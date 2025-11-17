# frozen_string_literal: true

module Xseed
  module Svg
    module Simplification
      class PatternRegistry
        attr_reader :complex_types, :element_patterns, :attribute_sets

        def initialize
          @complex_types = Hash.new(0)
          @element_patterns = Hash.new(0)
          @attribute_sets = Hash.new(0)
        end

        def register_complex_type(type_name)
          @complex_types[type_name] += 1
        end

        def register_element_pattern(element_name)
          @element_patterns[element_name] += 1
        end

        def register_attribute_set(attributes)
          signature = generate_attribute_signature(attributes)
          @attribute_sets[signature] += 1
        end

        def should_simplify_complex_type?(type_name, threshold)
          @complex_types[type_name] >= threshold
        end

        def should_simplify_element?(element_name, threshold)
          @element_patterns[element_name] >= threshold
        end

        def should_simplify_attributes?(attributes, threshold)
          signature = generate_attribute_signature(attributes)
          @attribute_sets[signature] >= threshold
        end

        def get_pattern_count(pattern_type, pattern_key)
          case pattern_type
          when :complex_type
            @complex_types[pattern_key]
          when :element
            @element_patterns[pattern_key]
          when :attribute_set
            signature = generate_attribute_signature(pattern_key)
            @attribute_sets[signature]
          else
            0
          end
        end

        def patterns_above_threshold(pattern_type, threshold)
          collection = case pattern_type
                       when :complex_type
                         @complex_types
                       when :element
                         @element_patterns
                       when :attribute_set
                         @attribute_sets
                       else
                         {}
                       end

          collection.select { |_key, count| count >= threshold }.keys
        end

        def pattern_summary
          {
            complex_types: @complex_types.size,
            element_patterns: @element_patterns.size,
            attribute_sets: @attribute_sets.size,
            total: @complex_types.size + @element_patterns.size + @attribute_sets.size
          }
        end

        def reset
          @complex_types.clear
          @element_patterns.clear
          @attribute_sets.clear
        end

        private

        def generate_attribute_signature(attributes)
          return "" if attributes.nil? || attributes.empty?
          Array(attributes).map(&:to_s).sort.join("|")
        end
      end
    end
  end
end
