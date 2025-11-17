# frozen_string_literal: true

require_relative "base"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema simple type definition
      # Handles restrictions, lists, unions, and facets
      class SimpleTypeSymbol < Base
        attr_accessor :variety, :base_type, :item_type, :primitive_type
        attr_reader :facets, :member_types

        def initialize(name:, type:, xsd_node:)
          @facets = []
          @member_types = []
          super
        end

        # Returns true if variety matches given type
        def variety?(variety_type)
          @variety == variety_type
        end

        # Returns true if type is restriction
        def restriction?
          @variety == :restriction
        end

        # Returns true if type is list
        def list?
          @variety == :list
        end

        # Returns true if type is union
        def union?
          @variety == :union
        end

        # Adds facet to simple type
        def add_facet(facet)
          @facets << facet
          facet
        end

        # Returns true if type has facets
        def has_facets?
          !@facets.empty?
        end

        # Returns facet by type
        def facet(facet_type)
          @facets.find { |f| f[:type] == facet_type }
        end

        # Returns all facets of given type
        def facets_of_type(facet_type)
          @facets.select { |f| f[:type] == facet_type }
        end

        # Returns array of enumeration values
        def enumeration_values
          facets_of_type(:enumeration).map { |f| f[:value] }
        end

        # Returns pattern value
        def pattern_value
          facet(:pattern)&.dig(:value)
        end

        # Returns minLength value
        def min_length
          facet(:minLength)&.dig(:value)
        end

        # Returns maxLength value
        def max_length
          facet(:maxLength)&.dig(:value)
        end

        # Returns length value
        def length
          facet(:length)&.dig(:value)
        end

        # Adds member type to union
        def add_member_type(type_name)
          @member_types << type_name
          type_name
        end

        # Returns final derivation constraints
        def final
          @final ||= extract_attribute("final")
        end

        # Returns true if type is built-in XSD type
        def built_in?
          return false unless namespace

          namespace == "http://www.w3.org/2001/XMLSchema"
        end

        # Resolves base type from registry
        def resolve_base_type(type_registry)
          return nil unless @base_type

          type_registry[@base_type]
        end

        # Returns display label for SVG rendering
        def display_label
          label = @name.to_s

          if restriction? && @base_type
            label += " (restriction of #{@base_type})"
          elsif list? && @item_type
            label += " (list of #{@item_type})"
          elsif union? && !@member_types.empty?
            label += " (union of #{@member_types.size} types)"
          end

          enum_count = enumeration_values.size
          label += " [#{enum_count} enums]" if enum_count.positive?

          label
        end

        # Returns summary of all facets
        def facet_summary
          return "" if @facets.empty?

          @facets.map { |f| "#{f[:type]}: #{f[:value]}" }.join(", ")
        end

        private

        # Extracts attribute from XSD node
        def extract_attribute(attr_name)
          return nil unless @xsd_node.respond_to?(:attributes)

          attributes = @xsd_node.attributes
          return nil unless attributes.is_a?(Hash)

          attributes[attr_name]
        end

        # Override calculate_bounds to account for variety and facets
        def calculate_bounds
          super

          # Add width for variety indicator
          @width += 30 if @variety

          # Adjust height for facets
          if @facets.size.positive?
            @height = DEFAULT_HEIGHT + (@facets.size * 20)
          end

          # Ensure minimum width
          @width = [@width, 100].max
        end
      end
    end
  end
end
