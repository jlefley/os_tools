module OSTools

  extend self

  def create_schema name, users_references_public_schema=true
    Sequel::Model.db.transaction do
      OSTools::Schema.create name
      OSTools::Schema.switch name, false
      OSTools::Database.load_structure File.join(Rails.root, 'db', 'schema_structure.sql'), users_references_public_schema
    end
  rescue
    raise SchemaCreationFailure
  ensure
    OSTools::Schema.reset
  end

  def load_seed schema_name
    OSTools.seed.each do |e|
      if Pathname.new(file = File.join(Rails.root, 'db/seed', "#{e[:table]}.csv")).exist?
        OSTools::Database.load_table file, schema_name, e
      else
        raise "seed file #{file} not found"
      end
    end
  end

  def dump_seed *args
    schema_name = args[0] || OSTools.default_schema
    OSTools.seed.each do |e|
      OSTools::Database.dump_table File.join(Rails.root, 'db/seed', "#{e[:table]}.csv"), schema_name, e
    end
  end

end
