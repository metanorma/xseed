# frozen_string_literal: true

require_relative "base"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema list type
      # A whitespace-separated list of values of a single item type
      class ListSymbol < Base
        attr_reader :item_type

        def initialize(name:, type:, xsd_node:)
          super
          @item_type = extract_attribute("itemType")
        end

        # Resolves item type from registry
        def resolve_item_type(type_registry)
          return nil unless @item_type

          type_registry[@item_type]
        end

        # Returns display label for SVG rendering
        def display_label
          "list of #{@item_type}"
        end

        private

        # Extracts attribute from XSD node
        def extract_attribute(attr_name)
          return nil unless @xsd_node.respond_to?(:attributes)

          attributes = @xsd_node.attributes
          return nil unless attributes.is_a?(Hash)

          attributes[attr_name]
        end
      end
    end
  end
end
