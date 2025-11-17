# frozen_string_literal: true

require_relative "base"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema union type
      # Allows values from multiple member types
      class UnionSymbol < Base
        attr_reader :member_types

        def initialize(name:, type:, xsd_node:)
          @member_types = []
          super
          parse_member_types
        end

        # Adds member type to union
        def add_member_type(type_name)
          @member_types << type_name
          type_name
        end

        # Resolves all member types from registry
        def resolve_member_types(type_registry)
          @member_types.filter_map { |mt| type_registry[mt] }
        end

        # Returns display label for SVG rendering
        def display_label
          "union of #{@member_types.size} types"
        end

        private

        # Parses memberTypes attribute into array
        def parse_member_types
          member_types_str = extract_attribute("memberTypes")
          return unless member_types_str

          @member_types = member_types_str.split(/\s+/)
        end

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
