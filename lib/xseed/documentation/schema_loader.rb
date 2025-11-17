# frozen_string_literal: true

require "lutaml/xsd"
require "nokogiri"

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
        # Validate that it's actually an XSD schema
        validate_schema_content(content)

        mappings = build_mappings(schema_mappings, config)

        # Use lutaml-xsd's parse method
        Lutaml::Xsd.parse(
          content,
          location: location,
          schema_mappings: mappings
        )
      rescue Nokogiri::XML::SyntaxError => e
        raise ParseError, "Invalid XML syntax: #{e.message}"
      rescue StandardError => e
        raise ParseError, "Failed to parse schema: #{e.message}"
      end

      # Validate that content is an XSD schema document
      #
      # @param content [String] XML content to validate
      # @raise [ParseError] if not a valid schema
      def self.validate_schema_content(content)
        doc = Nokogiri::XML(content)
        root = doc.root

        raise ParseError, "Empty or invalid XML document" unless root

        # Check if root element is xs:schema or xsd:schema
        unless root.name == "schema" &&
               root.namespace&.href&.include?("XMLSchema")
          raise ParseError,
                "Not a valid XSD schema: root element must be xs:schema"
        end
      rescue Nokogiri::XML::SyntaxError => e
        raise ParseError, "Invalid XML syntax: #{e.message}"
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

      private_class_method :build_mappings, :validate_schema_content
    end
  end
end
