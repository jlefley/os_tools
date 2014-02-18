require 'spec_helper'

describe OSTools do

  describe 'when creating a new schema with structure' do
  
    before do
      OSTools.configure do |config|
        config.default_schema = 'public'
        config.seed << { table: :test_table, columns: [:title] }
      end
      Sequel::Model.db.create_table(:public__schema_info) { Integer :version }
      Sequel::Model.db[:public__schema_info].insert(version: 4)
    end

    after do
      Sequel::Model.db.drop_table(:public__schema_info)
    end

    describe 'when creation is successful' do

      before do
        Sequel::Model.db.create_table(:public__test_table) { primary_key :id; String :title }
        OSTools::Database.dump_structure File.join(Rails.root, 'db', 'schema_structure.sql')
        OSTools.create_schema 'new'
      end

      after do
        OSTools::Schema.drop 'new'
        File.delete(File.join(Rails.root, 'db', 'schema_structure.sql'))
        Sequel::Model.db.drop_table(:public__test_table)
      end

      it 'should create a new schema populated with the structure from the structure file' do
        Sequel::Model.db[:new__test_table].all.should == []
      end
      it 'should reset the search path' do
        OSTools::Schema.search_path.gsub(/\s+/, '').should == '"$user",public'
      end

      describe 'when loading seed data after dumping seed data' do
        before do
          DB[:public__test_table] << { title: 'item title' }
          OSTools.dump_seed
        end

        after do
          File.delete(File.join(Rails.root, 'db/seed', 'test_table.csv'))
        end

        it 'should load CSV into configured tables within specified schema' do
          OSTools.load_seed 'new'
          DB[:new__test_table].first[:title].should == 'item title'
        end
      end
    end

    describe 'when creation is not successful' do
      it 'should raise SchemaCreationFailed' do
        expect { OSTools.create_schema 'new' }.to raise_error(OSTools::SchemaCreationFailure)
      end
      it 'should reset the search path' do
        expect { OSTools.create_schema 'new' }.to raise_error
        OSTools::Schema.search_path.gsub(/\s+/, '').should == '"$user",public'
      end
    end
  
  end

end
