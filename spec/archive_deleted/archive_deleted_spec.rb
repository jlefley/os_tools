require 'spec_helper'
require 'os_tools/sequel/triggers'

describe 'Archive deleted records', txn: true do

  describe 'when archive table is set up for existing table' do
    before do
      OSTools::Schema.switch OSTools.default_schema, false
      DB.create_table(:items) { Integer :id }
      DB.archive_deleted :items
    end
    
    describe 'when record is deleted from table with archive' do
      it 'should copy the deleted record into the archive table and set the deleted_at timestamp with the deletion time' do
        DB[:items] << { id: 1 }
        DB[:items].where(id: 1).delete
        DB[:deleted_items].filter(id: 1).get(:deleted_at).should_not be_nil
      end
    end

    describe 'when archive table is deleted' do
      before do
        DB.drop_deleted_archive :items
      end

      it 'should drop the archive table' do
        expect { DB[:deleted_items].all }.to raise_error
      end
      
      it 'should drop the move_deleted function' do
        expect { DB.drop_function(:move_deleted_items) }.to raise_error
      end
    end


    describe 'when function is updated to reflect schema changes' do
      before do
        DB.add_column :items, :name, String
        DB.add_column :deleted_items, :name, String
        DB.update_move_deleted_function :items
      end
    
      it 'should replace function with necessary changes to reflect new schema' do
        DB[:items] << { id: 1, name: 'name' }
        DB[:items].where(id: 1).delete
        DB[:deleted_items].filter(id: 1).get(:name).should_not be_nil
      end

      describe 'when added columns have been deleted' do
        before do
          DB.drop_column :items, :name
          DB.drop_column :deleted_items, :name
          DB.update_move_deleted_function :items
        end
        it 'should replace function with necessary changes to reflect new schema' do
          DB[:items] << { id: 1 }
          DB[:items].where(id: 1).delete
          DB[:deleted_items].filter(id: 1).get(:deleted_at).should_not be_nil
        end
      end
    end

  end
end
