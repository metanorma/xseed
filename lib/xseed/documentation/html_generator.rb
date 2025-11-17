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
          html.html(lang: "en") do
            generate_head(html)
            html.body do
              generate_body(html)
              generate_navigation(html)
            end
          end
        end
        # Replace HTML4 DOCTYPE with HTML5 DOCTYPE
        builder.to_html.sub(
          /<!DOCTYPE[^>]+>/,
          "<!DOCTYPE html>"
        )
      end

      # Generate HTML documentation and write to file
      #
      # @param output_path [String] Path to output HTML file
      def generate_file(output_path)
        html_content = generate
        File.write(output_path, html_content)
      end

      private

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
          html.section(id: "global-elements", class: "schema-section") do
            html.h2 do
              html.a(id: "SchemaElements") {}
              html.text "Global Elements"
            end
            parser.elements.each do |element|
              generate_component_content(html, element, "Element")
            end
          end
        end

        # Section 3: Global Types (Complex and Simple)
        types = parser.complex_types + parser.simple_types
        if types.any?
          html.section(id: "global-types", class: "schema-section") do
            html.h2 "Global Types"
            types.each do |type|
              type_label = type.name == "complexType" ? "Complex Type" : "Simple Type"
              generate_component_content(html, type, type_label)
            end
          end
        end

        # Section 4: Groups and Attributes
        groups_attrs = parser.groups + parser.attribute_groups
        if groups_attrs.any?
          html.section(id: "groups-attributes", class: "schema-section") do
            html.h2 "Global Groups and Attributes"
            groups_attrs.each do |component|
              type_label = component.name == "group" ? "Model Group" : "Attribute Group"
              generate_component_content(html, component, type_label)
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
                html.text target_ns
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
                html.li do
                  html.text "By default, local element declarations have no namespace."
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

      # Generate component content as div (not section) with all generators
      #
      # @param html [Nokogiri::HTML::Builder] HTML builder
      # @param component [Nokogiri::XML::Element] Schema component
      # @param component_type [String] Component type label
      def generate_component_content(html, component, component_type)
        component_name = component["name"] || component["ref"]
        return unless component_name

        component_id = generate_component_id(component_type, component_name)
        component_class = "component #{component_type.downcase.tr(' ', '-')}"

        html.div(id: component_id, class: component_class) do
          html.h3(class: "xs3p-subsection-heading") do
            html.text "#{component_type}: "
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
        # Get the component's XML representation
        xml = component.to_xml(indent: 3)

        # Add syntax highlighting classes
        xml.gsub!(/<(\/?)([\w:]+)([^>]*)>/) do
          tag_open = Regexp.last_match(1)
          tag_name = Regexp.last_match(2)
          attributes = Regexp.last_match(3)

          # Highlight tag names
          highlighted = "<span class=\"nt\">&lt;#{tag_open}"
          highlighted += "<a href=\"#ns_#{tag_name.split(':').first}\" " \
                        "title=\"Find out namespace of '#{tag_name.split(':').first}' prefix\">" \
                        "#{tag_name}</a>" if tag_name.include?(":")
          highlighted += tag_name unless tag_name.include?(":")

          # Highlight attributes
          if attributes && !attributes.empty?
            attributes.gsub!(/(\w+)="([^"]*)"/) do
              attr_name = Regexp.last_match(1)
              attr_value = Regexp.last_match(2)
              " <span class=\"na\">#{attr_name}=</span>" \
              "<span class=\"s\">\"#{attr_value}\"</span>"
            end
            highlighted += attributes
          end

          highlighted += "&gt;</span>"
          highlighted
        end

        xml
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
