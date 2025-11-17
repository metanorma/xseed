# frozen_string_literal: true

module Xseed
  module Svg
    module Symbol
      # Symbol representing the XSD schema root element
      # Schema symbols are wider to accommodate namespace display
      # and only have output connection points (no input)
      class SchemaSymbol < Base
        attr_reader :namespace

        def initialize(name:, type:, xsd_node:, namespace: nil)
          @namespace = namespace
          super(name: name, type: type, xsd_node: xsd_node)
        end

        private

        # Schema boxes are wider to accommodate namespace prefix display
        def calculate_bounds
          # Calculate width based on both name and namespace
          name_chars = @name.to_s.length
          namespace_chars = @namespace.to_s.length
          total_chars = name_chars + namespace_chars + 2 # +2 for separator

          # Width = extraPixels + chars * CHAR_WIDTH (per XSDVI pattern)
          extra_pixels = NAME_PADDING + 10 # Extra padding for schema root
          @width = [MIN_WIDTH, extra_pixels + (total_chars * CHAR_WIDTH)].max
          @height = MAX_HEIGHT
        end

        # Schema symbols only have output points (no input) since they're root
        def calculate_connection_points
          @connection_points = [
            { x: @width / 2, y: @height, type: :output }
          ]
        end
      end
    end
  end
end