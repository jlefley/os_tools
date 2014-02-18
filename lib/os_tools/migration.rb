module OSTools
  module Migration
    extend self
    
    def copy destination, sources, options = {}
      copied = []

      FileUtils.mkdir_p(destination) unless File.exists?(destination)

      destination_migrations = migrations(destination)
      last = destination_migrations.last
      sources.each do |scope, path|
        source_migrations = migrations(path)

        source_migrations.each do |migration|
          source = File.binread(migration.filename)
          inserted_comment = "# This migration comes from #{scope} (originally #{migration.version})\n"
          if /\A#.*\b(?:en)?coding:\s*\S+/ =~ source
            # If we have a magic comment in the original migration,
            # insert our comment after the first newline(end of the magic comment line)
            # so the magic keep working.
            # Note that magic comments must be at the first line(except sh-bang).
            source[/\n/] = "\n#{inserted_comment}"
          else
            source = "#{inserted_comment}#{source}"
          end

          if duplicate = destination_migrations.detect { |m| m.name == migration.name }
            if options[:on_skip] && duplicate.scope != scope.to_s
              options[:on_skip].call(scope, migration)
            end
            next
          end

          migration.version = next_migration_number(last ? last.version + 1 : 1).to_i
          new_path = File.join(destination, "#{migration.version}_#{migration.name.underscore}.#{scope}.rb")
          old_path, migration.filename = migration.filename, new_path
          last = migration

          File.binwrite(migration.filename, source)
          copied << migration
          options[:on_copy].call(scope, migration, old_path) if options[:on_copy]
          destination_migrations << migration
        end
      end

      copied
    end

    def next_migration_number number
      #if ActiveRecord::Base.timestamped_migrations
      #  [Time.now.utc.strftime("%Y%m%d%H%M%S"), "%.14d" % number].max
      #else
      #  "%.3d" % number
      #end 
      "%.3d" % number
    end

    def migrations paths
      paths = [paths]

      files = Dir[*paths.map { |p| "#{p}/**/[0-9]*_*.rb" }]

      migrations = files.map do |file|
        version, name, scope = file.scan(/([0-9]+)_([_a-z0-9]*)\.?([_a-z0-9]*)?\.rb\z/).first

        raise IllegalMigrationNameError.new(file) unless version
        version = version.to_i
        name = name.camelize

        MigrationProxy.new(name, version, file, scope)
      end

      migrations.sort_by(&:version)
    end
  
  end

  # MigrationProxy is used to defer loading of the actual migration classes
  # until they are needed
  class MigrationProxy < Struct.new(:name, :version, :filename, :scope)

    def initialize(name, version, filename, scope)
      super
      @migration = nil
    end

    def basename
      File.basename(filename)
    end

  end
end
