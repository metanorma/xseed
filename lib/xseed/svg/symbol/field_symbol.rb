# frozen_string_literal: true

require_relative "base"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema xs:field element within identity constraints
      # Field specifies the XPath expression for field selection
      class FieldSymbol < Base
        attr_reader :xpath

        def initialize(xsd_node:)
          @xpath = extract_xpath(xsd_node)
          super(name: "field: #{@xpath}", type: "field", xsd_node: xsd_node)
        end

        private

        # Extracts XPath from field node
        def extract_xpath(xsd_node)
          if xsd_node.respond_to?(:[])
            xsd_node["xpath"] || xsd_node[:xpath] || "."
          elsif xsd_node.respond_to?(:xpath)
            xsd_node.xpath || "."
          elsif xsd_node.respond_to?(:attributes)
            attributes = xsd_node.attributes
            attributes.is_a?(Hash) ? (attributes["xpath"] || ".") : "."
          else
            "."
          end
        end

        # Override calculate_bounds for compact field height
        def calculate_bounds
          @width = [MIN_WIDTH, (@name.length * CHAR_WIDTH) + NAME_PADDING].max
          @height = MID_HEIGHT
        end
      end
    end
  end
end