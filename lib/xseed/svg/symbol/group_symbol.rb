# frozen_string_literal: true

require_relative "base"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema group definition or reference
      # Can reference other named groups
      class GroupSymbol < Base
        # Returns ref attribute for group references
        def ref
          @ref ||= extract_attribute("ref")
        end

        # Returns true if this is a group reference
        def is_reference?
          !ref.nil?
        end

        # Resolves group reference using group registry
        def resolve_reference(group_registry)
          return nil unless ref

          group_registry[ref]
        end

        # Returns display label for SVG rendering
        def display_label
          if is_reference?
            "group → #{ref}"
          else
            "group: #{@name}"
          end
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
