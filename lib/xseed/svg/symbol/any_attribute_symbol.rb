# frozen_string_literal: true

require_relative "base"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema xs:anyAttribute wildcard
      # Allows any attribute from specified namespaces
      class AnyAttributeSymbol < Base
        attr_reader :namespace, :process_contents

        def initialize(xsd_node:)
          namespace = extract_namespace(xsd_node)
          super(name: "anyAttribute", type: "anyAttribute", xsd_node: xsd_node)
          @namespace = namespace
          @process_contents = extract_process_contents
        end

        # Returns display label for SVG rendering
        def display_label
          "anyAttribute: #{@namespace}"
        end

        private

        # Extracts namespace attribute
        def extract_namespace(node)
          return "##any" unless node.respond_to?(:attributes)

          attributes = node.attributes
          return "##any" unless attributes.is_a?(Hash)

          attributes["namespace"] || "##any"
        end

        # Extracts processContents attribute
        def extract_process_contents
          return "strict" unless @xsd_node.respond_to?(:attributes)

          attributes = @xsd_node.attributes
          return "strict" unless attributes.is_a?(Hash)

          attributes["processContents"] || "strict"
        end

        # Override calculate_bounds for anyAttribute display
        def calculate_bounds
          text = "anyAttribute: #{@namespace}"
          calculated_width = (text.length * CHAR_WIDTH) + 10
          @width = [MIN_WIDTH, calculated_width].max

          # Use compact height
          @height = MID_HEIGHT
        end
      end
    end
  end
end