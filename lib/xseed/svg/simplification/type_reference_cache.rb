# frozen_string_literal: true

module Xseed
  module Svg
    module Simplification
      # Tracks type reference expansion to enable pattern reuse
      # Determines when types should be inlined vs referenced
      class TypeReferenceCache
        attr_reader :expanded_types, :reference_counts, :always_inline

        def initialize(always_inline: false)
          @always_inline = always_inline
          @expanded_types = Hash.new { |h, k| h[k] = [] }
          @reference_counts = Hash.new(0)
        end

        # Track an expansion of a type at a specific location
        def mark_expanded(type_name, location_id)
          return unless type_name

          @expanded_types[type_name] << location_id
          @reference_counts[type_name] += 1
        end

        # Check if a type should be inlined (first occurrence)
        # or referenced (subsequent occurrences)
        # When always_inline is true, always returns true
        def should_inline?(type_name, threshold: 2)
          return true if @always_inline
          return true unless type_name
          return true if @reference_counts[type_name] < threshold

          false
        end

        # Get the first expansion location for creating a reference
        def get_reference(type_name)
          return nil unless type_name

          locations = @expanded_types[type_name]
          return nil if locations.empty?

          locations.first
        end

        # Check if a type has been expanded before
        def expanded?(type_name)
          return false unless type_name

          @reference_counts[type_name] > 0
        end

        # Get expansion count for a type
        def expansion_count(type_name)
          return 0 unless type_name

          @reference_counts[type_name]
        end

        # Get all types above a certain usage threshold
        def frequent_types(threshold: 2)
          @reference_counts.select { |_type, count| count >= threshold }.keys
        end

        # Reset the cache
        def reset
          @expanded_types.clear
          @reference_counts.clear
        end

        # Get cache statistics
        def statistics
          {
            total_types: @expanded_types.size,
            total_expansions: @reference_counts.values.sum,
            frequent_types: frequent_types.size,
            max_expansions: @reference_counts.values.max || 0
          }
        end
      end
    end
  end
end