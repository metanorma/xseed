# frozen_string_literal: true

require "nokogiri"
require_relative "config"
require_relative "constants"
require_relative "utils/references"
require_relative "utils/namespaces"
require_relative "utils/helpers"
require_relative "generators/properties_table_generator"
require_relative "generators/hierarchy_table_generator"
require_relative "generators/instance_sample_generator"
require_relative "presentation/css_generator"
require_relative "presentation/javascript_generator"
require_relative "presentation/navigation_builder"
require_relative "../parser/xsd_parser"

module Xseed
  module Documentation
    # Main HTML documentation generator
    # Integrates all content generators for complete schema documentation
    class HtmlGenerator
      include Utils::References
      include Utils::Namespaces
      include Utils::Helpers
      include Constants

      attr_reader :xsd_file, :config, :parser

      # Initialize the HTML generator
      #
      # @param xsd_file [String] Path to XSD schema file
      # @param config [Config] Configuration options (optional)
      def initialize(xsd_file, config = Config.new)
        @xsd_file = xsd_file
        @config = config
        @parser = Parser::XsdParser.new(xsd_file)
      end

      # Generate HTML documentation
      #
      # @return [String] Generated HTML content
      def generate
        builder = Nokogiri::HTML::Builder.new do |html|
          html.html do
            generate_head(html)
            html.body do
              generate_body(html)
              generate_navigation(html)
            end
          end
        end

        # Replace HTML4 DOCTYPE with HTML5 DOCTYPE
        html_output = builder.to_html.sub(
          /<!DOCTYPE[^>]+>/,
          "<!DOCTYPE html>"
        )

        # Convert HTML void hr tags to XML-style (xs3p compliance)
        html_output.gsub!(/<hr>/, '<hr></hr>')
      end

      # Generate HTML documentation and write to file
      #
      # @param output_path [String] Path to output HTML file
      def generate_file(output_path)
        # Auto-generate SVG diagrams if enabled
        generate_svg_diagrams(output_path) if @config.print_diagrams

        html_content = generate
        File.write(output_path, html_content)
      end

      private

      # Compactify HTML to match xs3p compact format
      # Removes whitespace between tags while preserving text content
      #
      # @param html [String] HTML content
      # @return [String] Compactified HTML
      def compactify_html(html)
        # Remove only newlines and indentation whitespace between tags
        # This matches xs3p's compact inline format
        html.gsub(/>\n\s*</, '><')
      end

      # Generate modal popup divs for element/attribute documentation (xs3p pattern)
      #
      # @param html [Nokogiri::HTML::Builder] HTML builder
      def generate_modal_popups(html)
        modal_counter = 0

        # Helper to generate a single modal
        generate_modal = lambda do |component_name, component_type, doc_text|
          next unless doc_text && !doc_text.strip.empty?

          modal_counter += 1
          modal_id = "id#{modal_counter}"

          html.div(class: "modal fade #{component_name}",
                   id: "#{modal_id}-popup",
                   tabindex: "-1",
                   role: "dialog",
                   "aria-hidden": "true") do
            html.div(class: "modal-header") do
              html.button(type: "button",
                         class: "close",
                         "data-dismiss": "modal",
                         "aria-hidden": "true") { html.text "×" }
              html.h4(class: "modal-title", id: "#{modal_id}-label") do
                html.text "#{component_type} #{component_name}"
              end
            end
            html.div(class: "modal-body") do
              html.div(class: "annotation documentation",
                      id: "wdoc-#{modal_id}-hidden") do
                html.div(class: "hidden", id: "#{modal_id}-hidden-doc-raw") do
                  html.text doc_text.strip
                end
                html.div(class: "xs3p-doc", id: "#{modal_id}-hidden-doc") do
                  html.text " "
                end
              end
            end
          end
        end

        # Generate modals for all elements
        parser.elements.each do |element|
          element_name = element["name"]
          next unless element_name

          doc = extract_documentation(element)
          generate_modal.call(element_name, "Element", doc)

          # Check for nested elements in inline complexType
          complex_type = element.at_xpath("xs:complexType", "xs" => "http://www.w3.org/2001/XMLSchema")
          if complex_type
            # Get sequence/choice/all children
            %w[sequence choice all].each do |group_type|
              group = complex_type.at_xpath("xs:#{group_type}", "xs" => "http://www.w3.org/2001/XMLSchema")
              next unless group

              group.xpath(".//xs:element", "xs" => "http://www.w3.org/2001/XMLSchema").each do |nested_elem|
                nested_name = nested_elem["name"]
                next unless nested_name

                nested_doc = extract_documentation(nested_elem)
                generate_modal.call(nested_name, "Element", nested_doc)
              end

              # Check for attributes
              group.xpath(".//xs:attribute", "xs" => "http://www.w3.org/2001/XMLSchema").each do |attr|
                attr_name = attr["name"]
                next unless attr_name

                attr_doc = extract_documentation(attr)
                generate_modal.call(attr_name, "Attribute", attr_doc)
              end
            end

            # Direct attributes on complexType
            complex_type.xpath("xs:attribute", "xs" => "http://www.w3.org/2001/XMLSchema").each do |attr|
              attr_name = attr["name"]
              next unless attr_name

              attr_doc = extract_documentation(attr)
              generate_modal.call(attr_name, "Attribute", attr_doc)
            end
          end
        end

        # Generate modals for complex types
        parser.complex_types.each do |type|
          type_name = type["name"]
          next unless type_name

          # Check for nested elements
          %w[sequence choice all].each do |group_type|
            group = type.at_xpath(".//xs:#{group_type}", "xs" => "http://www.w3.org/2001/XMLSchema")
            next unless group

            group.xpath(".//xs:element", "xs" => "http://www.w3.org/2001/XMLSchema").each do |nested_elem|
              nested_name = nested_elem["name"]
              next unless nested_name

              nested_doc = extract_documentation(nested_elem)
              generate_modal.call(nested_name, "Element", nested_doc)
            end
          end

          # Attributes
          type.xpath(".//xs:attribute", "xs" => "http://www.w3.org/2001/XMLSchema").each do |attr|
            attr_name = attr["name"]
            next unless attr_name

            attr_doc = extract_documentation(attr)
            generate_modal.call(attr_name, "Attribute", attr_doc)
          end
        end
      end

      # Extract documentation from XSD node
      def extract_documentation(node)
        doc_node = node.at_xpath("xs:annotation/xs:documentation", "xs" => "http://www.w3.org/2001/XMLSchema")
        doc_node&.text
      end

      # Auto-generate SVG diagrams for all elements using xsdvi
      #
      # @param html_output_path [String] Path to HTML output file
      def generate_svg_diagrams(html_output_path)
        require "xsdvi"
        require "fileutils"

        # Determine diagrams directory relative to HTML output
        output_dir = File.dirname(html_output_path)
        diagrams_path = File.join(output_dir, @config.diagrams_dir)
        FileUtils.mkdir_p(diagrams_path)

        # Generate SVG for each element
        parser.elements.each do |element|
          element_name = element["name"]
          next unless element_name

          svg_file = File.join(diagrams_path, "#{element_name}.svg")

          # Use xsdvi Ruby API
          writer = Xsdvi::Utils::Writer.new(svg_file)
          builder = Xsdvi::Tree::Builder.new
          handler = Xsdvi::XsdHandler.new(builder)
          handler.root_node_name = element_name
          handler.one_node_only = true
          handler.process_file(@xsd_file)

          root = builder.root
          generator = Xsdvi::SVG::Generator.new(writer)
          generator.hide_menu_buttons = true
          generator.draw(root)
        end
      rescue LoadError
        # xsdvi not available, skip SVG generation
        warn "Warning: xsdvi gem not available, skipping SVG generation"
      end

      # Generate HTML head section
      #
      # @param html [Nokogiri::HTML::Builder] HTML builder
      def generate_head(html)
        html.head do
          html.meta(charset: "UTF-8")
          html.meta(name: "viewport",
                    content: "width=device-width, initial-scale=1.0")
          html.title(title)
          generate_styles(html)
          generate_scripts(html)
        end
      end

      # Generate styles (inline or external)
      #
      # @param html [Nokogiri::HTML::Builder] HTML builder
      def generate_styles(html)
        # Load Bootstrap CSS first (needed for modal styling)
        bootstrap_url = @config.bootstrap_url || "https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.4.1"
        html.link(rel: "stylesheet", href: "#{bootstrap_url}/css/bootstrap.min.css")

        css_gen = Presentation::CssGenerator.new(@config)

        if css_gen.external_css_url
          html.link(rel: "stylesheet", href: css_gen.external_css_url)
        else
          html.style do
            html.text(css_gen.generate)
          end
        end
      end

      # Generate scripts (inline or external)
      #
      # @param html [Nokogiri::HTML::Builder] HTML builder
      def generate_scripts(html)
        js_gen = Presentation::JavascriptGenerator.new(@config)

        # jQuery
        html.script(src: js_gen.jquery_url, defer: true) {}

        # Bootstrap JS (if enabled)
        if js_gen.bootstrap_url
          html.script(src: "#{js_gen.bootstrap_url}/js/bootstrap.min.js",
                      defer: true) {}
        end

        # Custom JavaScript
        html.script(defer: true) do
          html.text(js_gen.generate)
        end
      end

      # Generate navigation sidebar
      #
      # @param html [Nokogiri::HTML::Builder] HTML builder
      def generate_navigation(html)
        nav_builder = Presentation::NavigationBuilder.new(@parser, @config)
        html << nav_builder.generate
      end


      # Generate HTML body content
      #
      # @param html [Nokogiri::HTML::Builder] HTML builder
      def generate_body(html)
        # Generate modal popups FIRST (xs3p pattern)
        generate_modal_popups(html)

        # Toggle button as direct child of body
        html.div(id: "toggle") do
          html.span "<"
        end

        html.main do
          html.div(class: "title-section") do
            html.h1 do
              html.a(id: "top") {}
              html.text title
            end
          end

          # Schema-level information
          generate_schema_info(html)

          # Generate documentation with 4 major sections
          generate_component_sections(html)

          # Glossary section (if enabled)
          generate_glossary(html) if @config.print_glossary
        end
      end

      # Generate components in 4 major sections (XS3P/XSDVI compliance)
      #
      # @param html [Nokogiri::HTML::Builder] HTML builder
      def generate_component_sections(html)
        # Section 2: Global Elements
        if parser.elements.any?
          html.section(id: "SectionSchemaElements", class: "schema-section") do
            html.h2 do
              html.a(id: "SchemaElements") {}
              html.text "Elements"
            end
            parser.elements.each do |element|
              generate_component_content(html, element, "Element")
            end
          end
        end

        # Section 3: Complex Types
        complex_types = parser.complex_types
        if complex_types.any?
          html.section(id: "SectionSchemaComplexTypes", class: "schema-section") do
            html.h2 do
              html.a(id: "SchemaComplexTypes") {}
              html.text "Complex Types"
            end
            complex_types.each do |type|
              generate_component_content(html, type, "Complex Type")
            end
          end
        end

        # Section 3b: Simple Types
        simple_types = parser.simple_types
        if simple_types.any?
          html.section(id: "SectionSchemaSimpleTypes", class: "schema-section") do
            html.h2 do
              html.a(id: "SchemaSimpleTypes") {}
              html.text "Types"
            end
            simple_types.each do |type|
              generate_component_content(html, type, "Simple Type")
            end
          end
        end

        # Section 4: Attribute Groups
        attr_groups = parser.attribute_groups
        if attr_groups.any?
          html.section(id: "SectionSchemaAttributeGroups", class: "schema-section") do
            html.h2 do
              html.a(id: "SchemaAttributeGroups") {}
              html.text "Attribute Groups"
            end
            attr_groups.each do |component|
              generate_component_content(html, component, "Attribute Group")
            end
          end
        end
      end

      # Get component type label
      #
      # @param node_name [String] XML node name
      # @return [String] Human-readable component type
      def get_component_type_label(node_name)
        case node_name
        when "element"
          "Element"
        when "complexType"
          "Complex Type"
        when "simpleType"
          "Simple Type"
        when "group"
          "Model Group"
        when "attributeGroup"
          "Attribute Group"
        when "attribute"
          "Attribute"
        when "notation"
          "Notation"
        else
          node_name
        end
      end

      # Generate glossary section
      #
      # @param html [Nokogiri::HTML::Builder] HTML builder
      def generate_glossary(html)
        html.section(id: "Glossary") do
          html.h2 "Glossary"
          html.p "XSD schema terms and definitions."
          # TODO: Implement glossary generation
        end
      end

      # Generate schema information section
      #
      # @param html [Nokogiri::HTML::Builder] HTML builder
      def generate_schema_info(html)
        schema = parser.schema
        return unless schema

        html.section(id: "SectionSchemaProperties", class: "schema-info") do
          html.h2 do
            html.a(id: "SchemaProperties") {}
            html.text "Schema Document Properties"
          end

          html.dl(class: "dl-horizontal") do
            # Target Namespace
            html.dt(class: "header") do
              html.a(title: "Look up 'Target Namespace' in glossary",
                     href: "#term_TargetNS") do
                html.text "Target Namespace"
              end
            end
            html.dd(class: "") do
              if (target_ns = schema["targetNamespace"])
                html.span(class: "targetNS") do
                  html.text target_ns
                end
              else
                html.text "None"
              end
            end

            # Element and Attribute Namespaces
            html.dt(class: "header") { html.text "Element and Attribute Namespaces" }
            html.dd(class: "") do
              html.ul do
                html.li do
                  html.text "Global element and attribute declarations belong to this schema's target namespace."
                end

                # Check elementFormDefault
                element_form = schema["elementFormDefault"]
                if element_form == "qualified"
                  html.li do
                    html.text "By default, local element declarations belong to this schema's target namespace."
                  end
                else
                  html.li do
                    html.text "By default, local element declarations have no namespace."
                  end
                end

                html.li do
                  html.text "By default, local attribute declarations have no namespace."
                end
              end
            end
          end

          # Declared Namespaces
          generate_declared_namespaces(html, schema)

          # Schema Component Representation
          generate_schema_component_callout(html, schema)

          html.div(style: "text-align: right; clear: both;") do
            html.a(href: "#top", title: "Go to top of page") do
              html.span(class: "glyphicon glyphicon-chevron-up") { html.text " " }
            end
          end
          html.hr
        end
      end

      # Generate declared namespaces section
      #
      # @param html [Nokogiri::HTML::Builder] HTML builder
      # @param schema [Nokogiri::XML::Element] Schema element
      def generate_declared_namespaces(html, schema)
        html.h4 "Declared Namespaces:"
        html.dl(class: "dl-horizontal") do
          html.dt(class: "header") { html.text "Prefix" }
          html.dd(class: "header") { html.text "Namespace" }

          # Extract namespace declarations
          schema.namespace_definitions.each do |ns|
            prefix = ns.prefix || "(default)"
            html.dt(class: "") do
              html.a(id: "ns_#{ns.prefix}") {} if ns.prefix
              html.text prefix
            end
            html.dd(class: "") { html.text ns.href }
          end
        end
      end

      # Generate component content as direct children (not wrapped in div) per xs3p
      #
      # @param html [Nokogiri::HTML::Builder] HTML builder
      # @param component [Nokogiri::XML::Element] Schema component
      # @param component_type [String] Component type label
      def generate_component_content(html, component, component_type)
        component_name = component["name"] || component["ref"]
        return unless component_name

        component_id = generate_component_id(component_type, component_name)

        # XS3P does NOT wrap components in divs - content flows directly
        html.h3(class: "xs3p-subsection-heading") do
          html.text "#{component_type}: "
          html.a(id: component_id) {}
          html.strong component_name
        end

        # SVG diagram reference (if exists)
        generate_svg_reference(html, component_name)

        # Properties definition lists (no heading) - generates 1-3 DLs per component
        props_gen = Generators::PropertiesTableGenerator.new(component,
                                                            @config)
        props_gen.generate.each { |dl_html| html << dl_html }

        # Hierarchy table (if applicable)
        hier_gen = Generators::HierarchyTableGenerator.new(
          component,
          @parser,
          @config
        )
        hierarchy_html = hier_gen.generate
        html << hierarchy_html if hierarchy_html

        # Instance sample in callout block (skip for simple types and notations)
        unless %w[simpleType notation].include?(component.name)
          generate_instance_representation_callout(html, component)
        end

        # Schema component representation in callout block
        generate_schema_component_callout(html, component)

        # Back to top link and separator
        html.div(style: "text-align: right; clear: both;") do
          html.a(href: "#top", title: "Go to top of page") do
            html.span(class: "glyphicon glyphicon-chevron-up") { html.text " " }
          end
        end
        html.hr
      end

      # Generate SVG diagram reference
      #
      # @param html [Nokogiri::HTML::Builder] HTML builder
      # @param component_name [String] Component name
      def generate_svg_reference(html, component_name)
        return unless @config.print_diagrams

        html.object(data: "diagrams/#{component_name}.svg",
                    type: "image/svg+xml") {}
      end

      # Generate instance representation callout block
      #
      # @param html [Nokogiri::HTML::Builder] HTML builder
      # @param component [Nokogiri::XML::Element] Schema component
      def generate_instance_representation_callout(html, component)
        html.div(class: "bs-callout bs-callout-info") do
          html.h4 do
            html.text "XML Instance Representation"
            html.text " "
            generate_help_popover(html, "instance")
          end
          sample_gen = Generators::InstanceSampleGenerator.new(
            component,
            @parser,
            @config
          )
          html << sample_gen.generate
        end
      end

      # Generate schema component representation callout block
      #
      # @param html [Nokogiri::HTML::Builder] HTML builder
      # @param component [Nokogiri::XML::Element] Schema component
      def generate_schema_component_callout(html, component)
        html.div(class: "bs-callout bs-callout-info") do
          html.h4 do
            html.text "Schema Component Representation"
            html.text " "
            generate_help_popover(html, "schema")
          end
          html.pre(class: "codehilite") do
            html << format_xsd_component(component)
          end
        end
      end

      # Generate help popover button
      #
      # @param html [Nokogiri::HTML::Builder] HTML builder
      # @param type [String] Type of help ("instance" or "schema")
      def generate_help_popover(html, type)
        content = if type == "instance"
                    instance_help_content
                  else
                    schema_help_content
                  end

        html.span(class: "xs3p-panel-help") do
          html.button(type: "button",
                      class: "btn btn-doc",
                      "data-container": "body",
                      "data-toggle": "popover",
                      "data-placement": type == "instance" ? "right" : "left",
                      "data-html": "true",
                      "data-content": content) do
            html.span(class: "glyphicon glyphicon-question-sign") { html.text " " }
          end
        end
      end

      # Format XSD component for display
      #
      # @param component [Nokogiri::XML::Element] Schema component
      # @return [String] Formatted XSD
      def format_xsd_component(component)
        # Special handling for schema element - collapse children
        if component.name == "schema"
          return format_collapsed_schema(component)
        end

        # Clone component to avoid modifying original
        comp_copy = component.dup

        # Remove annotation children (xs3p compliance)
        comp_copy.xpath(".//xsd:annotation", "xsd" => "http://www.w3.org/2001/XMLSchema").each(&:remove)

        # Get the component's XML representation
        xml = comp_copy.to_xml(indent: 3, indent_text: "   ")

        # Add syntax highlighting classes
        xml.gsub!(/<(\/?)([\w:]+)([^>]*)>/) do
          tag_open = Regexp.last_match(1)
          tag_name = Regexp.last_match(2)
          attributes = Regexp.last_match(3)

          # Highlight tag names
          highlighted = "<span class=\"nt\">&lt;#{tag_open}"
          if tag_name.include?(":")
            prefix = tag_name.split(':').first
            local_name = tag_name.split(':').last
            highlighted += "<a href=\"#ns_#{prefix}\" title=\"Find out namespace of '#{prefix}' prefix\">#{prefix}</a>:#{local_name}"
          else
            highlighted += tag_name
          end

          highlighted += "</span>"

          # Highlight attributes
          if attributes && !attributes.empty?
            attributes.gsub!(/(\w+)="([^"]*)"/) do
              attr_name = Regexp.last_match(1)
              attr_value = Regexp.last_match(2)

              # Check if attribute value is a type reference
              if attr_name == "type" && !attr_value.include?(":")
                # Local type reference - add link
                attr_value_html = "<span class=\"type\"><a title='Jump to \"#{attr_value}\" type definition.' href=\"#type_#{attr_value}\">#{attr_value}</a></span>"
                " <span class=\"na\">#{attr_name}=</span><span class=\"s\">\"#{attr_value_html}\"</span>"
              elsif attr_name.include?(":") || ["ref", "base"].include?(attr_name)
                # Potential reference - add link if local
                local_name = attr_value.include?(":") ? attr_value.split(":").last : attr_value
                if attr_name == "ref" || attr_name == "base"
                  attr_value_html = "<a title='Jump to \"#{local_name}\" #{attr_name == 'base' ? 'type' : 'element'} definition.' href=\"##{attr_name == 'base' ? 'type' : 'element'}_#{local_name}\">#{attr_value}</a>"
                  " <span class=\"na\">#{attr_name}=</span><span class=\"s\">\"#{attr_value_html}\"</span>"
                else
                  " <span class=\"na\">#{attr_name}=</span><span class=\"s\">\"#{attr_value}\"</span>"
                end
              else
                " <span class=\"na\">#{attr_name}=</span><span class=\"s\">\"#{attr_value}\"</span>"
              end
            end
            highlighted += attributes
          end

          highlighted += "<span class=\"nt\">&gt;</span>"
          highlighted
        end

        xml
      end

      # Format collapsed schema component (xs3p compliance)
      #
      # @param schema [Nokogiri::XML::Element] Schema element
      # @return [String] Formatted collapsed XSD
      def format_collapsed_schema(schema)
        result = []

        # Opening tag with attributes
        tag_parts = ["<span class=\"nt\">&lt;"]
        tag_parts << "<a href=\"#ns_xsd\" title=\"Find out namespace of 'xsd' prefix\">xsd</a>:schema</span>"

        # Add schema attributes
        schema.attributes.each do |name, attr|
          tag_parts << " <span class=\"na\">#{name}=</span><span class=\"s\">\"#{attr.value}\"</span>"
        end
        tag_parts << "<span class=\"nt\">&gt;</span>"

        result << tag_parts.join("")

        # Show first import/include child if exists
        first_child = schema.children.find { |c| c.element? && %w[import include].include?(c.name) }
        if first_child
          # Format just the first import/include line
          child_line = "   <span class=\"nt\">&lt;"
          child_line += "<a href=\"#ns_xsd\" title=\"Find out namespace of 'xsd' prefix\">xsd</a>:#{first_child.name}</span>"

          first_child.attributes.each do |name, attr|
            child_line += " <span class=\"na\">#{name}=</span><span class=\"s\">\"#{attr.value}\"</span>"
          end
          child_line += "<span class=\"nt\">/&gt;</span>"

          result << child_line
        end

        # Collapsed content placeholder
        result << "<span class=\"scContent\">...</span>"

        # Closing tag
        result << "<span class=\"nt\">&lt;/<a href=\"#ns_xsd\" title=\"Find out namespace of 'xsd' prefix\">xsd</a>:schema&gt;</span>"

        result.join("\n")
      end

      # Help content for instance representation
      #
      # @return [String] HTML help content
      def instance_help_content
        "The XML Instance Representation table shows the schema component's content as an XML instance. " \
        "&lt;ul&gt;" \
        "&lt;li&gt;The minimum and maximum occurrence of elements and attributes are provided in square brackets, e.g. [0..1].&lt;/li&gt;" \
        "&lt;li&gt;Model group information are shown in gray, e.g. Start Choice ... End Choice.&lt;/li&gt;" \
        "&lt;li&gt;For type derivations, the elements and attributes that have been added to or changed from the base type's content are shown in &lt;strong&gt;bold&lt;/strong&gt;&lt;/li&gt;" \
        "&lt;li&gt;If an element/attribute has a fixed value, the fixed value is shown in green.&lt;/li&gt;" \
        "&lt;/ul&gt;"
      end

      # Help content for schema component
      #
      # @return [String] HTML help content
      def schema_help_content
        "The Schema Component Representation table below displays the underlying XML representation of the schema component. (Annotations are not shown.)"
      end

      # Generate component ID for anchor links
      #
      # @param component_type [String] Component type
      # @param component_name [String] Component name
      # @return [String] Component ID
      def generate_component_id(component_type, component_name)
        case component_type
        when "Element"
          "element-#{component_name}"
        when "Complex Type"
          "type-#{component_name}"
        when "Simple Type"
          "type-#{component_name}"
        when "Model Group"
          "group-#{component_name}"
        when "Attribute Group"
          "attributeGroup-#{component_name}"
        else
          "#{component_type.downcase.tr(' ', '-')}-#{component_name}"
        end
      end

      # Get the title for the documentation
      #
      # @return [String] Documentation title
      def title
        @config.title || "XSD Schema Documentation"
      end
    end
  end
end
