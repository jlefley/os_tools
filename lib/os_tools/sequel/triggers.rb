require 'sequel_postgresql_triggers'

module Sequel
  module Postgres
    module DatabaseMethods
      def created_at_trigger table_name
        pgt_created_at table_name, :created_at, trigger_name: :created_at, function_name: "#{table_name.to_s}_created_at".to_sym
      end 
      
      def updated_at_trigger table_name
        pgt_updated_at table_name, :updated_at, trigger_name: :updated_at, function_name: "#{table_name.to_s}_updated_at".to_sym
      end 
      
      def drop_created_at_trigger table_name
        drop_function "#{table_name.to_s}_created_at".to_sym
      end 
      
      def drop_updated_at_trigger table_name
        drop_function "#{table_name.to_s}_updated_at".to_sym
      end   
    
      def archive_deleted table_name
        run %(CREATE TABLE deleted_#{table_name} (LIKE #{table_name} INCLUDING INDEXES);)
        run %(ALTER TABLE deleted_#{table_name} ADD COLUMN deleted_at timestamp with time zone NOT NULL DEFAULT now();)
        update_move_deleted_function table_name
        run <<-SQL
          CREATE TRIGGER move_deleted_#{table_name}
          BEFORE DELETE ON #{table_name}
          FOR EACH ROW
          EXECUTE PROCEDURE move_deleted_#{table_name}();
        SQL
      end

      def update_move_deleted_function table_name
        cols = self[:information_schema__columns].
          where(table_name: table_name.to_s, table_schema: OSTools::Schema.search_path).select(:column_name).map(:column_name)
        new_cols = cols.join(',')
        old_cols = cols.each { |c| c.insert(0, 'OLD.') }.join(',')
        run <<-SQL
          CREATE OR REPLACE FUNCTION move_deleted_#{table_name}() RETURNS trigger AS $$
          BEGIN
            INSERT INTO deleted_#{table_name} (#{new_cols}) VALUES (#{old_cols});
            RETURN OLD;
          END;
          $$ LANGUAGE plpgsql;
        SQL
      end

      def drop_deleted_archive table_name
        drop_table "deleted_#{table_name}"
        drop_function "move_deleted_#{table_name}", cascade: true
      end
    end
  end
end
