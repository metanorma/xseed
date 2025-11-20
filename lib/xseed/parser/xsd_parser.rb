# frozen_string_literal: true

require "nokogiri"

module Xseed
  module Parser
    # XSD Parser for extracting schema components and metadata
    #
    # This class parses XML Schema Definition (XSD) files using Nokogiri
    # and provides methods to access schema components such as elements,
    # types, groups, and documentation.
    #
    # @example Parse an XSD file
    #   parser = Xseed::Parser::XsdParser.new("schema.xsd")
    #   elements = parser.elements
    #   types = parser.types
    #
    class XsdParser
      attr_reader :document, :schema, :target_namespace

      XSD_NS = "http://www.w3.org/2001/XMLSchema"

      # Initialize the parser with an XSD file path
      #
      # @param xsd_file_path [String] Path to the XSD file
      # @raise [Errno::ENOENT] if file does not exist
      def initialize(xsd_file_path)
        content = File.read(xsd_file_path)
        @document = Nokogiri::XML(content, &:strict)
        @schema = @document.root

        raise ParserError, "Invalid XSD: No root element found" unless @schema

        parse_schema
      rescue Nokogiri::XML::SyntaxError => e
        raise ParserError, "Invalid XML syntax: #{e.message}"
      end

      # Get the elementFormDefault attribute value
      #
      # @return [String, nil] The elementFormDefault value
      def element_form_default
        schema["elementFormDefault"]
      end

      # Get the schema version attribute
      #
      # @return [String, nil] The schema version if present
      def schema_version
        schema["version"]
      end

      # Get all global element definitions
      #
      # @return [Array<Nokogiri::XML::Element>] Array of element nodes
      def elements
        xpath("//xs:schema/xs:element")
      end

      # Get all complex type definitions
      #
      # @return [Array<Nokogiri::XML::Element>] Array of complexType nodes
      def complex_types
        xpath("//xs:schema/xs:complexType")
      end

      # Get all simple type definitions
      #
      # @return [Array<Nokogiri::XML::Element>] Array of simpleType nodes
      def simple_types
        xpath("//xs:schema/xs:simpleType")
      end

      # Get all type definitions (both complex and simple)
      #
      # @return [Array<Nokogiri::XML::Element>] Array of type nodes
      def types
        complex_types + simple_types
      end

      # Get all group definitions
      #
      # @return [Array<Nokogiri::XML::Element>] Array of group nodes
      def groups
        xpath("//xs:schema/xs:group")
      end

      # Get all attribute group definitions
      #
      # @return [Array<Nokogiri::XML::Element>] Array of attributeGroup nodes
      def attribute_groups
        xpath("//xs:schema/xs:attributeGroup")
      end

      # Get namespace mappings from the schema
      #
      # @return [Hash<String, String>] Hash mapping prefixes to namespace URIs
      def namespaces
        schema.namespaces.transform_keys do |key|
          key.sub(/^xmlns:/, "")
        end
      end

      # Get schema-level documentation
      #
      # @return [String, nil] The documentation text or nil
      def documentation
        doc_node = schema.at_xpath(
          "xs:annotation/xs:documentation",
          "xs" => XSD_NS,
        )
        return nil unless doc_node

        doc_node.text.strip
      end

      # Get documentation for a specific element by name
      #
      # @param element_name [String] The name of the element
      # @return [String, nil] The documentation text or nil
      def element_documentation(element_name)
        element = schema.at_xpath(
          "xs:element[@name='#{element_name}']",
          "xs" => XSD_NS,
        )
        return nil unless element

        extract_documentation(element)
      end

      # Get documentation for a specific type by name
      #
      # @param type_name [String] The name of the type
      # @return [String, nil] The documentation text or nil
      def type_documentation(type_name)
        type_node = schema.at_xpath(
          "xs:complexType[@name='#{type_name}'] | " \
          "xs:simpleType[@name='#{type_name}']",
          "xs" => XSD_NS,
        )
        return nil unless type_node

        extract_documentation(type_node)
      end

      # Get all import declarations
      #
      # @return [Array<Nokogiri::XML::Element>] Array of import nodes
      def imports
        xpath("//xs:schema/xs:import")
      end

      # Get all include declarations
      #
      # @return [Array<Nokogiri::XML::Element>] Array of include nodes
      def includes
        xpath("//xs:schema/xs:include")
      end

      private

      # Parse the schema and extract metadata
      def parse_schema
        return unless schema

        @target_namespace = schema["targetNamespace"]
      end

      # Execute XPath query with XSD namespace
      #
      # @param xpath_expr [String] XPath expression
      # @return [Array<Nokogiri::XML::Element>] Matching nodes
      def xpath(xpath_expr)
        document.xpath(xpath_expr, "xs" => XSD_NS)
      end

      # Extract documentation from an XML node
      #
      # @param node [Nokogiri::XML::Element] The node to extract from
      # @return [String, nil] The documentation text or nil
      def extract_documentation(node)
        doc_node = node.at_xpath(
          "xs:annotation/xs:documentation",
          "xs" => XSD_NS,
        )
        return nil unless doc_node

        doc_node.text.strip
      end
    end
  end
end
