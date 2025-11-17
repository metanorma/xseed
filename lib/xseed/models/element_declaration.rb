# frozen_string_literal: true

require "lutaml/model"

module Xseed
  module Models
    # Represents an XSD element declaration
    #
    # This model captures all properties of an xs:element declaration including
    # name, type, occurrence constraints, and documentation.
    #
    # @example Creating an element
    #   element = ElementDeclaration.new(
    #     name: "Person",
    #     type: "PersonType",
    #     min_occurs: 0,
    #     max_occurs: "unbounded"
    #   )
    #
    class ElementDeclaration < Lutaml::Model::Serializable
      attribute :name, :string
      attribute :type, :string
      attribute :min_occurs, :integer, default: -> { 1 }
      attribute :max_occurs, :string, default: -> { "1" }
      attribute :nillable, Lutaml::Model::Type::Boolean, default: -> { false }
      attribute :abstract, Lutaml::Model::Type::Boolean, default: -> { false }
      attribute :substitution_group, :string
      attribute :documentation, :string
      attribute :default_value, :string
      attribute :fixed_value, :string

      xml do
        root "element"
        namespace "http://www.w3.org/2001/XMLSchema", "xs"

        map_attribute "name", to: :name
        map_attribute "type", to: :type
        map_attribute "minOccurs", to: :min_occurs
        map_attribute "maxOccurs", to: :max_occurs
        map_attribute "nillable", to: :nillable
        map_attribute "abstract", to: :abstract
        map_attribute "substitutionGroup", to: :substitution_group
        map_attribute "default", to: :default_value
        map_attribute "fixed", to: :fixed_value
      end

      yaml do
        map "name", to: :name
        map "type", to: :type
        map "min_occurs", to: :min_occurs
        map "max_occurs", to: :max_occurs
        map "nillable", to: :nillable
        map "abstract", to: :abstract
        map "substitution_group", to: :substitution_group
        map "documentation", to: :documentation
        map "default_value", to: :default_value
        map "fixed_value", to: :fixed_value
      end

      json do
        map "name", to: :name
        map "type", to: :type
        map "minOccurs", to: :min_occurs
        map "maxOccurs", to: :max_occurs
        map "nillable", to: :nillable
        map "abstract", to: :abstract
        map "substitutionGroup", to: :substitution_group
        map "documentation", to: :documentation
        map "defaultValue", to: :default_value
        map "fixedValue", to: :fixed_value
      end

      # Parse an element declaration from an XSD Nokogiri node
      #
      # @param node [Nokogiri::XML::Element] The xs:element node
      # @return [ElementDeclaration] The parsed element declaration
      def self.from_xsd_node(node)
        new(
          name: node["name"],
          type: node["type"],
          min_occurs: parse_occurs(node["minOccurs"], 1),
          max_occurs: node["maxOccurs"] || "1",
          nillable: parse_boolean(node["nillable"]),
          abstract: parse_boolean(node["abstract"]),
          substitution_group: node["substitutionGroup"],
          default_value: node["default"],
          fixed_value: node["fixed"],
          documentation: extract_documentation(node)
        )
      end

      # Check if the element is optional (minOccurs = 0)
      #
      # @return [Boolean] true if the element is optional
      def optional?
        min_occurs.zero?
      end

      # Check if the element is unbounded (maxOccurs = "unbounded")
      #
      # @return [Boolean] true if the element is unbounded
      def unbounded?
        max_occurs == "unbounded"
      end

      # Check if the element has documentation
      #
      # @return [Boolean] true if documentation is present
      def documented?
        !documentation.nil? && !documentation.empty?
      end

      # Get occurrence string representation
      #
      # @return [String] Occurrence representation like "[0..1]" or "[1..∞]"
      def occurrence_string
        return "" if min_occurs == 1 && max_occurs == "1"

        max_display = max_occurs == "unbounded" ? "∞" : max_occurs
        "[#{min_occurs}..#{max_display}]"
      end

      private_class_method def self.parse_occurs(value, default)
        return default if value.nil? || value.empty?

        value.to_i
      end

      private_class_method def self.parse_boolean(value)
        value == "true"
      end

      private_class_method def self.extract_documentation(node)
        doc_node = node.at_xpath(
          "xs:annotation/xs:documentation",
          "xs" => "http://www.w3.org/2001/XMLSchema"
        )
        return nil unless doc_node

        doc_node.text.strip
      end
    end
  end
end
