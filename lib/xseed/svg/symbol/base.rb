# frozen_string_literal: true

module Xseed
  module Svg
    module Symbol
      # Base class for all SVG symbols representing XSD components
      # Provides common functionality for positioning, relationships, and documentation
      class Base
        attr_reader :name, :type, :xsd_node, :children, :connection_points
        attr_accessor :x, :y, :width, :height, :parent

        # Default dimensions matching XSDVI
        MIN_WIDTH = 153             # XSDVI element width (from reference SVGs)
        MIN_COMPACT_WIDTH = 80      # Smaller minimum for compact symbols (identity constraints)
        MAX_HEIGHT = 46             # XSDVI MAX_HEIGHT (for normal elements)
        MID_HEIGHT = 31             # XSDVI MID_HEIGHT (for compositors)
        DEFAULT_WIDTH = MIN_WIDTH
        DEFAULT_HEIGHT = MAX_HEIGHT
        NAME_PADDING = 10
        CHAR_WIDTH = 6              # XSDVI uses approximately 6px per character

        # Connection point radius
        CONNECTION_RADIUS = 2

        def initialize(name:, type:, xsd_node:)
          # Convert Nokogiri::XML::Attr to string value
          @name = name.respond_to?(:value) ? name.value : name.to_s
          @type = type
          @xsd_node = xsd_node
          @children = []
          @parent = nil
          @x = 0
          @y = 0
          @connection_points = []

          calculate_bounds
          calculate_connection_points
        end

        # Returns bounding box as hash with position and dimensions
        def bounding_box
          {
            x: @x,
            y: @y,
            width: @width,
            height: @height
          }
        end

        # Sets position of symbol
        def set_position(x, y)
          @x = x
          @y = y
        end

        # Adds child symbol and establishes parent relationship
        def add_child(child_symbol)
          @children << child_symbol
          child_symbol.parent = self
          child_symbol
        end

        # Removes child symbol and clears parent relationship
        def remove_child(child_symbol)
          return nil unless @children.include?(child_symbol)

          @children.delete(child_symbol)
          child_symbol.parent = nil
          child_symbol
        end

        # Returns documentation text from XSD annotation
        def documentation
          return nil unless @xsd_node

          # First try to get documentation from annotation object (for mock objects/testing)
          if @xsd_node.respond_to?(:annotation) && @xsd_node.annotation
            annotation = @xsd_node.annotation
            return annotation.documentation if annotation.respond_to?(:documentation)
          end

          # Fall back to XPath for real XML nodes
          return nil unless @xsd_node.respond_to?(:at_xpath)

          # Use XPath to extract documentation from xs:annotation/xs:documentation
          doc_node = begin
            @xsd_node.at_xpath(
              'xs:annotation/xs:documentation',
              'xs' => 'http://www.w3.org/2001/XMLSchema'
            )
          rescue StandardError
            nil
          end

          return nil unless doc_node

          doc_node.text&.strip
        end

        # Returns namespace from XSD node
        def namespace
          @xsd_node.respond_to?(:namespace) ? @xsd_node.namespace : nil
        end

        # Returns qualified name with namespace prefix
        def qualified_name
          if @xsd_node.respond_to?(:namespace_prefix) && @xsd_node.namespace_prefix
            "#{@xsd_node.namespace_prefix}:#{@name}"
          else
            @name
          end
        end

        # Returns true if symbol has no children
        def leaf?
          @children.empty?
        end

        # Returns true if symbol has no parent
        def root?
          @parent.nil?
        end

        # Returns depth from root (0 for root symbols)
        def depth
          return 0 if root?

          1 + @parent.depth
        end

        # Returns array of ancestor symbols from parent to root
        def ancestors
          return [] if root?

          ancestors_list = [@parent]
          current = @parent
          until current.root?
            current = current.parent
            ancestors_list << current
          end
          ancestors_list
        end

        # Returns array of all descendant symbols (recursive)
        def descendants
          result = []
          @children.each do |child|
            result << child
            result.concat(child.descendants)
          end
          result
        end

        # Returns input connection point (top-center by default)
        def input_point
          connection_points.find { |p| p[:type] == :input }
        end

        # Returns output connection point (bottom-center by default)
        def output_point
          connection_points.find { |p| p[:type] == :output }
        end

        # Returns true if this is a compositor (sequence, choice, all)
        def compositor?
          %w[sequence choice all].include?(@type)
        end

        # Groups child attributes by their patterns (occurrence, type, etc.)
        # Returns hash with pattern signature as key and array of attributes as value
        def group_attributes_by_pattern
          attributes = @children.select { |c| c.type == "attribute" }
          return {} if attributes.empty?

          groups = {}
          attributes.each do |attr|
            pattern = attribute_pattern_signature(attr)
            groups[pattern] ||= []
            groups[pattern] << attr
          end
          groups
        end

        # Returns a signature string representing an attribute's pattern
        def attribute_pattern_signature(attr)
          parts = []
          parts << (attr.respond_to?(:optional?) && attr.optional? ? "optional" : "required")
          parts << (attr.respond_to?(:type_ref) ? attr.type_ref.to_s : "string")
          parts.join(":")
        end

        private

        # Calculates initial bounding box dimensions based on content
        # Accounts for all text fields that will be displayed (XSDVI WidthCalculator pattern)
        def calculate_bounds
          # Collect all fields that will be displayed
          fields = []

          # Add target_namespace if present (for ElementSymbol)
          if respond_to?(:target_namespace) && target_namespace && !target_namespace.empty?
            fields << target_namespace.to_s
          # Also check for namespace from xsd_node
          elsif @xsd_node.respond_to?(:namespace) && @xsd_node.namespace && !@xsd_node.namespace.to_s.empty?
            fields << @xsd_node.namespace.to_s
          end

          # Always add name
          fields << @name.to_s

          # Add type info if present (with "type: " prefix) - strip xs:/xsd: prefix for width calculation
          if respond_to?(:type_info) && type_info
            type_display = type_info.to_s.sub(/^xs:/, '').sub(/^xsd:/, '')
            fields << "type: #{type_display}"
          elsif respond_to?(:type_ref) && type_ref
            type_display = type_ref.to_s.sub(/^xs:/, '').sub(/^xsd:/, '')
            fields << "type: #{type_display}"
          end

          # Add cardinality if present
          if respond_to?(:min_occurs)
            min = respond_to?(:min_occurs) ? min_occurs.to_i : 1
            max = respond_to?(:max_occurs) ? max_occurs : 1
            max_val = max == Float::INFINITY ? Float::INFINITY : max.to_i

            # Only add if not default (1..1)
            unless min == 1 && max_val == 1
              max_str = max_val == Float::INFINITY ? "*" : max_val.to_s
              fields << "#{min}..#{max_str}"
            end
          end

          # Find longest field
          max_chars = fields.map(&:length).max || 0

          # Width = extraPixels + chars * CHAR_WIDTH (per XSDVI WidthCalculator.java)
          extra_pixels = NAME_PADDING
          @width = [MIN_WIDTH, extra_pixels + (max_chars * CHAR_WIDTH)].max

          # Calculate height (can be adjusted by subclasses)
          @height = DEFAULT_HEIGHT
        end

        # Calculates connection points for this symbol
        # Default: one input point at top-center, one output at bottom-center
        # Compositor types (sequence, choice, all) get multiple points
        def calculate_connection_points
          if compositor?
            calculate_compositor_connection_points
          else
            calculate_default_connection_points
          end
        end

        # Default connection points for regular symbols
        def calculate_default_connection_points
          @connection_points = [
            { x: @width / 2, y: 0, type: :input },
            { x: @width / 2, y: @height, type: :output }
          ]
        end

        # Connection points for compositor symbols (sequence, choice, all)
        # Multiple output points on the right side for child connections
        def calculate_compositor_connection_points
          # Input point at left-center
          @connection_points = [
            { x: 0, y: @height / 2, type: :input }
          ]

          # Add output points for each child (or 3 by default)
          child_count = [@children.size, 3].max
          child_count = [child_count, 1].max

          # Distribute output points vertically on right side
          spacing = @height / (child_count + 1).to_f
          child_count.times do |i|
            y_pos = spacing * (i + 1)
            @connection_points << {
              x: @width,
              y: y_pos,
              type: :output,
              index: i
            }
          end
        end
      end
    end
  end
end
