# frozen_string_literal: true

require_relative "base"

module Xseed
  module Svg
    module Symbol
      class CollapsedSymbol < Base
        attr_reader :original_element, :collapsed_depth, :expansion_data

        def initialize(original_element:, collapsed_depth:, expansion_data: {})
          @original_element = original_element
          @collapsed_depth = collapsed_depth
          @expansion_data = expansion_data

          element_name = if original_element.respond_to?(:[])
                           original_element["name"]&.to_s || "element"
                         elsif original_element.respond_to?(:name)
                           original_element.name || "element"
                         else
                           "element"
                         end

          mock_node = if original_element.respond_to?(:document)
                        original_element
                      else
                        create_mock_node(element_name)
                      end

          super(
            name: element_name,
            type: "collapsed",
            xsd_node: mock_node
          )

          @original_type = extract_type_ref
        end

        def collapsed?
          true
        end

        def original_type
          @original_type
        end

        def collapse_indicator
          "..."
        end

        def tooltip_text
          "Collapsed at depth #{@collapsed_depth}. Click to expand full structure."
        end

        def expandable?
          !@expansion_data.empty?
        end

        def type_info
          @original_type
        end

        private

        def extract_type_ref
          if @original_element.respond_to?(:[])
            @original_element["type"]
          elsif @expansion_data[:type_ref]
            @expansion_data[:type_ref]
          end
        end

        def create_mock_node(name)
          require "ostruct"
          OpenStruct.new(
            name: name,
            annotation: nil,
            namespace: nil,
            namespace_prefix: nil
          )
        end

        def calculate_bounds
          super
          @width += 20
        end
      end
    end
  end
end
