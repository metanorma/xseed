# frozen_string_literal: true

module Xseed
  module Svg
    # Layout engine for positioning SVG symbols in a hierarchical tree structure
    # Uses a vertical tree layout with proper spacing and collision avoidance
    class LayoutEngine
      # Layout spacing constants matching XSDVI
      # XSDVI uses X_INDENT = 45, Y_INDENT = 25
      HORIZONTAL_SPACING = 45  # Space between parent and child horizontally (X_INDENT)
      VERTICAL_SPACING = 71    # Space between siblings (MAX_HEIGHT 46 + Y_INDENT 25)
      MAX_HEIGHT = 46          # XSDVI MAX_HEIGHT constant for spacing calculations
      Y_INDENT = 25            # XSDVI Y_INDENT constant
      MARGIN = 10
      ROOT_X = 20              # XSDVI root starts at x=20
      ROOT_Y = 50              # XSDVI root starts at y=50

      attr_reader :root

      def initialize(root_symbol)
        @root = root_symbol
        @viewport_width = 0
        @viewport_height = 0
        @max_x = 0
        @max_y = 0
      end

      # Performs layout of entire symbol tree and calculates viewport
      # @return [Hash] viewport dimensions { width:, height: }
      def layout
        reset_bounds
        @highest_y_position = ROOT_Y
        position_symbol(@root, ROOT_X, ROOT_Y)
        calculate_viewport
        viewport
      end

      # Returns calculated viewport dimensions
      # @return [Hash] with :width and :height keys
      def viewport
        { width: @viewport_width, height: @viewport_height }
      end

      private

      # Resets tracking variables before layout
      def reset_bounds
        @max_x = 0
        @max_y = 0
      end

      # Recursively positions a symbol and its children using XSDVI algorithm
      # @param symbol [Symbol::Base] the symbol to position
      # @param x [Numeric] x coordinate for this symbol
      # @param y [Numeric] y coordinate for this symbol
      # @return [Numeric] the vertical space consumed by this symbol and its children
      def position_symbol(symbol, x, y)
        # Position current symbol
        symbol.set_position(x, y)

        # Track maximum bounds
        update_bounds(symbol)

        # Update highest Y position for XSDVI algorithm
        # This is used by siblings to determine their Y position
        @highest_y_position = y

        # If no children, return height consumed
        return symbol.height if symbol.children.empty?

        # Position children using XSDVI algorithm (AbstractSymbol.java:207-224):
        # - First child shares parent's Y position (highestYPosition)
        # - Subsequent children are placed below: highestYPosition + MAX_HEIGHT + Y_INDENT
        child_x = x + symbol.width + HORIZONTAL_SPACING

        symbol.children.each_with_index do |child, index|
          if index.zero?
            # First child shares parent's Y position (XSDVI critical pattern)
            child_y = @highest_y_position
          else
            # Subsequent children: highestYPosition + MAX_HEIGHT + Y_INDENT
            # Use VERTICAL_SPACING constant which equals MAX_HEIGHT (46) + Y_INDENT (25) = 71
            child_y = @highest_y_position + VERTICAL_SPACING
          end

          # Recursively position child
          # This updates @highest_y_position to the child's Y position
          position_symbol(child, child_x, child_y)
        end

        symbol.height
      end

      # Updates maximum bounds tracking
      # @param symbol [Symbol::Base] symbol to check bounds of
      def update_bounds(symbol)
        symbol_right = symbol.x + symbol.width
        symbol_bottom = symbol.y + symbol.height

        @max_x = symbol_right if symbol_right > @max_x
        @max_y = symbol_bottom if symbol_bottom > @max_y
      end

      # Calculates final viewport dimensions with margins
      def calculate_viewport
        @viewport_width = @max_x + MARGIN
        @viewport_height = @max_y + MARGIN
      end
    end
  end
end
