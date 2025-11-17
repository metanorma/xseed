# frozen_string_literal: true

require_relative "sequence_symbol"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema all compositor
      # All child elements must appear (in any order)
      class AllSymbol < SequenceSymbol
        # Returns compositor type
        def compositor_type
          :all
        end

        # Returns false as all group is not ordered
        def ordered?
          false
        end

        # Returns true as all children are required
        def all_required?
          true
        end

        # Returns display label for SVG rendering
        def display_label
          label = "all"
          label += " [#{occurrence_display}]" if occurrence_display
          label
        end
      end
    end
  end
end
