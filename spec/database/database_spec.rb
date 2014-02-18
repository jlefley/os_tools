require 'spec_helper'

describe OSTools::Database do

  after do
    OSTools::Schema.drop 'tenant'
    File.delete 'structure.sql'
    Sequel::Model.db.drop_table(:public__schema_info)
    Sequel::Model.db.drop_table(:public__items)
    Sequel::Model.db.drop_table(:public__users)
    OSTools::Schema.reset
  end

  before do
    OSTools.configure do |config|
      config.default_schema = 'public'
    end
    OSTools::Schema.create 'tenant'
    Sequel::Model.db.create_table(:public__schema_info) { Integer :version }
    Sequel::Model.db[:public__schema_info].insert(version: 4)
    Sequel::Model.db.create_table(:public__users) { primary_key :id; String :name }
    Sequel::Model.db.create_table(:public__items) { String :title; primary_key :id; foreign_key :user_id, :users }
    Sequel::Model.db.create_table(:tenant__tenant_table) { primary_key :id }
    OSTools::Database.dump_structure 'structure.sql'
  end

  describe 'when dumping structure' do
 
    before do
      @structure = open('structure.sql', 'r').read
    end

    it 'should dump structure of default schema' do
      @structure.should include 'items'
      @structure.should_not include 'tenant_table'
    end

    it 'should add an insert statement to the structure file with the current schema migration version' do
      @structure.should include 'INSERT INTO schema_info VALUES (4)'
    end

  end

  describe 'when loading structure' do
 
    before do
      OSTools::Schema.switch 'tenant', false
    end

    describe 'when set to update user table references' do
      before { OSTools::Database.load_structure 'structure.sql' }
      
      it 'should load structure from file into schema specified by search path' do
        Sequel::Model.db[:tenant__schema_info].first[:version].should == 4
      end

      it 'should update references to users table to <default_schema>.users' do
        user_id = Sequel::Model.db[:public__users].insert(name: 'abc')
        Sequel::Model.db[:tenant__items].insert(user_id: user_id)
      end
    end
    
    describe 'when set to not update user table references' do
      before { OSTools::Database.load_structure 'structure.sql', false }
      
      it 'should load structure from file into schema specified by search path' do
        Sequel::Model.db[:tenant__schema_info].first[:version].should == 4
      end

      it 'should not update references to users table to <default_schema>.users' do
        user_id = Sequel::Model.db[:public__users].insert(name: 'abc')
        expect { Sequel::Model.db[:tenant__items].insert(user_id: user_id) }.to raise_error
      end
    end

  end

end
