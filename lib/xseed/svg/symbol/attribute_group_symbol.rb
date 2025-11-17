# frozen_string_literal: true

require_relative "base"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema attribute group definition or reference
      # Groups common attributes for reuse across types
      class AttributeGroupSymbol < Base
        attr_reader :attributes

        def initialize(name:, type:, xsd_node:)
          @attributes = []
          super
        end

        # Adds attribute to group
        def add_attribute(attribute_symbol)
          @attributes << attribute_symbol
          attribute_symbol
        end

        # Returns true if group has attributes
        def has_attributes?
          !@attributes.empty?
        end

        # Returns ref attribute for group references
        def ref
          @ref ||= extract_attribute("ref")
        end

        # Returns true if this is an attribute group reference
        def is_reference?
          !ref.nil?
        end

        # Returns display label for SVG rendering
        def display_label
          if is_reference?
            "attributeGroup → #{ref}"
          else
            "attributeGroup: #{@name}"
          end
        end

        private

        # Extracts attribute from XSD node
        def extract_attribute(attr_name)
          return nil unless @xsd_node.respond_to?(:attributes)

          attrs = @xsd_node.attributes
          return nil unless attrs.is_a?(Hash)

          attrs[attr_name]
        end

        # Override calculate_bounds for attribute groups
        def calculate_bounds
          super

          # Adjust height based on number of attributes
          return unless @attributes.size.positive?

          @height = DEFAULT_HEIGHT + (@attributes.size * 20)
        end
      end
    end
  end
end
