require 'spec_helper'

describe OSTools::Schema do

  before do
    OSTools::Schema.reset
  end

  describe 'when getting search path' do
    it 'should return the current search path' do
      OSTools::Schema.search_path.should == %{"$user", public}
    end
  end

  describe 'when setting search path' do
    it 'should add the specified schema name to the begining of the search path' do
      OSTools::Schema.switch 'some_schema'
      OSTools::Schema.search_path.should == %{some_schema, public}
    end
    describe 'when excluding public' do
      it 'should set the search path to include only the specified schema name' do
        OSTools::Schema.switch 'some_schema', false
        OSTools::Schema.search_path.should == %{some_schema}
      end
    end
  end

  describe 'when search path is reset' do
    it 'should restore the search path to the default' do
      OSTools::Schema.switch 'some_schema'
      OSTools::Schema.reset
      OSTools::Schema.search_path.should == %{"$user", public}
    end
  end

  describe 'when schema is created' do
    it 'should should create a new schema with the specified name' do
      Sequel::Model.db.transaction(rollback: :always) do
        OSTools::Schema.create 'new_schema'
        OSTools::Schema.all.should include 'new_schema'
      end
    end
    describe 'when schema with specified name exists' do
      it 'should raise SchemaExists error' do
        Sequel::Model.db.transaction(rollback: :always) do
          OSTools::Schema.create 'new_schema'
          expect { OSTools::Schema.create 'new_schema' }.to raise_error(OSTools::SchemaExists) 
        end
      end
    end
  end

  describe 'when getting schemas list' do
    it 'should return an array of the existing schemas' do
      OSTools::Schema.all.should include 'public'
    end
  end

  describe 'when dropping schema' do
    it 'should drop the schema and contained tables from the database' do
      Sequel::Model.db.transaction(rollback: :always) do
        OSTools::Schema.create 'new_schema'
        Sequel::Model.db.create_table(:new_schema__test_table) { primary_key :id }
        OSTools::Schema.drop 'new_schema'
        OSTools::Schema.all.should_not include 'new_schema'
      end
    end
    describe 'when schema with specified name does not exist' do
      it 'should raise SchemaNotFound error' do
        expect { OSTools::Schema.drop 'non_existing' }.to raise_error(OSTools::SchemaNotFound) 
      end
    end
  end

end

