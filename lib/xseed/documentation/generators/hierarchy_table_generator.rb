# frozen_string_literal: true

require "nokogiri"
require_relative "../config"
require_relative "../constants"

module Xseed
  module Documentation
    module Generators
      # Generates HTML hierarchy tables for schema components
      # Shows type hierarchies and substitution groups
      # Ported from XS3P hierarchy-tables.xsl
      class HierarchyTableGenerator
        include Constants

        attr_reader :component, :parser, :config

        # Initialize the hierarchy table generator
        #
        # @param component [Nokogiri::XML::Element] Schema component
        # @param parser [Xseed::Parser::XsdParser] XSD parser instance
        # @param config [Config] Configuration options
        def initialize(component, parser, config = Config.new)
          raise ArgumentError, "Component cannot be nil" if component.nil?
          raise ArgumentError, "Parser cannot be nil" if parser.nil?

          @component = component
          @parser = parser
          @config = config
        end

        # Generate HTML hierarchy table
        #
        # @return [String, nil] HTML table markup or nil if no hierarchy
        def generate
          return nil unless has_hierarchy?

          builder = Nokogiri::HTML::Builder.new do |html|
            html.div(class: "hierarchy") do
              html.table(class: "table table-striped xs3p-in-panel-table") do
                html.tbody do
                  if element?
                    generate_substitution_groups(html)
                  elsif complex_type?
                    generate_complex_type_hierarchy(html)
                  elsif simple_type?
                    generate_simple_type_hierarchy(html)
                  end
                end
              end
            end
          end
          builder.to_html
        end

        private

        # Check if component has hierarchy to display
        #
        # @return [Boolean]
        def has_hierarchy?
          if element?
            # Element has hierarchy if it has substitutionGroup or is head of one
            !component["substitutionGroup"].nil? || has_substitution_members?
          elsif complex_type?
            # Complex type has hierarchy if it has base type or derived types
            has_base_type? || !find_subtypes.empty?
          elsif simple_type?
            # Simple type has hierarchy if it has restriction base or derived types
            has_restriction_base? || !find_simple_subtypes.empty?
          else
            false
          end
        end

        # Generate substitution groups section for elements
        #
        # @param html [Nokogiri::HTML::Builder] HTML builder
        def generate_substitution_groups(html)
          # Show substitution group this element belongs to
          if component["substitutionGroup"]
            html.tr do
              html.td do
                html.ul do
                  html.li do
                    html.em do
                      html.text "This element can be used wherever the following element is referenced:"
                    end
                    html.ul do
                      html.li do
                        html.text component["substitutionGroup"]
                      end
                    end
                  end
                end
              end
            end
          end

          # Show substitution group members (elements that can substitute this one)
          return unless has_substitution_members?

          members = find_substitution_members
          html.tr do
            html.td do
              html.ul do
                html.li do
                  html.em do
                    html.text "The following elements can be used wherever this element is referenced:"
                  end
                  html.ul do
                    members.each do |member|
                      html.li do
                        html.text member["name"]
                      end
                    end
                  end
                end
              end
            end
          end
        end

        # Generate type hierarchy for complex types
        #
        # @param html [Nokogiri::HTML::Builder] HTML builder
        def generate_complex_type_hierarchy(html)
          # Show supertypes
          if has_base_type?
            html.tr do
              html.th do
                if config.print_all_super_types
                  html.text "Super-types:"
                else
                  html.text "Parent type:"
                end
              end
              html.td do
                generate_supertypes(html)
              end
            end
          end

          # Show subtypes
          subtypes = find_subtypes
          return if subtypes.empty?

          html.tr do
            html.th do
              if config.print_all_sub_types
                html.text "Sub-types:"
              else
                html.text "Direct sub-types:"
              end
            end
            html.td do
              generate_subtypes(html, subtypes)
            end
          end
        end

        # Generate type hierarchy for simple types
        #
        # @param html [Nokogiri::HTML::Builder] HTML builder
        def generate_simple_type_hierarchy(html)
          # Show supertypes
          if has_restriction_base?
            html.tr do
              html.th do
                if config.print_all_super_types
                  html.text "Super-types:"
                else
                  html.text "Parent type:"
                end
              end
              html.td do
                generate_simple_supertypes(html)
              end
            end
          end

          # Show subtypes
          subtypes = find_simple_subtypes
          return if subtypes.empty?

          html.tr do
            html.th do
              if config.print_all_sub_types
                html.text "Sub-types:"
              else
                html.text "Direct sub-types:"
              end
            end
            html.td do
              generate_simple_derived_types(html, subtypes)
            end
          end
        end

        # Generate supertypes chain for complex types
        #
        # @param html [Nokogiri::HTML::Builder] HTML builder
        def generate_supertypes(html)
          base_ref = extract_base_type_ref
          return unless base_ref

          if config.print_all_super_types
            # Show full hierarchy
            chain = build_supertype_chain(base_ref)
            html.text chain.join(" < ")
          else
            # Show only immediate parent
            html.text "#{base_ref} (#{derivation_method})"
          end
        end

        # Generate supertypes for simple types
        #
        # @param html [Nokogiri::HTML::Builder] HTML builder
        def generate_simple_supertypes(html)
          restriction = component.at_xpath("xsd:restriction", "xsd" => XSD_NS)
          return unless restriction

          base_ref = restriction["base"]
          return unless base_ref

          if config.print_all_super_types
            # Show full hierarchy
            chain = build_simple_supertype_chain(base_ref)
            html.text chain.join(" < ")
          else
            # Show only immediate parent
            html.text "#{base_ref} (by restriction)"
          end
        end

        # Generate subtypes list
        #
        # @param html [Nokogiri::HTML::Builder] HTML builder
        # @param subtypes [Array<Nokogiri::XML::Element>] Subtype elements
        def generate_subtypes(html, subtypes)
          html.ul do
            subtypes.each do |subtype|
              html.li do
                html.text subtype["name"]
                html.text " (by #{get_derivation_method(subtype)})"

                # Recursively show sub-subtypes if config allows
                if config.print_all_sub_types
                  sub_subtypes = find_subtypes_of(subtype)
                  unless sub_subtypes.empty?
                    generate_subtypes(html,
                                      sub_subtypes)
                  end
                end
              end
            end
          end
        end

        # Generate subtypes list for simple types
        #
        # @param html [Nokogiri::HTML::Builder] HTML builder
        # @param subtypes [Array<Nokogiri::XML::Element>] Subtype elements
        def generate_simple_derived_types(html, subtypes)
          html.ul do
            subtypes.each do |subtype|
              html.li do
                html.text "#{subtype['name']} (by restriction)"

                # Recursively show sub-subtypes if config allows
                if config.print_all_sub_types
                  sub_subtypes = find_simple_subtypes_of(subtype)
                  unless sub_subtypes.empty?
                    generate_simple_derived_types(html, sub_subtypes)
                  end
                end
              end
            end
          end
        end

        # Check if component is an element
        #
        # @return [Boolean]
        def element?
          component.name == "element"
        end

        # Check if component is a complex type
        #
        # @return [Boolean]
        def complex_type?
          component.name == "complexType"
        end

        # Check if component is a simple type
        #
        # @return [Boolean]
        def simple_type?
          component.name == "simpleType"
        end

        # Check if element has substitution group members
        #
        # @return [Boolean]
        def has_substitution_members?
          !find_substitution_members.empty?
        end

        # Find elements that can substitute this element
        #
        # @return [Array<Nokogiri::XML::Element>]
        def find_substitution_members
          element_name = component["name"]
          return [] unless element_name

          parser.elements.select do |elem|
            elem["substitutionGroup"] == element_name
          end
        end

        # Check if complex type has base type
        #
        # @return [Boolean]
        def has_base_type?
          return false unless complex_type?

          !extract_base_type_ref.nil?
        end

        # Check if simple type has restriction base
        #
        # @return [Boolean]
        def has_restriction_base?
          return false unless simple_type?

          restriction = component.at_xpath("xsd:restriction", "xsd" => XSD_NS)
          !!(restriction && restriction["base"])
        end

        # Extract base type reference from complex type
        #
        # @return [String, nil]
        def extract_base_type_ref
          # Check simpleContent
          if (extension = component.at_xpath(
            "xsd:simpleContent/xsd:extension",
            "xsd" => XSD_NS
          ))
            return extension["base"]
          end

          if (restriction = component.at_xpath(
            "xsd:simpleContent/xsd:restriction",
            "xsd" => XSD_NS
          ))
            return restriction["base"]
          end

          # Check complexContent
          if (extension = component.at_xpath(
            "xsd:complexContent/xsd:extension",
            "xsd" => XSD_NS
          ))
            return extension["base"]
          end

          if (restriction = component.at_xpath(
            "xsd:complexContent/xsd:restriction",
            "xsd" => XSD_NS
          ))
            return restriction["base"]
          end

          nil
        end

        # Get derivation method (extension or restriction)
        #
        # @return [String]
        def derivation_method
          if component.at_xpath(
            "xsd:simpleContent/xsd:extension | xsd:complexContent/xsd:extension",
            "xsd" => XSD_NS
          )
            "extension"
          elsif component.at_xpath(
            "xsd:simpleContent/xsd:restriction | xsd:complexContent/xsd:restriction",
            "xsd" => XSD_NS
          )
            "restriction"
          else
            "unknown"
          end
        end

        # Get derivation method for a given type
        #
        # @param type [Nokogiri::XML::Element] Type element
        # @return [String]
        def get_derivation_method(type)
          if type.at_xpath(
            "xsd:complexContent/xsd:extension | xsd:simpleContent/xsd:extension",
            "xsd" => XSD_NS
          )
            "extension"
          else
            "restriction"
          end
        end

        # Build supertype chain
        #
        # @param base_ref [String] Base type reference
        # @return [Array<String>]
        def build_supertype_chain(base_ref)
          chain = [base_ref]
          current_type_name = strip_namespace_prefix(base_ref)

          # Find the type in the schema
          current_type = parser.complex_types.find do |t|
            t["name"] == current_type_name
          end

          # Walk up the hierarchy
          while current_type
            generator = self.class.new(current_type, parser, config)
            next_base = generator.send(:extract_base_type_ref)
            break unless next_base

            chain.unshift(next_base)
            current_type_name = strip_namespace_prefix(next_base)
            current_type = parser.complex_types.find do |t|
              t["name"] == current_type_name
            end
          end

          chain << "#{component['name']} (by #{derivation_method})"
          chain
        end

        # Build supertype chain for simple types
        #
        # @param base_ref [String] Base type reference
        # @return [Array<String>]
        def build_simple_supertype_chain(base_ref)
          chain = [base_ref]
          current_type_name = strip_namespace_prefix(base_ref)

          # Find the type in the schema
          current_type = parser.simple_types.find do |t|
            t["name"] == current_type_name
          end

          # Walk up the hierarchy
          while current_type
            restriction = current_type.at_xpath(
              "xsd:restriction",
              "xsd" => XSD_NS
            )
            break unless restriction

            next_base = restriction["base"]
            break unless next_base

            chain.unshift(next_base)
            current_type_name = strip_namespace_prefix(next_base)
            current_type = parser.simple_types.find do |t|
              t["name"] == current_type_name
            end
          end

          chain << "#{component['name']} (by restriction)"
          chain
        end

        # Find direct subtypes of this complex type
        #
        # @return [Array<Nokogiri::XML::Element>]
        def find_subtypes
          type_name = component["name"]
          return [] unless type_name

          parser.complex_types.select do |ct|
            base_ref = self.class.new(ct, parser, config)
                           .send(:extract_base_type_ref)
            base_ref && strip_namespace_prefix(base_ref) == type_name
          end
        end

        # Find direct subtypes of a given type
        #
        # @param type [Nokogiri::XML::Element] Type element
        # @return [Array<Nokogiri::XML::Element>]
        def find_subtypes_of(type)
          type_name = type["name"]
          return [] unless type_name

          parser.complex_types.select do |ct|
            next if ct == type

            base_ref = self.class.new(ct, parser, config)
                           .send(:extract_base_type_ref)
            base_ref && strip_namespace_prefix(base_ref) == type_name
          end
        end

        # Find direct subtypes of this simple type
        #
        # @return [Array<Nokogiri::XML::Element>]
        def find_simple_subtypes
          type_name = component["name"]
          return [] unless type_name

          parser.simple_types.select do |st|
            restriction = st.at_xpath("xsd:restriction", "xsd" => XSD_NS)
            next unless restriction

            base_ref = restriction["base"]
            base_ref && strip_namespace_prefix(base_ref) == type_name
          end
        end

        # Find direct subtypes of a given simple type
        #
        # @param type [Nokogiri::XML::Element] Type element
        # @return [Array<Nokogiri::XML::Element>]
        def find_simple_subtypes_of(type)
          type_name = type["name"]
          return [] unless type_name

          parser.simple_types.select do |st|
            next if st == type

            restriction = st.at_xpath("xsd:restriction", "xsd" => XSD_NS)
            next unless restriction

            base_ref = restriction["base"]
            base_ref && strip_namespace_prefix(base_ref) == type_name
          end
        end

        # Strip namespace prefix from a type reference
        #
        # @param ref [String] Type reference (may include prefix)
        # @return [String] Type name without prefix
        def strip_namespace_prefix(ref)
          ref.to_s.split(":").last
        end
      end
    end
  end
end
