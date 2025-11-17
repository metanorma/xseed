# frozen_string_literal: true

module Xseed
  module Svg
    module Symbol
      # Compact symbol representing a type reference
      # Used when a type has been expanded elsewhere
      class TypeReferenceSymbol < Base
        attr_reader :type_name, :reference_location

        def initialize(name:, type_name:, xsd_node:, reference_location: nil)
          @type_name = type_name
          @reference_location = reference_location
          super(name: "→ #{type_name}", type: "type_reference", xsd_node: xsd_node)
        end

        # Override calculate_bounds for compact display
        def calculate_bounds
          # Compact width for type references
          type_display = @type_name.to_s.sub(/^xs:/, '').sub(/^xsd:/, '')
          text_length = "→ #{type_display}".length
          @width = [MIN_WIDTH, NAME_PADDING + (text_length * CHAR_WIDTH)].max
          @height = DEFAULT_HEIGHT
        end

        # Type references are always leaf nodes
        def leaf?
          true
        end

        # Type references render with special indicator
        def reference_indicator
          "→"
        end
      end
    end
  end
end