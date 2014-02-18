require 'spec_helper'
require 'rake'

describe 'schemas rake task namespace' do

  let(:structure_path) { File.join(Rails.root, 'db', 'schema_structure.sql') }
  
  before :all do
    Rake.application.rake_require 'os_tools/railties/schema'
    Rake::Task.define_task :environment
  end

  before do
    $stdout.stub :puts
    OSTools::Schema.create 'test_schema'
    OSTools.configure do |config|
      config.schema_names = ['test_schema']
      config.default_schema = 'public'
    end
  end

  after do
    OSTools::Schema.drop 'test_schema'
    File.delete structure_path
  end

  def migrate
    Rake.application.invoke_task 'schemas:migrate'
    Rake::Task['schemas:migrate'].reenable
  end

  def migrate_down version
    ENV['VERSION'] = version
    Rake.application.invoke_task 'schemas:migrate:down'
    Rake::Task['schemas:migrate:down'].reenable
  end

  def migrate_up version
    ENV['VERSION'] = version
    Rake.application.invoke_task 'schemas:migrate:up'
    Rake::Task['schemas:migrate:up'].reenable
  end

  def assert_search_path_reset
    OSTools::Schema.search_path.gsub(/\s+/, '').should == '"$user",public'
  end

  def assert_migration_version_1
    Sequel::Model.db[:test_schema__things].all.should == []
    Sequel::Model.db[:public__things].all.should == []
    expect { Sequel::Model.db[:test_schema__items].all }.to raise_error
    expect { Sequel::Model.db[:public__items].all }.to raise_error
    assert_search_path_reset
    structure = File.open(structure_path, 'r').read
    structure.should include 'things'
    structure.should_not include 'items'
  end

  def assert_migration_version_2
    Sequel::Model.db[:test_schema__things].all.should == []
    Sequel::Model.db[:public__things].all.should == []
    Sequel::Model.db[:test_schema__items].all.should == []
    Sequel::Model.db[:public__items].all.should == []
    assert_search_path_reset
    structure = File.open(structure_path, 'r').read
    structure.should include 'things'
    structure.should include 'items'
  end

  describe 'migrate:up' do
    it 'should run the up migration for specified version over configured schema names and default schema, reset search path, and dump structure' do
      migrate_up '1'
      assert_migration_version_1
      Sequel::Model.db.drop_table(:public__schema_info)
      Sequel::Model.db.drop_table(:public__things)
    end
  end

  describe 'migrate:down' do
    it 'should run the down migration for specified version over configured schema names and default schema, reset search path, and dump structure' do
      migrate
      migrate_down '1'
      assert_migration_version_1
      Sequel::Model.db.drop_table(:public__schema_info)
      Sequel::Model.db.drop_table(:public__things)
    end
  end

  describe 'migrate' do
    it 'should run pending migrations over configured schema names and default schema, reset search path, and dump structure' do
      migrate
      assert_migration_version_2
      Sequel::Model.db.drop_table(:public__schema_info)
      Sequel::Model.db.drop_table(:public__things)
      Sequel::Model.db.drop_table(:public__items)
    end
  end

end
