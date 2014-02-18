namespace :schemas do
  namespace :migrate do
    task load: :environment do
      require 'sequel_rails/migrations'
    end
 
    desc 'Runs the up migration for a given migration VERSION over all configured schemas'
    task up: :load do
      version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
      raise 'VERSION is required' unless version

      puts "Migrating schema #{OSTools.default_schema} up"
      OSTools::Schema.switch OSTools.default_schema, false
      SequelRails::Migrations.migrate version
      OSTools::Database.dump_structure File.join(Rails.root, 'db', 'schema_structure.sql')
      
      OSTools.schema_names.each do |schema|
        puts "Migrating schema #{schema} up" 
        OSTools::Schema.switch schema, false
        SequelRails::Migrations.migrate version
      end
      OSTools::Schema.reset
    end

    desc 'Runs the down migration for a given migration VERSION over all configured schema names'
    task down: :load do
      version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
      raise 'VERSION is required' unless version
   
      puts "Migrating schema #{OSTools.default_schema} down"
      OSTools::Schema.switch OSTools.default_schema, false
      SequelRails::Migrations.migrate version
      OSTools::Database.dump_structure File.join(Rails.root, 'db', 'schema_structure.sql')

      OSTools.schema_names.each do |schema|
        puts "Migrating schema #{schema} down" 
        OSTools::Schema.switch schema, false
        SequelRails::Migrations.migrate version
      end
      OSTools::Schema.reset
    end

  end

  desc 'Runs pending migrations over all configured schema names'
  task migrate: 'migrate:load' do
    puts "Migrating schema #{OSTools.default_schema}"
    OSTools::Schema.switch OSTools.default_schema, false
    SequelRails::Migrations.migrate
    OSTools::Database.dump_structure File.join(Rails.root, 'db', 'schema_structure.sql')

    OSTools.schema_names.each do |schema|
      puts "Migrating schema #{schema}" 
      OSTools::Schema.switch schema, false
      SequelRails::Migrations.migrate
    end
    OSTools::Schema.reset
  end

  namespace :structure do
    desc 'Dump database schema structure to db/schema_structure.sql'
    task dump: :environment do
      OSTools::Schema.switch OSTools.default_schema, false
      OSTools::Database.dump_structure File.join(Rails.root, 'db', 'schema_structure.sql')
      OSTools::Schema.reset
    end

    desc 'Load database schema structure from db/schema_structure.rb into default schema'
    task load: :environment do
      OSTools::Schema.switch OSTools.default_schema, false
      OSTools::Database.load_structure File.join(Rails.root, 'db', 'schema_structure.sql'), false
      OSTools::Schema.reset
    end
  end

end
