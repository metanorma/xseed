# frozen_string_literal: true

require "nokogiri"

module Xseed
  module Documentation
    module Presentation
      # Generates navigation sidebar (Table of Contents) for HTML documentation
      # Ports functionality from XS3P navigation.xsl
      class NavigationBuilder
        def initialize(parser, config)
          @parser = parser
          @config = config
        end

        def generate
          builder = Nokogiri::HTML::Builder.new do |html|
            html.nav(id: "toc") do
              html.ul(class: "nav nav-list xs3p-sidenav") do
                generate_toc_items(html)
              end
            end
          end
          builder.to_html
        end

        private

        def generate_toc_items(html)
          # Schema properties
          html.li do
            html.strong do
              html.a("Schema Document Properties", href: "#SchemaProperties")
            end
          end

          # Generate component sections based on sorting preference
          if @config.sort_by_component
            generate_sorted_components(html)
          else
            generate_unsorted_components(html)
          end

          # Glossary (if enabled)
          return unless @config.print_glossary

          html.li do
            html.strong do
              html.a("Glossary", href: "#Glossary")
            end
          end
        end

        def generate_sorted_components(html)
          # Elements
          if @parser.elements.any?
            generate_component_section(html, @parser.elements, "Elements",
                                       "#SchemaElements")
          end

          # Complex Types
          if @parser.complex_types.any?
            generate_component_section(html, @parser.complex_types,
                                       "Complex Types", "#SchemaComplexTypes")
          end

          # Groups
          if @parser.groups.any?
            generate_component_section(html, @parser.groups, "Groups",
                                       "#SchemaGroups")
          end

          # Simple Types
          if @parser.simple_types.any?
            generate_component_section(html, @parser.simple_types, "Types",
                                       "#SchemaSimpleTypes")
          end

          # Attribute Groups
          return unless @parser.attribute_groups.any?

          generate_component_section(html, @parser.attribute_groups,
                                     "Attribute Groups", "#SchemaAttributeGroups")
        end

        def generate_unsorted_components(html)
          html.li do
            html.strong do
              html.a("Global Schema Components", href: "#SchemaComponents")
            end
          end

          # Generate all components in order they appear
          all_components = []
          if @parser.attribute_groups.any?
            all_components.concat(@parser.attribute_groups)
          end
          if @parser.complex_types.any?
            all_components.concat(@parser.complex_types)
          end
          all_components.concat(@parser.elements) if @parser.elements.any?
          all_components.concat(@parser.groups) if @parser.groups.any?
          if @parser.simple_types.any?
            all_components.concat(@parser.simple_types)
          end

          all_components.each do |component|
            generate_component_link(html, component)
          end
        end

        def generate_component_section(html, components, title, anchor)
          return if components.empty?

          html.li do
            html.strong do
              html.a(title, href: anchor)
            end

            html.ul(class: "nav nav-list nav-list-#{title.downcase.tr(' ',
                                                                      '-')}") do
              sorted_components = components.sort_by { |c| c["name"] || "" }
              sorted_components.each do |component|
                generate_component_link(html, component)
              end
            end
          end
        end

        def generate_component_link(html, component)
          component_name = component["name"]
          return unless component_name

          component_type = component.name
          component_id = generate_component_id(component_type, component_name)

          html.li(class: "nav-sub-item") do
            html.a(href: "##{component_id}") do
              html.strong component_name
            end
          end
        end

        def generate_component_id(component_type, component_name)
          type_name = case component_type
                      when "element"
                        "element"
                      when "complexType"
                        "complex-type"
                      when "simpleType"
                        "simple-type"
                      when "group"
                        "model-group"
                      when "attributeGroup"
                        "attribute-group"
                      when "attribute"
                        "attribute"
                      when "notation"
                        "notation"
                      else
                        component_type.downcase
                      end

          "#{type_name}-#{component_name}"
        end
      end
    end
  end
end
