# frozen_string_literal: true

module Xseed
  module Svg
    module Symbol
      # Symbol representing a loop/circular reference in XSD structure
      # Indicates that recursion was detected and prevents infinite loops
      # Renders as a small indicator box with arrow notation
      class LoopSymbol < Base
        attr_reader :target_name

        def initialize(name:, target_name:, xsd_node:)
          @target_name = target_name
          # Display with arrow notation to indicate loop/recursion (matching XSDVI)
          super(name: "→ #{target_name}", type: "loop", xsd_node: xsd_node)
        end

        private

        # Loop indicators are smaller boxes - just enough to show the arrow
        def calculate_bounds
          # Calculate width based on the arrow notation display including target name
          text_width = @name.to_s.length * CHAR_WIDTH
          @width = [text_width + NAME_PADDING, MIN_WIDTH].max

          # Use MID_HEIGHT for compact display (like compositors)
          @height = MID_HEIGHT
        end

        # Loop symbols have both input and output points for consistency
        # even though they don't spawn new children
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