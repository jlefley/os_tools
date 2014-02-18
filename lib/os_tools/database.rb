module OSTools
  module Database

    extend self

    def dump_structure filename
      load_config
      ENV['PGPASSWORD'] = escape(password) unless password.blank?
      command = %w(pg_dump -s -x -O)
      command << '-f' << escape(filename)
      command << '-U' << escape(username) unless username.blank?
      command << '--port' << escape(port.to_s) unless port.blank?
      command << '--host' << escape(host) unless host.blank?
      command << '-n' << escape(OSTools.default_schema)
      command << escape(database)
      raise 'Error dumping database structure' unless Kernel.system(*command)
      write_version escape(filename)
      ENV['PGPASSWORD'] = nil unless password.blank?
    end

    def load_structure filename, reference_default_schema_users=true
      structure = File.open(filename, 'r').read
      structure.gsub! %{SET search_path = public, pg_catalog;}, ''
      structure.gsub! %{COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';}, ''
      structure.gsub! %{REFERENCES users}, %{REFERENCES #{OSTools.default_schema}.users} if reference_default_schema_users
      Sequel::Model.db.run structure
    end

    def dump_table filename, schema, config
      table, columns = config.values_at :table, :columns
      db = Sequel::Model.db
      File.open(filename, 'w') { |f| f.write db.copy_table(db["#{schema}__#{table}".to_sym].select(*columns), format: :csv) }
    end

    def load_table filename, schema, config
      table, columns = config.values_at :table, :columns
      Sequel::Model.db.copy_into "#{schema}__#{table}".to_sym, columns: columns, data: File.read(filename), format: :csv
    end

    private

    def load_config
      @config = SequelRails.configuration.environments[Rails.env.to_s]
    end

    def write_version filename
      version = Sequel::Model.db[Sequel.qualify(OSTools.default_schema.to_sym, :schema_info)].first[:version]
      File.open(filename, 'a') { |f| f << "INSERT INTO schema_info VALUES (#{version});" }
    end

    def password
      @config['password']
    end

    def username
      @config['username']
    end

    def port
      @config['port']
    end

    def host
      @config['host']
    end

    def database
      @config['database']
    end

    def escape string
      Shellwords.escape string
    end

  end
end
