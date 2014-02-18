require 'os_tools/version'
require 'sequel_rails'
require 'os_tools/migration'
require 'os_tools/database'
require 'os_tools/schema'
require 'os_tools/instance'
require 'os_tools/railtie' if defined? Rails

module OSTools
  class << self
    attr_accessor :schema_names, :default_schema, :seed

    def configure
      yield self if block_given?
    end

    def default_schema
      @default_schema || 'public'
    end

    def schema_names
      @schema_names.respond_to?(:call) ? @schema_names.call : @schema_names
    end
  end

  self.seed = []

  class SchemaExists < StandardError; end
  class SchemaNotFound < StandardError; end
  class SchemaCreationFailure < StandardError; end
end
