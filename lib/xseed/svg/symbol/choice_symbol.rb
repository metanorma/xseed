# frozen_string_literal: true

require_relative "sequence_symbol"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema choice compositor
      # One of the child elements must appear
      class ChoiceSymbol < SequenceSymbol
        # Returns compositor type
        def compositor_type
          :choice
        end

        # Returns false as choice is not ordered
        def ordered?
          false
        end

        # Returns true as choice is exclusive
        def exclusive?
          true
        end

        # Returns display label for SVG rendering
        def display_label
          label = "choice"
          label += " [#{occurrence_display}]" if occurrence_display
          label
        end
      end
    end
  end
end
