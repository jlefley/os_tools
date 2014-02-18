module OSTools
  module Schema

    extend self

    def search_path
      Sequel::Model.db.fetch('SHOW search_path').first[:search_path]
    end

    def switch schema, include_public = true
      path = [schema.to_s, ('public' if include_public)].compact.join(',')
      Sequel::Model.db.run("SET search_path TO #{path}")
    end

    def reset
      switch '"$user"'
    end

    def all
      sql = "SELECT nspname FROM pg_namespace WHERE nspname !~ '^pg_.*' AND nspname != 'information_schema'"
      Sequel::Model.db.fetch(sql).map(:nspname)
    end

    def create name
      Sequel::Model.db.run(%{CREATE SCHEMA "#{name}"})
    rescue
      raise SchemaExists
    end

    def drop name
      Sequel::Model.db.run(%{DROP SCHEMA "#{name}" CASCADE})
    rescue
      raise SchemaNotFound
    end

  end
end
