# frozen_string_literal: true

require_relative "base"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema notation declaration
      # Used to reference external data formats
      class NotationSymbol < Base
        # Returns public identifier
        def public_id
          @public_id ||= extract_attribute("public")
        end

        # Returns system identifier
        def system_id
          @system_id ||= extract_attribute("system")
        end

        # Returns display label for SVG rendering
        def display_label
          "notation: #{@name}"
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
