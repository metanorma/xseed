# frozen_string_literal: true

require_relative "base"
require_relative "selector_symbol"
require_relative "field_symbol"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema xs:key identity constraint
      # Keys define uniqueness constraints within a specific scope
      class KeySymbol < Base
        attr_reader :selector, :fields

        def initialize(name:, xsd_node:)
          super(name: name, type: "key", xsd_node: xsd_node)
          @selector = extract_selector
          @fields = extract_fields
          create_child_symbols
        end

        # Returns selector XPath expression
        def selector_xpath
          return nil unless @selector

          @selector.respond_to?(:[]) ? @selector["xpath"] : @selector.xpath
        end

        # Returns array of field XPath expressions
        def field_xpaths
          @fields.map do |f|
            f.respond_to?(:[]) ? f["xpath"] : f.xpath
          end.compact
        end

        private

        # Extracts selector element from XSD node
        def extract_selector
          return nil unless @xsd_node.respond_to?(:selector)

          @xsd_node.selector
        end

        # Extracts field elements from XSD node
        def extract_fields
          return [] unless @xsd_node.respond_to?(:field)

          fields = @xsd_node.field
          fields.is_a?(Array) ? fields : [fields].compact
        end

        # Creates child symbols for selector and fields
        def create_child_symbols
          # Add selector symbol if present
          if @selector
            selector_sym = SelectorSymbol.new(xsd_node: @selector)
            add_child(selector_sym)
          end

          # Add field symbols if present
          @fields.each do |field|
            field_sym = FieldSymbol.new(xsd_node: field)
            add_child(field_sym)
          end
        end

        # Override calculate_bounds for compact height
        def calculate_bounds
          # Calculate width based on name - allow to grow beyond MIN_COMPACT_WIDTH for long names
          text_width = (@name.length * CHAR_WIDTH) + NAME_PADDING
          @width = [MIN_COMPACT_WIDTH, text_width].max

          # Use compact height for constraints
          @height = MID_HEIGHT
        end
      end
    end
  end
end