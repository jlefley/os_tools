require 'spec_helper'

describe OSTools do

  describe 'when configuring' do
   
    it 'should yield OSTools' do
      OSTools.configure do |config|
        config.should == OSTools
      end
    end

    it 'should allow configuration of default schema' do
      OSTools.configure do |config|
        config.default_schema = 'some_schema'
      end
      OSTools.default_schema.should == 'some_schema'
    end

    it 'should have public as default schema if not configured' do
      OSTools.default_schema = nil
      OSTools.default_schema.should == 'public'
    end

    describe 'when setting schema names' do
      describe 'with array' do
        it 'should set schema names accordingly' do
          OSTools.configure do |config|
            config.schema_names = ['users']
          end
          OSTools.schema_names.should == ['users']
        end
      end
      describe 'with lambda' do
        it 'should set schema names accordingly' do
          OSTools.configure do |config|
            config.schema_names = lambda{ ['users'] }
          end
          OSTools.schema_names.should == ['users']
        end
      end
    end
  end

end
