# frozen_string_literal: true

require_relative "base"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema attribute declaration
      # Handles use constraints, type references, and attribute properties
      class AttributeSymbol < Base
        attr_accessor :type_ref

        def initialize(name:, type:, xsd_node:)
          super
          extract_attribute_properties
        end

        # Returns use constraint (required/optional/prohibited)
        def use
          @use ||= extract_attribute_value("use") || "optional"
        end

        # Returns true if attribute is required
        def required?
          use == "required"
        end

        # Returns true if attribute is optional
        def optional?
          use == "optional"
        end

        # Returns true if attribute is prohibited
        def prohibited?
          use == "prohibited"
        end

        # Returns default value if specified
        def default_value
          @default_value ||= extract_attribute_value("default")
        end

        # Returns fixed value if specified
        def fixed_value
          @fixed_value ||= extract_attribute_value("fixed")
        end

        # Returns form (qualified/unqualified)
        def form
          @form ||= extract_attribute_value("form")
        end

        # Returns ref attribute for attribute references
        def ref
          @ref ||= extract_attribute_value("ref")
        end

        # Returns true if this is an attribute reference
        def is_reference?
          !ref.nil?
        end

        # Resolves type reference using type registry
        def resolve_type_reference(type_registry)
          return nil unless @type_ref

          type_registry[@type_ref]
        end

        # Returns display label for SVG rendering
        def display_label
          label = "@#{@name}"

          # Add use indicator
          if required?
            label += " !"
          elsif prohibited?
            label += " (prohibited)"
          end

          # Add type information
          if @type_ref
            type_name = @type_ref.split(":").last
            label += " : #{type_name}"
          end

          # Add default value indicator
          label += " = ..." if default_value

          label
        end

        private

        # Extracts attribute-specific properties
        def extract_attribute_properties
          @type_ref = extract_attribute_value("type")
        end

        # Extracts attribute value from XSD node
        def extract_attribute_value(attr_name)
          return nil unless @xsd_node.respond_to?(:attributes)

          attributes = @xsd_node.attributes
          return nil unless attributes.is_a?(Hash)

          attributes[attr_name]
        end

        # Override calculate_bounds for smaller attribute symbols
        def calculate_bounds
          super

          # Attributes are typically smaller than elements
          @height = (DEFAULT_HEIGHT * 0.75).to_i

          # Add width for @ prefix and type
          @width += 30 if @type_ref
        end
      end
    end
  end
end
