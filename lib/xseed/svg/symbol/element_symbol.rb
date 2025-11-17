# frozen_string_literal: true

require_relative "base"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema element declaration
      # Handles occurrence constraints, type references, and element properties
      class ElementSymbol < Base
        attr_accessor :type_ref, :substitution_group, :target_namespace

        def initialize(name:, type:, xsd_node:, target_namespace: nil)
          @target_namespace = target_namespace
          super(name: name, type: type, xsd_node: xsd_node)
          extract_element_attributes
        end

        # Returns minimum occurrences (0 = optional)
        def min_occurs
          @min_occurs ||= extract_occurs("minOccurs", 1)
        end

        # Returns maximum occurrences (Float::INFINITY = unbounded)
        def max_occurs
          @max_occurs ||= extract_occurs("maxOccurs", 1)
        end

        # Returns true if element can be nil
        def nillable?
          @nillable ||= extract_boolean("nillable", false)
        end

        # Returns true if element is optional (minOccurs = 0)
        def optional?
          min_occurs.zero?
        end

        # Returns true if element is required (minOccurs > 0)
        def required?
          !optional?
        end

        # Returns true if element can appear multiple times
        def repeatable?
          max_occurs > 1
        end

        # Returns true if element is abstract
        def abstract?
          @abstract ||= extract_boolean("abstract", false)
        end

        # Returns default value if specified
        def default_value
          @default_value ||= extract_attribute("default")
        end

        # Returns fixed value if specified
        def fixed_value
          @fixed_value ||= extract_attribute("fixed")
        end

        # Returns form (qualified/unqualified)
        def form
          @form ||= extract_attribute("form")
        end

        # Resolves type reference using type registry
        def resolve_type_reference(type_registry)
          return nil unless @type_ref

          type_registry[@type_ref]
        end

        # Returns type information for display (alias for type_ref)
        def type_info
          @type_ref
        end

        # Returns display label for SVG rendering
        def display_label
          label = @name.to_s
          label = "#{label} [#{occurrence_display}]" if occurrence_display
          label
        end

        private

        # Extracts element-specific attributes from XSD node
        def extract_element_attributes
          @type_ref = extract_attribute("type")
          @substitution_group = extract_attribute("substitutionGroup")
        end

        # Extracts occurrence attribute and handles "unbounded"
        def extract_occurs(attr_name, default)
          value = extract_attribute(attr_name)
          return default if value.nil?
          return Float::INFINITY if value == "unbounded"

          value.to_i
        end

        # Extracts boolean attribute
        def extract_boolean(attr_name, default)
          value = extract_attribute(attr_name)
          return default if value.nil?

          value.to_s.downcase == "true"
        end

        # Extracts attribute from XSD node
        def extract_attribute(attr_name)
          return nil unless @xsd_node.respond_to?(:attributes)

          attributes = @xsd_node.attributes
          return nil unless attributes.is_a?(Hash)

          attr = attributes[attr_name]
          # Nokogiri returns Attr objects, extract the value
          attr.respond_to?(:value) ? attr.value : attr
        end

        # Returns occurrence display string
        def occurrence_display
          return nil if min_occurs == 1 && max_occurs == 1

          max_str = max_occurs == Float::INFINITY ? "*" : max_occurs.to_s
          "#{min_occurs}..#{max_str}"
        end
      end
    end
  end
end
