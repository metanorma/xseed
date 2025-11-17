# frozen_string_literal: true

require_relative "base"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema sequence compositor
      # Elements must appear in specified order
      class SequenceSymbol < Base
        # Returns compositor type
        def compositor_type
          :sequence
        end

        # Returns true as sequence is ordered
        def ordered?
          true
        end

        # Returns minimum occurrences
        def min_occurs
          @min_occurs ||= extract_occurs("minOccurs", 1)
        end

        # Returns maximum occurrences
        def max_occurs
          @max_occurs ||= extract_occurs("maxOccurs", 1)
        end

        # Returns true if sequence is optional
        def optional?
          min_occurs.zero?
        end

        # Returns true if sequence can repeat
        def repeatable?
          max_occurs > 1
        end

        # Returns display label for SVG rendering
        def display_label
          label = "sequence"
          label += " [#{occurrence_display}]" if occurrence_display
          label
        end

        private

        # Extracts occurrence attribute
        def extract_occurs(attr_name, default)
          value = extract_attribute(attr_name)
          return default if value.nil?
          return Float::INFINITY if value == "unbounded"

          value.to_i
        end

        # Extracts attribute from XSD node
        def extract_attribute(attr_name)
          return nil unless @xsd_node.respond_to?(:attributes)

          attributes = @xsd_node.attributes
          return nil unless attributes.is_a?(Hash)

          attr = attributes[attr_name]
          # Nokogiri returns Attr objects, extract the value
          attr.respond_to?(:value) ? attr.value : attr
        end

        # Returns occurrence display string
        def occurrence_display
          return nil if min_occurs == 1 && max_occurs == 1

          max_str = max_occurs == Float::INFINITY ? "*" : max_occurs.to_s
          "#{min_occurs}..#{max_str}"
        end
      end
    end
  end
end
