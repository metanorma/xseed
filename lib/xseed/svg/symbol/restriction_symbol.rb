# frozen_string_literal: true

require_relative "base"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema restriction
      # Used within simpleContent or complexContent to restrict a base type
      class RestrictionSymbol < Base
        attr_reader :base_type, :facets

        def initialize(name:, type:, xsd_node:)
          @facets = []
          super
          @base_type = extract_attribute("base")
        end

        # Returns derivation method
        def derivation_method
          :restriction
        end

        # Adds facet to restriction
        def add_facet(facet)
          @facets << facet
          facet
        end

        # Returns true if has facets
        def has_facets?
          !@facets.empty?
        end

        # Returns display label for SVG rendering
        def display_label
          label = "restriction of #{@base_type}"
          label += " (#{@facets.size} facets)" if @facets.size.positive?
          label
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
