# frozen_string_literal: true

require_relative "base"

module Xseed
  module Svg
    module Symbol
      # Symbol representing an element as the root of a diagram (single-element mode)
      # Similar to ElementSymbol but serves as the root node in single-element diagrams
      # Sized like elements (not schema) with both input and output connection points
      class ElementRootSymbol < Base
        attr_reader :element_name, :target_namespace

        def initialize(element_name:, target_namespace: nil, xsd_node:)
          @element_name = element_name
          @target_namespace = target_namespace
          super(name: element_name, type: "element_root", xsd_node: xsd_node)
        end

        private

        # ElementRoot is sized like elements, not schema
        # Calculates width based on element name and optional target namespace
        def calculate_bounds
          # Collect fields that will be displayed
          fields = []

          # Add target_namespace if present
          if @target_namespace && !@target_namespace.empty?
            fields << @target_namespace.to_s
          end

          # Add element name
          fields << @element_name.to_s

          # Find longest field
          max_chars = fields.map(&:length).max || @element_name.length

          # Width = extraPixels + chars * CHAR_WIDTH (per XSDVI pattern)
          extra_pixels = NAME_PADDING
          @width = [MIN_WIDTH, extra_pixels + (max_chars * CHAR_WIDTH)].max

          # Use element height (not schema height)
          @height = DEFAULT_HEIGHT
        end

        # ElementRoot has both input and output connection points like regular elements
        def calculate_connection_points
          @connection_points = [
            { x: @width / 2, y: 0, type: :input },
            { x: @width / 2, y: @height, type: :output }
          ]
        end
      end
    end
  end
end