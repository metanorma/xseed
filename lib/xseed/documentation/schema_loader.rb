# frozen_string_literal: true

require "lutaml/xsd"

module Xseed
  module Documentation
    # Wrapper around Lutaml::Xsd for loading and parsing XSD schemas
    #
    # This class provides a simple interface to lutaml-xsd's schema parsing
    # capabilities, with Xseed-specific error handling and configuration.
    #
    # @example Load a schema from file
    #   schema = SchemaLoader.load("path/to/schema.xsd")
    #   puts schema.target_namespace
    #
    # @example Parse schema content with mappings
    #   schema = SchemaLoader.parse(
    #     xsd_content,
    #     location: "/path/to/schemas",
    #     schema_mappings: [
    #       { from: "common.xsd", to: "/local/common.xsd" }
    #     ]
    #   )
    #
    class SchemaLoader
      # Error raised when schema file cannot be loaded
      class LoadError < StandardError; end

      # Error raised when schema content cannot be parsed
      class ParseError < StandardError; end

      # Load an XSD schema from a file
      #
      # @param file_path [String] Path to the XSD file
      # @param config [Config] Optional configuration for schema mappings
      # @return [Lutaml::Xsd::Schema] Parsed schema object
      # @raise [LoadError] if file cannot be read
      # @raise [ParseError] if schema cannot be parsed
      def self.load(file_path, config: nil)
        content = File.read(file_path)
        location = File.dirname(File.expand_path(file_path))

        parse(content, location: location, config: config)
      rescue Errno::ENOENT
        raise LoadError, "Schema file not found: #{file_path}"
      rescue ParseError => e
        raise e
      rescue StandardError => e
        raise ParseError, "Failed to load schema: #{e.message}"
      end

      # Parse XSD schema content
      #
      # @param content [String] XSD schema content
      # @param location [String] Base directory or URL for resolving imports
      # @param schema_mappings [Array<Hash>] Schema location mappings
      # @param config [Config] Optional configuration for additional mappings
      # @return [Lutaml::Xsd::Schema] Parsed schema object
      # @raise [ParseError] if schema cannot be parsed
      def self.parse(content, location: nil, schema_mappings: nil, config: nil)
        # Note: schema_mappings and config parameters are accepted for future
        # compatibility but not yet used as lutaml-xsd doesn't support them yet

        # Use lutaml-xsd's parse method which handles all validation
        Lutaml::Xsd.parse(
          content,
          location: location,
        )
      rescue StandardError => e
        raise ParseError, "Failed to parse schema: #{e.message}"
      end

      # Build schema location mappings from various sources
      #
      # @param explicit_mappings [Array<Hash>] Explicitly provided mappings
      # @param config [Config] Configuration object with potential mappings
      # @return [Array<Hash>] Combined schema location mappings
      def self.build_mappings(explicit_mappings, config)
        mappings = []

        # Add explicit mappings if provided
        mappings.concat(explicit_mappings) if explicit_mappings

        # Add config-based mappings if available
        if config.respond_to?(:schema_mappings)
          mappings.concat(config.schema_mappings)
        end

        mappings.empty? ? nil : mappings
      end

      private_class_method :build_mappings
    end
  end
end
