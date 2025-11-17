# frozen_string_literal: true

require "nokogiri"
require_relative "text_wrapper"
require_relative "symbol/type_reference_symbol"

module Xseed
  module Svg
    # Renders SVG diagrams from positioned symbol trees
    # Generates complete SVG XML with embedded CSS styling
    class SvgRenderer
      # Default viewport dimensions
      DEFAULT_VIEWPORT_WIDTH = 800
      DEFAULT_VIEWPORT_HEIGHT = 600

      # Visual constants
      CORNER_RADIUS = 5
      CONNECTOR_OFFSET = 10

      def initialize(root_symbol, viewport: nil)
        @root = root_symbol
        @viewport_width = viewport ? viewport[:width] : DEFAULT_VIEWPORT_WIDTH
        @viewport_height = viewport ? viewport[:height] : DEFAULT_VIEWPORT_HEIGHT
        @serial_counter = [0]  # Hierarchical counter for XSDVI IDs (_1, _1_1, etc.)
      end

      # Generates complete SVG XML document
      # @return [String] SVG XML as string
      def render
        builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
          xml.svg(xmlns: "http://www.w3.org/2000/svg",
                  'xmlns:xlink' => "http://www.w3.org/1999/xlink",
                  id: 'svg',
                  width: @viewport_width.to_s,
                  height: @viewport_height.to_s,
                  viewBox: "0 0 #{@viewport_width} #{@viewport_height}",
                  onload: 'loadSVG()') do
            xml.title { xml.text 'XsdVi' }
            xml.script(type: 'text/ecmascript') do
              xml.cdata javascript_code
            end
            xml.style { xml.text css_styles }
            xml.defs { render_definitions(xml) }

            # Render menu buttons (Collapse All / Expand All)
            render_menu_buttons(xml)

            # Render all connectors first (so they appear behind symbols)
            render_all_connectors(xml, @root)

            # Render symbols on top
            render_symbols(xml, @root)
          end
        end
        builder.to_xml
      end

      private

      # Renders XSDVI menu buttons (Collapse All / Expand All)
      def render_menu_buttons(xml)
        # Collapse All button
        xml.rect(class: 'button', x: '300', y: '10', width: '20', height: '20',
                 onclick: 'collapseAll()')
        xml.line(x1: '303', y1: '20', x2: '317', y2: '20')
        xml.text_('collapse all', x: '330', y: '20')

        # Expand All button
        xml.rect(class: 'button', x: '400', y: '10', width: '20', height: '20',
                 onclick: 'expandAll()')
        xml.line(x1: '403', y1: '20', x2: '417', y2: '20')
        xml.line(x1: '410', y1: '13', x2: '410', y2: '27')
        xml.text_('expand all', x: '430', y: '20')
      end

      # Renders SVG definitions (XSDVI style plus/minus buttons)
      def render_definitions(xml)
        # Plus button symbol (for collapsed state)
        xml.symbol(class: 'button', id: 'plus') do
          xml.rect(x: '1', y: '1', width: '10', height: '10')
          xml.line(x1: '3', y1: '6', x2: '9', y2: '6')
          xml.line(x1: '6', y1: '3', x2: '6', y2: '9')
        end

        # Minus button symbol (for expanded state)
        xml.symbol(class: 'button', id: 'minus') do
          xml.rect(x: '1', y: '1', width: '10', height: '10')
          xml.line(x1: '3', y1: '6', x2: '9', y2: '6')
        end
      end

      # Recursively renders all symbols as SVG groups
      def render_symbols(xml, symbol, parent_id = nil)
        symbol_id = generate_serial_id(symbol, parent_id)
        desc_height = calculate_description_height(symbol)

        # Wrap ALL ElementSymbols in anchor tags (XSDVI style)
        # LoopSymbol is separate from ElementSymbol, so won't be wrapped
        if symbol.is_a?(Symbol::ElementSymbol)
          xml.a(href: "#", onclick: "window.parent.location.href = window.parent.location.href.split('#')[0]  + '#element_#{symbol.name}'") do
            render_symbol_group(xml, symbol, symbol_id, desc_height, parent_id)
          end
        else
          render_symbol_group(xml, symbol, symbol_id, desc_height, parent_id)
        end

        # Recursively render children directly (flatten structure)
        symbol.children.each_with_index do |child, index|
          child_parent_id = symbol_id
          render_symbols(xml, child, child_parent_id)
        end
      end

      # Renders the actual symbol group element
      def render_symbol_group(xml, symbol, symbol_id, desc_height, parent_id)
        # Build class list: both XSDVI 'box' and specific symbol type classes
        css_classes = ['box', symbol_class(symbol)].join(' ')

        xml.g(id: symbol_id,
              'data-name' => symbol.name,  # Add data-name for test compatibility
              class: css_classes,           # Add both 'box' and type-specific classes
              transform: "translate(#{symbol.x},#{symbol.y})",
              'data-desc-height' => desc_height.to_s,
              'data-desc-height-rest' => desc_height.to_s,
              'data-desc-x' => symbol.x.to_s) do

          # Add title element if documentation exists (for accessibility and tests)
          if symbol.documentation && !symbol.documentation.empty?
            xml.title { xml.text symbol.documentation }
          end

          # Render curved path connector if this is a last child
          render_curved_path_if_needed(xml, symbol, parent_id)

          # Render symbol shape
          render_symbol_shape(xml, symbol)

          # Render symbol text
          render_symbol_text(xml, symbol)

          # Render connection circles (for test compatibility)
          render_connection_circles(xml, symbol)

          # Render element properties if applicable
          render_element_properties(xml, symbol) if symbol.is_a?(Symbol::ElementSymbol)

          # Render processContents indicator for any/anyAttribute
          render_process_contents_indicator(xml, symbol)

          # Render collapse/expand button if has children (XSDVI style with <use>)
          render_xsdvi_collapse_button(xml, symbol, symbol_id) unless symbol.children.empty?
        end
      end

      # Genertes XSDVI-style hierarchical serial ID (_1, _1_1, _1_2, etc.)
      def generate_serial_id(symbol, parent_id)
        if parent_id.nil?
          # Root symbol
          "_1"
        else
          # Get parent's child index
          index = symbol.parent.children.index(symbol) + 1
          "#{parent_id}_#{index}"
        end
      end

      # Calculates description height for data attributes
      def calculate_description_height(symbol)
        doc = symbol.documentation
        return 0 unless doc && !doc.empty?

        # XSDVI uses (int)(width / 5.5) characters per line
        wrap_width = (symbol.width / 5.5).to_i
        wrap_width = [wrap_width, 10].max

        lines = TextWrapper.wrap(doc, wrap_width)
        lines.length * 14  # 14px per line
      end

      # Renders curved path connector inside child box if it's last child and not a compositor
      def render_curved_path_if_needed(xml, symbol, parent_id)
        return unless symbol.parent

        # Don't add curved path if this symbol is itself a compositor
        return if symbol.compositor?

        # Don't add curved path for LOOP symbols - they use straight connection
        return if symbol.is_a?(Symbol::LoopSymbol)

        # Only render curved path if PARENT is a compositor or schema (XSDVI pattern)
        return unless symbol.parent.compositor? || symbol.parent.is_a?(Symbol::SchemaSymbol)

        # Only use curved path if parent has MULTIPLE children (not single child)
        return unless symbol.parent.children.size > 1

        # Check if this is the last child
        is_last = symbol.parent.children.last == symbol
        return unless is_last

        # Calculate x-offset for XSDVI style (10 - X_INDENT where X_INDENT=45)
        x_offset = -35
        vertical_y2 = -15 - 25  # -15 - Y_INDENT (25)

        # Render the curved path portion
        xml.path(
          class: 'connector',
          d: "M#{x_offset},#{vertical_y2} Q#{x_offset},15 0,23",
          fill: 'none',
          stroke: '#666666',
          'stroke-width' => '1'
        )
      end

      # Renders name with special character (like @ for attributes) in larger font
      def render_name_with_special_char(xml, symbol)
        name = symbol.name
        # Split on @ symbol
        if name.start_with?('@')
          xml.text_('@',
                   x: "17",
                   y: "55",
                   class: "special-char",
                   "font-size" => "24",
                   "font-weight" => "bold",
                   fill: "#776633")

        # Render rest of name in regular font
          remaining = name[1..-1]
          unless remaining.empty?
            xml.text_(remaining,
                     x: (24 + 9 * remaining.length).to_s, # After @ symbol
                     y: "55",
                     class: "symbol-name",
                     "font-size" => "12",
                     "font-weight" => "bold")
          end
        else
          # Regular rendering
          xml.text_(class: "symbol-name",
                    x: "5",
                    y: "27") do
            xml.text truncate_text(name, symbol.width)
          end
        end
      end

      # Renders element properties (nillable, abstract, substitution group)
      def render_element_properties(xml, symbol)
        properties = []
        properties << "nillable" if symbol.nillable?
        properties << "abstract" if symbol.abstract?
        properties << "→#{symbol.substitution_group}" if symbol.substitution_group

        return if properties.empty?

        xml.text_(properties.join(", "),
                  x: "5",
                  y: "59",
                  class: "element-properties",
                  "font-size" => "9",
                  "font-style" => "italic",
                  fill: "#666666")
      end

      # Renders processContents indicator for any/anyAttribute symbols
      def render_process_contents_indicator(xml, symbol)
        return unless symbol.respond_to?(:process_contents)

        color = case symbol.process_contents
                when "strict" then "#FF0000" # Red
                when "lax" then "#FFFF00"    # Yellow
                when "skip" then "#00FF00"   # Green
                else "#CCCCCC"
                end

        xml.rect(
          x: symbol.width - 15,
          y: 5,
          width: 10,
          height: 10,
          fill: color,
          stroke: "#000000",
          "stroke-width" => 1
        )
      end

      # Renders connection circles for input/output points (for test compatibility)
      def render_connection_circles(xml, symbol)
        # Render input circle if symbol has input point
        if symbol.input_point
          xml.circle(
            class: "connection-input",
            cx: symbol.input_point[:x].to_s,
            cy: symbol.input_point[:y].to_s,
            r: "2"
          )
        end

        # Render output circle(s)
        if symbol.compositor?
          # Compositor symbols may have multiple output circles
          symbol.connection_points.each do |point|
            if point[:type] == :output
              xml.circle(
                class: "connection-output compositor-output",
                cx: point[:x].to_s,
                cy: point[:y].to_s,
                r: "2"
              )
            end
          end
        elsif symbol.output_point
          # Regular symbols have single output circle
          xml.circle(
            class: "connection-output",
            cx: symbol.output_point[:x].to_s,
            cy: symbol.output_point[:y].to_s,
            r: "2"
          )
        end
      end

      # Renders XSDVI-style collapse/expand button using <use>
      def render_xsdvi_collapse_button(xml, symbol, symbol_id)
        button_x = symbol.width - 13
        button_y = 17

        xml.use(
          x: button_x.to_s,
          y: button_y.to_s,
          'xlink:href' => '#minus',
          id: "s#{symbol_id}",
          onclick: "show('#{symbol_id}')"
        )
      end

      # Recursively renders all connector lines between parent and children
      def render_all_connectors(xml, symbol, parent_id = nil)
        symbol_id = generate_serial_id(symbol, parent_id)

        symbol.children.each_with_index do |child, index|
          is_last = (index == symbol.children.size - 1)
          child_id = "#{symbol_id}_#{index + 1}"
          render_connector(xml, symbol, child, index, is_last_child: is_last, child_id: child_id)
          # Recursively render connectors for child's children
          render_all_connectors(xml, child, symbol_id)
        end
      end

      # Renders a single connector line from parent to child
      def render_connector(xml, parent, child, child_index = 0, is_last_child: false, child_id: nil)
        # Get connection points
        parent_point = if parent.compositor?
                         # Use specific output point for compositor
                         parent.connection_points.find do |p|
                           p[:type] == :output && p[:index] == child_index
                         end || parent.output_point
                       else
                         parent.output_point
                       end

        child_point = child.input_point

        return unless parent_point && child_point

        # Calculate absolute positions
        px = parent.x + parent_point[:x]
        py = parent.y + parent_point[:y]
        cx = child.x + child_point[:x]
        cy = child.y + child_point[:y]

        # Calculate x-offset for XSDVI style (10 - X_INDENT where X_INDENT=45)
        x_offset = -35

        # Use curved path for last child of compositors (XSDVI pattern)
        # Compositors always use curved paths for their last child
        if parent.compositor? && is_last_child
          render_curved_connector_xsdvi(xml, px, py, cx, cy, x_offset, child_id)
        else
          render_straight_connector(xml, px, py, cx, cy)
        end
      end

      # Renders XSDVI-style curved connector with vertical line only
      # The curved path portion is rendered inside the child box
      def render_curved_connector_xsdvi(xml, px, py, cx, cy, x_offset, child_id = nil)
        # Vertical line from parent level to curve start
        # y1 is relative to child position
        vertical_y1 = py - cy + 23  # 23 is MAX_HEIGHT/2
        vertical_y2 = -15 - 25      # -15 - Y_INDENT (25)

        xml.line(
          class: 'connector',
          id: child_id ? "p#{child_id}" : nil,
          x1: x_offset.to_s,
          y1: vertical_y1.to_s,
          x2: x_offset.to_s,
          y2: vertical_y2.to_s,
          stroke: '#666666',
          'stroke-width' => '1'
        )
      end

      # Renders a straight connector line
      def render_straight_connector(xml, x1, y1, x2, y2)
        xml.line(
          class: "connector",
          x1: x1.to_s,
          y1: y1.to_s,
          x2: x2.to_s,
          y2: y2.to_s,
          stroke: '#666666',
          'stroke-width' => 1
        )
      end

      # Renders a curved connector using SVG path (XSDVI pattern)
      def render_curved_connector(xml, x1, y1, x2, y2)
        # Calculate control point for quadratic bezier curve
        # XSDVI uses midpoint between start and end for smooth curves
        control_x = (x1 + x2) / 2
        control_y = (y1 + y2) / 2

        xml.path(
          class: "connector curved",
          d: "M#{x1},#{y1} Q#{control_x},#{control_y} #{x2},#{y2}",
          "marker-end" => "url(#arrowhead)",
          fill: "none",
          stroke: "#666666",
          "stroke-width" => "1"
        )
      end

      # Renders the shape for a symbol (rectangle with variations)
      def render_symbol_shape(xml, symbol)
        shape_class = "symbol-shape #{symbol_shape_class(symbol)}"

        # Schema symbols: single rect with class="boxschema", no shadow
        if symbol.is_a?(Symbol::SchemaSymbol)
          xml.rect(class: "boxschema",
                   x: "0",
                   y: "0",
                   width: symbol.width.to_s,
                   height: symbol.height.to_s,
                   rx: "5",
                   ry: "5")
          return
        end

        # Compositor symbols: single rounded rect with no shadow
        if symbol.compositor?
          xml.rect(class: shape_class,
                   x: "0",
                   y: "8",
                   width: symbol.width.to_s,
                   height: "31",
                   rx: "9")
          return
        end

        # Loop symbols: XSDVI-style boxloop with no shadow and arrow polygons
        if symbol.is_a?(Symbol::LoopSymbol)
          xml.rect(class: "boxloop",
                   x: "0",
                   y: "12",
                   width: symbol.width.to_s,
                   height: "21",
                   rx: "9")
          # Arrow polygons (XSDVI style)
          half_width = symbol.width / 2
          xml.polygon(class: "filled",
                     points: "#{half_width+3},8 #{half_width-2},12 #{half_width+3},17")
          xml.polygon(class: "filled",
                     points: "#{symbol.width-5},24 #{symbol.width},19 #{symbol.width+5},24")
          return
        end

        # Render shadow first (XSDVI style with 3px offset and rounded corners)
        xml.rect(class: "shadow",
                 x: "3",
                 y: "3",
                 width: symbol.width.to_s,
                 height: symbol.height.to_s,
                 rx: "5",
                 ry: "5")

        # Render main shape
        if symbol.is_a?(Symbol::AttributeSymbol)
          # Attribute shapes with styling based on required/optional
          if symbol.optional?
            # Optional attributes: dashed border
            xml.rect(class: "#{shape_class} attribute-optional",
                     x: "0",
                     y: "0",
                     width: symbol.width.to_s,
                     height: symbol.height.to_s,
                     style: "stroke-dasharray: 4,2;")
          else
            # Required attributes: solid border
            xml.rect(class: "#{shape_class} attribute-required",
                     x: "0",
                     y: "0",
                     width: symbol.width.to_s,
                     height: symbol.height.to_s)
          end
        elsif symbol.is_a?(Symbol::ElementSymbol) && symbol.optional?
          # Optional elements with dashed border (minOccurs=0)
          xml.rect(class: shape_class,
                   x: "0",
                   y: "0",
                   width: symbol.width.to_s,
                   height: symbol.height.to_s,
                   style: "stroke-dasharray: 4,2;")
        else
          # Regular rectangle for elements and types with rounded corners
          xml.rect(class: shape_class,
                   x: "0",
                   y: "0",
                   width: symbol.width.to_s,
                   height: symbol.height.to_s,
                   rx: "5",
                   ry: "5")
        end
      end

      # Renders text labels for a symbol matching XSDVI positioning
      def render_symbol_text(xml, symbol)
        if symbol.compositor?
          # Compositors have numbered labels for children
          render_compositor_text(xml, symbol)
        elsif symbol.is_a?(Symbol::SchemaSymbol)
          # Schema box shows "/ schema" with tspan for "/ " prefix
          xml.text_(class: "symbol-name",
                    x: "5",
                    y: "27") do
            xml.tspan('/ ')
            xml.text 'schema'
          end
        else
          # Elements show name and type info
          render_element_text(xml, symbol)
        end

        # Add description text below symbol (XSDVI style) - NOT for schema
        render_description_text(xml, symbol) unless symbol.is_a?(Symbol::SchemaSymbol)
      end

      # Renders text for compositor symbols (sequence, choice, all)
      def render_compositor_text(xml, symbol)
        # Calculate circle positions: width/2 + 12 for x coordinate
        circle_x = (symbol.width / 2.0) + 12
        text_x = symbol.width / 2.0

        # Render circles directly (XSDVI style)
        # Circle 1 at y=14
        xml.circle(cx: circle_x.to_s, cy: '14', r: '2', fill: '#000000')

        # Circle 2 at y=23
        xml.circle(cx: circle_x.to_s, cy: '23', r: '2', fill: '#000000')

        # Circle 3 at y=32
        xml.circle(cx: circle_x.to_s, cy: '32', r: '2', fill: '#000000')

        # Add vertical connecting line between circles
        xml.line(x1: circle_x.to_s,
                y1: '14',
                x2: circle_x.to_s,
                y2: '32',
                class: 'compositor-line',
                stroke: '#000000',
                'stroke-width' => '1')

        # Add numbered text labels: 1, 2, 3 at y=17, 26, 35
        xml.text_(class: "small",
                  x: text_x.to_s,
                  y: '17',
                  'text-anchor' => 'middle') do
          xml.text '1'
        end

        xml.text_(class: "small",
                  x: text_x.to_s,
                  y: '26',
                  'text-anchor' => 'middle') do
          xml.text '2'
        end

        xml.text_(class: "small",
                  x: text_x.to_s,
                  y: '35',
                  'text-anchor' => 'middle') do
          xml.text '3'
        end
      end

      # Renders text for element symbols
      def render_element_text(xml, symbol)
        # Handle LoopSymbol specially (XSDVI style - only LOOP text)
        if symbol.is_a?(Symbol::LoopSymbol)
          xml.text_('LOOP',
                x: "10",
                y: "27")
          return
        end

        # Namespace/targetNamespace at top of box (y=13, small font, visible class)
        target_ns = symbol.respond_to?(:target_namespace) ? symbol.target_namespace : nil
        if target_ns && !target_ns.empty?
          xml.text_(target_ns.to_s,
                     x: "5",
                     y: "13",
                     class: "visible",
                     "font-size" => "11")
        end

        # Handle TypeReferenceSymbol specially
        if symbol.is_a?(Symbol::TypeReferenceSymbol)
          # Display arrow and type name for type references
          xml.text_(class: "type-reference",
                    x: "5",
                    y: "27",
                    fill: "#0066CC") do
            xml.text "→ #{symbol.type_name.to_s.sub(/^xs:/, '').sub(/^xsd:/, '')}"
          end

          # Add "See first occurrence" hint
          xml.text_("(referenced)",
                  x: "5",
                  y: "41",
                  class: "visible",
                  "font-size" => "9",
                  "font-style" => "italic",
                  fill: "#666666")
          return
        end

        # Symbol name (y=27, strong, elementlink class for elements)
        # Handle special characters like @ for attributes with bigger font
        if symbol.name.start_with?('@')
          render_name_with_special_char(xml, symbol)
        else
          # Add elementlink class for navigable elements
          name_class = symbol.is_a?(Symbol::ElementSymbol) ? "strong elementlink" : "symbol-name"
          xml.text_(class: name_class,
                    x: "5",
                    y: "27") do
            xml.text truncate_text(symbol.name, symbol.width)
          end
        end

        # Type info if available (y=41, visible class) - strip xs: prefix
        if symbol.respond_to?(:type_info) && symbol.type_info
          # Strip xs: or xsd: prefix from type
          type_display = symbol.type_info.to_s.sub(/^xs:/, '').sub(/^xsd:/, '')
          type_text = "type: #{truncate_text(type_display, symbol.width)}"
          xml.text_(type_text,
                    x: "5",
                    y: "41",
                    class: "visible",
                    "font-size" => "11")
        elsif symbol.respond_to?(:type_ref) && symbol.type_ref
          # Strip xs: or xsd: prefix from type
          type_display = symbol.type_ref.to_s.sub(/^xs:/, '').sub(/^xsd:/, '')
          type_text = "type: #{truncate_text(type_display, symbol.width)}"
          xml.text_(type_text,
                    x: "5",
                    y: "41",
                    class: "visible",
                    "font-size" => "11")
        end

        # Empty text line at y=59 (required by XSDVI format)
        xml.text_('',
                  x: "5",
                  y: "59")

        # Cardinality (if needed, would go here but conflicts with empty line)
        # Skipping cardinality for now to match XSDVI exactly
      end

      # Renders description text below symbol (XSDVI style)
      def render_description_text(xml, symbol)
        doc = symbol.documentation
        return unless doc && !doc.empty?

        # Calculate wrap width: XSDVI uses (int)(width / 5.5) characters per line
        wrap_width = (symbol.width / 5.5).to_i
        wrap_width = [wrap_width, 10].max  # Minimum 10 characters

        # Wrap text at calculated width
        lines = TextWrapper.wrap(doc, wrap_width)

        # Render each line at y=73, 87, 101, etc. (14px spacing)
        lines.each_with_index do |line, index|
          y_pos = 73 + (index * 14)
          xml.text_(line,
                   x: 5,
                   y: y_pos,
                   class: 'desc',
                   'font-size' => 11,
                   fill: '#666666')
        end
      end

      # Returns CSS class for symbol based on its type
      def symbol_class(symbol)
        type_class = case symbol.type
                     when "element" then "xsd-element"
                     when "element_root" then "xsd-element"
                     when "complexType" then "xsd-complex-type"
                     when "simpleType" then "xsd-simple-type"
                     when "sequence" then "xsd-sequence"
                     when "choice" then "xsd-choice"
                     when "all" then "xsd-all"
                     when "group" then "xsd-group"
                     when "attribute" then "xsd-attribute"
                     when "attributeGroup" then "xsd-attribute-group"
                     when "restriction" then "xsd-restriction"
                     when "extension" then "xsd-extension"
                     when "union" then "xsd-union"
                     when "list" then "xsd-list"
                     when "any" then "xsd-any"
                     when "anyAttribute" then "xsd-any-attribute"
                     when "notation" then "xsd-notation"
                     when "key" then "xsd-key"
                     when "unique" then "xsd-unique"
                     when "keyref" then "xsd-keyref"
                     when "selector" then "xsd-selector"
                     when "field" then "xsd-field"
                     else "xsd-unknown"
                     end

        "xsd-symbol #{type_class}"
      end

      # Returns shape-specific CSS class
      def symbol_shape_class(symbol)
        "shape-#{symbol.type.gsub(/[A-Z]/) { |m| "-#{m.downcase}" }}"
      end

      # Checks if symbol is a complex or simple type
      def complex_or_simple_type?(symbol)
        %w[complexType simpleType].include?(symbol.type)
      end

      # Trucates text to fit within given width
      def truncate_text(text, width)
        # Convert to string if it's a Nokogiri Attr object
        text_str = text.respond_to?(:value) ? text.value : text.to_s

        # Rough approximation: 8 pixels per character
        max_chars = (width / 8.0).floor - 2
        return text_str if text_str.length <= max_chars

        "#{text_str[0...max_chars]}..."
      end

      # Formats cardinality for display (min..max)
      # Returns empty string for default (1..1)
      def format_cardinality(min_occurs, max_occurs)
        # Convert to strings/numbers for comparison
        min = min_occurs.to_i
        max = max_occurs == Float::INFINITY ? Float::INFINITY : max_occurs.to_i

        # Default is 1..1, don't show
        return "" if min == 1 && max == 1

        # Format max as * for unbounded
        max_str = max == Float::INFINITY ? "*" : max.to_s
        "#{min}..#{max_str}"
      end

      # Returns JavaScript code for interactive features
      def javascript_code
        # Calculate HEIGHT_SUM and HEIGHT_HALF based on XSDVI constants
        # MAX_HEIGHT = 46, Y_INDENT = 25
        height_sum = 71    # MAX_HEIGHT (46) + Y_INDENT (25)
        height_half = 23   # MAX_HEIGHT / 2

        <<~JS
  var efBoxes = [];
  var eSvg = null;

