# frozen_string_literal: true

require_relative "base"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema any wildcard
      # Allows elements from specified namespaces
      class AnySymbol < Base
        # Returns namespace constraint
        def wildcard_namespace
          @wildcard_namespace ||= extract_attribute("namespace") || "##any"
        end

        # Returns process contents mode
        def process_contents
          @process_contents ||= extract_attribute("processContents") || "strict"
        end

        # Returns minimum occurrences
        def min_occurs
          @min_occurs ||= extract_occurs("minOccurs", 1)
        end

        # Returns maximum occurrences
        def max_occurs
          @max_occurs ||= extract_occurs("maxOccurs", 1)
        end

        # Checks if wildcard accepts given namespace
        def accepts_namespace?(namespace_uri)
          case wildcard_namespace
          when "##any"
            true
          when "##other"
            namespace_uri != @xsd_node.namespace
          else
            wildcard_namespace.split(/\s+/).include?(namespace_uri)
          end
        end

        # Returns display label for SVG rendering
        def display_label
          "any (#{wildcard_namespace}, #{process_contents})"
        end

        private

        # Extracts occurrence attribute
        def extract_occurs(attr_name, default)
          value = extract_attribute(attr_name)
          return default if value.nil?
          return Float::INFINITY if value == "unbounded"

          value.to_i
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
      end
    end
  end
end
