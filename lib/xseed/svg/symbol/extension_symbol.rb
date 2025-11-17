# frozen_string_literal: true

require_relative "base"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema extension
      # Used within simpleContent or complexContent to extend a base type
      class ExtensionSymbol < Base
        attr_reader :base_type

        def initialize(name:, type:, xsd_node:)
          super
          @base_type = extract_attribute("base")
        end

        # Returns derivation method
        def derivation_method
          :extension
        end

        # Resolves base type from registry
        def resolve_base_type(type_registry)
          return nil unless @base_type

          type_registry[@base_type]
        end

        # Returns display label for SVG rendering
        def display_label
          "extension of #{@base_type}"
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