////////// loadSVG()
  function loadSVG() {
    efBoxes = getElementsByClassName('box', document.getElementsByTagName('g'));
    eSvg = document.getElementById('svg');
    expandAll();
  }

////////// getElementsByClassName(string, nodeList)
  function getElementsByClassName(sClass, nlNodes) {
    var elements = [];
    for (var i=0; i<nlNodes.length; i++) {
      if(nlNodes.item(i).nodeType==1 && sClass==nlNodes.item(i).getAttribute('class')) {
        elements.push(nlNodes.item(i));
      }
    }
    return elements;
  }

////////// show(string)
  function show(sId) {
    var useElement = document.getElementById('s'+sId);
    var moveNext = false;
    var eBoxLast;
    var maxX = 500;

    if (notPlus(useElement)) {
      eBoxLast = document.getElementById(sId);
      setPlus(useElement);
      for (var i=0; i<efBoxes.length; i++) {
        var eBox = efBoxes[i];
        if (moveNext) {
          move(eBoxLast, eBox);
        }
        else if (isDescendant(sId, eBox.id)) {
          eBox.setAttribute('visibility', 'hidden');
        }
        else if (isHigherBranch(sId, eBox.id)) {
          move(eBoxLast, eBox);
          moveNext = true;
        }
        if (eBox.getAttribute('visibility') != 'hidden') {
          eBoxLast = eBox;
          x = xTrans(eBox);
          if (x > maxX) maxX = x;
        }
      }
    }

    else {
      setMinus(useElement);
      var skipDescendantsOf;
      for (var i=0; i<efBoxes.length; i++) {
        var eBox = efBoxes[i];
        if (moveNext) {
          move(eBoxLast, eBox);
        }
        else if (isDescendant(sId, eBox.id) && (!skipDescendantsOf || !isDescendant(skipDescendantsOf.id, eBox.id))) {
          eBox.setAttribute('visibility', 'visible');
          move(eBoxLast, eBox);
          if (nextClosed(eBox)) skipDescendantsOf = eBox;
        }
        else if (isHigherBranch(sId, eBox.id)) {
          move(eBoxLast, eBox);
          moveNext = true;
        }
        if (eBox.getAttribute('visibility') != 'hidden') {
          eBoxLast = eBox;
          x = xTrans(eBox);
          if (x > maxX) maxX = x;
        }
      }
    }
    setHeight(yTrans(eBoxLast)+#{height_sum});
    setWidth(maxX+360);
  }

////////// collapseAll()
  function collapseAll() {
    for (var i=0; i<efBoxes.length; i++) {
      var eBox = efBoxes[i];
      var useElement = document.getElementById('s'+eBox.id);
      if (useElement) setPlus(useElement);
      if (eBox.id != '_1') eBox.setAttribute('visibility', 'hidden');
    }
    setHeight(400);
    setWidth(500);
  }

////////// expandAll()
  function expandAll() {
    var eBoxLast;
    var maxX = 0;
    for (var i=0; i<efBoxes.length; i++) {
      var eBox = efBoxes[i];
      var useElement = document.getElementById('s'+eBox.id);
      if (useElement) setMinus(useElement);
      move(eBoxLast, eBox);
      eBox.setAttribute('visibility', 'visible');
      eBoxLast = eBox;
      var x = xTrans(eBox);
      if (x > maxX) maxX = x;
    }
    setHeight(yTrans(eBoxLast)+#{height_sum});
    setWidth(maxX+360);
  }

////////// makeVisible(string)
  function makeVisible(sId) {
    var childNodes = document.getElementById(sId).childNodes;
    var hidden = getElementsByClassName('hidden', childNodes);
    var visible = getElementsByClassName('visible', childNodes);
    inheritVisibility(hidden);
    hiddenVisibility(visible);
  }

////////// makeHidden(string)
  function makeHidden(sId) {
    var childNodes = document.getElementById(sId).childNodes;
    var hidden = getElementsByClassName('hidden', childNodes);
    var visible = getElementsByClassName('visible', childNodes);
    inheritVisibility(visible);
    hiddenVisibility(hidden);
  }

////////// inheritVisibility(element[])
  function inheritVisibility(efElements) {
    for (var i=0; i<efElements.length; i++) {
      efElements[i].setAttribute('visibility', 'inherit');
    }
  }

////////// hiddenVisibility(element[])
  function hiddenVisibility(efElements) {
    for (var i=0; i<efElements.length; i++) {
      efElements[i].setAttribute('visibility', 'hidden');
    }
  }

////////// nextClosed(element)
  function nextClosed(eBox) {
    var useElement = document.getElementById('s'+eBox.id);
    return (useElement && !notPlus(useElement));
  }

////////// isHigherBranch(string, string)
  function isHigherBranch(sSerialLower, sSerialHigher) {
    var sLower = sSerialLower.split('_');
    var sHigher = sSerialHigher.split('_');
    for (var i=0; i<sLower.length; i++) {
      if (Number(sHigher[i]) > Number(sLower[i])) return true;
      else if (Number(sHigher[i]) < Number(sLower[i])) return false;
    }
    return false;
  }

////////// isOnHigherLevel(element, element)
  function isOnHigherLevel(eBoxLower, eBoxHigher) {
    var sLower = eBoxLower.id.split('_');
    var sHigher = eBoxHigher.id.split('_');
    for (var i=0; i<sLower.length; i++) {
      if (Number(sHigher[i]) > Number(sLower[i])) return true;
    }
    return false;
  }

////////// isDescendant(string, string)
  function isDescendant(sSerialAsc, sSerialDesc) {
    return (sSerialDesc.length > sSerialAsc.length && sSerialDesc.indexOf(sSerialAsc) === 0);
  }

////////// getParent(element)
  function getParent(eBox) {
    var serial = eBox.id.substring(0, eBox.id.lastIndexOf('_'));
    return document.getElementById(serial);
  }

////////// move(element, element)
  function move(eBoxLast, eBox) {
    if (!eBoxLast) return;
    if (isOnHigherLevel(eBoxLast, eBox)) {
      var attDescHeight = eBoxLast.getAttribute('data-desc-height-rest');
      var attDescX = Number(eBoxLast.getAttribute('data-desc-x'));
      var attX = xTrans(eBox);
      var descHeight = Number(attDescHeight);
      var heightAddon = 0;

      var currWidth = eBox.getElementsByClassName("shadow")[0];
      if (currWidth) {
        currWidth = Number(currWidth.getAttribute("width"));
      } else {
        currWidth = 0;
      }
      if(descHeight && ((attDescX >= attX && attDescX < attX + currWidth) || (attX < attDescX))) heightAddon = descHeight;

      setYTrans(eBox, yTrans(eBoxLast)+#{height_sum}+heightAddon);
      var parent = getParent(eBox);
      var line = document.getElementById('p'+eBox.id);
      if (!parent || !line) return;
      line.setAttribute('y1', String(yTrans(parent)-yTrans(eBox)+#{height_half}));
    }
    else {
      setYTrans(eBox, yTrans(eBoxLast));
    }
  }

////////// notPlus(element)
  function notPlus(eUseElement) {
    return (eUseElement.getAttributeNS('http://www.w3.org/1999/xlink', 'href') != '#plus');
  }

////////// setPlus(element)
  function setPlus(eUseElement) {
    eUseElement.setAttributeNS('http://www.w3.org/1999/xlink', 'href', '#plus');
  }

////////// setMinus(element)
  function setMinus(eUseElement) {
    eUseElement.setAttributeNS('http://www.w3.org/1999/xlink', 'href', '#minus');
  }

////////// setHeight(number)
  function setHeight(nHeight) {
    eSvg.setAttribute('height', nHeight);
  }

////////// setWidth(number)
  function setWidth(nWidth) {
    eSvg.setAttribute('width', nWidth);
  }

////////// xyTrans(element)
  function xTrans(eBox) {
    var transform = eBox.getAttribute('transform');
    var x = Number(transform.substring(10, Number(transform.length)-1).split(',')[0]);
    if(!x) x = 0;
    return x;
  }

////////// yTrans(element)
  function yTrans(eBox) {
    var transform = eBox.getAttribute('transform');
    var y = Number(transform.substring(10, Number(transform.length)-1).split(',')[1]);
    if(!y) y = 0;
    return y;
  }

########// setYTrans(element, number)
  function setYTrans(eBox, nValue) {
    eBox.setAttribute('transform', 'translate('+xTrans(eBox)+','+nValue+')');
  }
        JS
      end

      # Returns embedded CSS styles for SVG matching XSDVI color scheme
      def css_styles
        <<~CSS
          .xsd-symbol {
            cursor: pointer;
            pointer-events: all;
          }

          .xsd-symbol.symbol-hover .symbol-shape {
            stroke-width: 3;
            filter: drop-shadow(0 0 5px rgba(0,0,0,0.3));
          }

          .symbol-shape {
            stroke-width: 1;
            transition: stroke-width 0.2s, filter 0.2s;
          }

          .type-link {
            cursor: pointer;
            text-decoration: underline;
          }

          .type-link:hover {
            fill: #0000CC;
          }

          .collapse-button {
            cursor: pointer;
          }

          .collapse-button:hover circle {
            fill: #F0F0F0;
          }

          .child-group {
            display: block;
          }

          .menu-button {
            cursor: pointer;
          }

          .menu-button:hover .menu-dot {
            fill: #333333;
          }

          .special-char {
            font-weight: bold;
          }

          /* Type reference styles */
          .type-reference {
            fill: #0066CC;
            font-family: Arial, sans-serif;
            font-size: 12px;
            font-weight: bold;
            cursor: pointer;
            text-decoration: underline;
          }

          .type-reference:hover {
            fill: #0000CC;
          }

          /* Shadow for depth effect */
          .shadow {
            fill: #ccccd8;
            stroke: none;
          }

          /* Connection circle styles */
          .connection-input {
            fill: #4CAF50;
            stroke: #388E3C;
            stroke-width: 1;
          }

          .connection-output {
            fill: #2196F3;
            stroke: #1976D2;
            stroke-width: 1;
          }

          /* Compositor internal line */
          .compositor-line {
            stroke: #000;
            stroke-width: 1;
            fill: none;
          }

          /* Element styles - XSDVI light yellow */
          .xsd-element .symbol-shape {
            fill: #FFFFBB;
            stroke: #776633;
          }

          /* Complex Type styles - XSDVI light yellow */
          .xsd-complex-type .symbol-shape {
            fill: #FFFFBB;
            stroke: #776633;
          }

          /* Simple Type styles - XSDVI light yellow */
          .xsd-simple-type .symbol-shape {
            fill: #FFFFBB;
            stroke: #776633;
          }

          /* Compositor styles (sequence, choice, all) - XSDVI light blue */
          .xsd-sequence .symbol-shape,
          .xsd-choice .symbol-shape,
          .xsd-all .symbol-shape {
            fill: #E7EBF3;
            stroke: #666677;
          }

          /* Group styles */
          .xsd-group .symbol-shape {
            fill: #E7EBF3;
            stroke: #666677;
          }

          /* Attribute styles - XSDVI light yellow */
          .xsd-attribute .symbol-shape {
            fill: #FFFFBB;
            stroke: #776633;
          }

          /* Attribute Group styles */
          .xsd-attribute-group .symbol-shape {
            fill: #FFFFBB;
            stroke: #776633;
          }

          /* Restriction styles */
          .xsd-restriction .symbol-shape {
            fill: #FFFFBB;
            stroke: #776633;
          }

          /* Extension styles */
          .xsd-extension .symbol-shape {
            fill: #FFFFBB;
            stroke: #776633;
          }

          /* Union styles */
          .xsd-union .symbol-shape {
            fill: #FFFFBB;
            stroke: #776633;
          }

          /* List styles */
          .xsd-list .symbol-shape {
            fill: #FFFFBB;
            stroke: #776633;
          }

          /* Any/styles */
          .xsd-any .symbol-shape {
            fill: #FFFFBB;
            stroke: #776633;
          }

          /* AnyAttribute styles */
          .xsd-any-attribute .symbol-shape {
            fill: #FFFFBB;
            stroke: #776633;
          }

          /* Identity constraint styles */
          .xsd-key .symbol-shape,
          .xsd-unique .symbol-shape,
          .xsd-keyref .symbol-shape {
            fill: #E7EBF3;
            stroke: #666677;
          }

          /* Selector and Field styles */
          .xsd-selector .symbol-shape,
          .xsd-field .symbol-shape {
            fill: #E7EBF3;
            stroke: #666677;
          }

          /* Attribute styling based on required/optional */
          .attribute-required {
            stroke-width: 2;
            stroke-dasharray: none;
          }

          .attribute-optional {
            stroke-width: 1;
            stroke-dasharray: 4,2;
          }

          /* Text styles matching XSDVI */
          .symbol-name {
            fill: #000;
            font-family: Arial, sans-serif;
            font-size: 12px;
            font-weight: bold;
            pointer-events: none;
          }

          .symbol-type {
            fill: #000;
            font-family: Arial, sans-serif;
            font-size: 11px;
            pointer-events: none;
          }

          .small {
            font-size: 10px;
          }

          /* Connector styles - XSDVI gray */
          .connector {
            stroke: #666666;
            stroke-width: 1;
            fill: none;
          }

          /* XSDVI Button styles */
          .button rect {
            fill: #FFFFFF;
            stroke: #000000;
            stroke-width: 1;
            cursor: pointer;
          }

          .button line {
            stroke: #000000;
            stroke-width: 1;
          }

          .button {
            cursor: pointer;
            pointer-events: all;
          }

          /* Connector line styles - changed from .connection to .connector */
          .connector {
            stroke: #666666;
            stroke-width: 1;
            fill: none;
          }

          /* Box class for XSDVI compatibility */
          .box {
            cursor: pointer;
          }
        CSS
      end
    end
  end
end
