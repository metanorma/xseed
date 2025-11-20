# frozen_string_literal: true

require "nokogiri"
require_relative "../config"
require_relative "../constants"

module Xseed
  module Documentation
    module Generators
      # Generates HTML properties definition lists for schema components
      # Ported from XS3P xs3p.xsl properties templates (lines 2322-3418)
      #
      # XS3P uses definition lists (<dl class="dl-horizontal">) not tables.
      # Each component type generates 1-3 DLs:
      # - Elements: Properties DL + Documentation DL
      # - Complex Types: Used By DL + Properties DL + Documentation DL
      # - Simple Types: Properties DL + Documentation DL
      # - Attributes: Properties DL + Documentation DL
      # - Attribute Groups/Groups: Used By DL + Documentation DL
      # - Schema: Properties DL + Namespaces DL
      class PropertiesTableGenerator
        include Constants

        attr_reader :component, :config, :schema

        # Initialize the properties generator
        #
        # @param component [Nokogiri::XML::Element] Schema component
        # @param config [Config] Configuration options
        def initialize(component, config = Config.new)
          raise ArgumentError, "Component cannot be nil" if component.nil?

          @component = component
          @config = config
          @schema = component.document.root
        end

        # Generate HTML definition lists with component properties
        # Returns array of DL HTML strings (1-3 DLs depending on component type)
        #
        # @return [Array<String>] Array of HTML DL markup strings
        def generate
          case component.name
          when "schema"
            generate_schema_properties
          when "element"
            generate_element_properties
          when "complexType"
            generate_complex_type_properties
          when "simpleType"
            generate_simple_type_properties
          when "attribute"
            generate_attribute_properties
          when "attributeGroup", "group"
            generate_group_properties
          when "notation"
            generate_notation_properties
          else
            []
          end
        end

        private

        # Generate properties for schema element (xs3p.xsl lines 3088-3290)
        # Returns: [Properties DL, Namespaces DL]
        def generate_schema_properties
          dls = []

          # First DL: Schema properties
          dls << build_dl do |xml|
            # Target Namespace
            xml.dt(class: "header") do
              glossary_term_ref(xml, "TargetNS", "Target Namespace")
            end
            xml.dd(class: "") do
              if schema["targetNamespace"]
                xml.span(class: "targetNS") do
                  xml.text schema["targetNamespace"]
                end
              else
                xml.text "None"
              end
            end

            # Version
            if schema["version"]
              xml.dt(class: "header") { xml.text "Version" }
              xml.dd(class: "") { xml.text schema["version"] }
            end

            # Language
            if schema["xml:lang"]
              xml.dt(class: "header") { xml.text "Language" }
              xml.dd(class: "") { xml.text schema["xml:lang"] }
            end

            # Element and Attribute Namespaces
            xml.dt(class: "header") do
              xml.text "Element and Attribute Namespaces"
            end
            xml.dd(class: "") do
              xml.ul do
                xml.li do
                  xml.text "Global element and attribute declarations belong to this schema's target namespace."
                end
                xml.li do
                  if schema["elementFormDefault"] == "qualified"
                    xml.text "By default, local element declarations belong to this schema's target namespace."
                  else
                    xml.text "By default, local element declarations have no namespace."
                  end
                end
                xml.li do
                  if schema["attributeFormDefault"] == "qualified"
                    xml.text "By default, local attribute declarations belong to this schema's target namespace."
                  else
                    xml.text "By default, local attribute declarations have no namespace."
                  end
                end
              end
            end

            # Schema Composition (imports, includes, redefines)
            if has_schema_composition?
              xml.dt(class: "header") { xml.text "Schema Composition" }
              xml.dd(class: "") do
                xml.ul do
                  generate_composition_info(xml)
                end
              end
            end
          end

          # Second DL: Declared Namespaces
          dls << build_declared_namespaces_dl

          dls
        end

        # Generate properties for element (xs3p.xsl lines 2732-2947)
        # Returns: [Properties DL, Documentation DL]
        def generate_element_properties
          dls = []

          # First DL: Element properties
          dls << build_dl do |xml|
            # Type
            xml.dt(class: "header") { xml.text "Type" }
            xml.dd(class: "") do
              type_value = get_element_type
              if type_value.start_with?("Locally-defined")
                xml.text type_value
              else
                xml.span(class: "type") do
                  type_ref_link(xml, type_value)
                end
              end
            end

            # Used By
            used_by = find_used_by_for_element
            if used_by.any?
              xml.dt(class: "header") { xml.text "Used By" }
              xml.dd(class: "") do
                used_by.each_with_index do |type_name, idx|
                  xml.text ", " if idx.positive?
                  xml.span(class: "type") { type_ref_link(xml, type_name) }
                end
              end
            end

            # Nillable
            if component["nillable"]
              xml.dt(class: "header") do
                glossary_term_ref(xml, "Nillable", "Nillable")
              end
              xml.dd(class: "") do
                xml.text print_boolean(component["nillable"])
              end
            end

            # Abstract
            if component["abstract"]
              xml.dt(class: "header") do
                glossary_term_ref(xml, "Abstract", "Abstract")
              end
              xml.dd(class: "") do
                xml.text print_boolean(component["abstract"])
              end
            end

            # Default Value
            if component["default"]
              xml.dt(class: "header") { xml.text "Default Value" }
              xml.dd(class: "") { xml.text component["default"] }
            end

            # Fixed Value
            if component["fixed"]
              xml.dt(class: "header") { xml.text "Fixed Value" }
              xml.dd(class: "") { xml.text component["fixed"] }
            end

            # Final (Substitution Group Exclusions)
            final_value = get_final_value
            if final_value && !final_value.empty?
              xml.dt(class: "header") do
                glossary_term_ref(xml, "ElemFinal",
                                  "Substitution Group Exclusions")
              end
              xml.dd(class: "") { xml.text final_value }
            end

            # Block (Disallowed Substitutions)
            block_value = get_block_value
            if block_value && !block_value.empty?
              xml.dt(class: "header") do
                glossary_term_ref(xml, "ElemBlock", "Disallowed Substitutions")
              end
              xml.dd(class: "") { xml.text block_value }
            end
          end

          # Second DL: Documentation
          dls << generate_documentation_dl

          dls.compact
        end

        # Generate properties for complex type (xs3p.xsl lines 2547-2726)
        # Returns: [Super-types DL, Used By DL, Properties DL, Documentation DL]
        def generate_complex_type_properties
          dls = []

          # First DL: Super-types (if has extension/restriction)
          base_type = get_complex_type_base
          if base_type
            dls << build_dl do |xml|
              xml.dt(class: "header") { xml.text "Super-types:" }
              xml.dd(class: "") do
                xml.span(class: "type") { type_ref_link(xml, base_type) }
              end
            end
          end

          # Second DL: Used By (if applicable)
          used_by = find_used_by_for_type
          if used_by.any?
            dls << build_dl do |xml|
              xml.dt(class: "header") { xml.text "Used By" }
              xml.dd(class: "") do
                used_by.each_with_index do |elem_name, idx|
                  xml.text ", " if idx.positive?
                  xml.span(class: "type") { element_ref_link(xml, elem_name) }
                end
              end
            end
          end

          # Third DL: Complex type properties (ONLY if has abstract/final/block)
          if has_complex_type_properties?
            dls << build_dl do |xml|
              # Abstract
              if component["abstract"]
                xml.dt(class: "header") do
                  glossary_term_ref(xml, "Abstract", "Abstract")
                end
                xml.dd(class: "") do
                  xml.text print_boolean(component["abstract"])
                end
              end

              # Final (Prohibited Derivations)
              final_value = get_derivation_set(component["final"] || schema["finalDefault"])
              unless final_value.empty?
                xml.dt(class: "header") do
                  glossary_term_ref(xml, "TypeFinal", "Prohibited Derivations")
                end
                xml.dd(class: "") { xml.text final_value }
              end

              # Block (Prohibited Substitutions)
              block_value = get_derivation_set(component["block"] || schema["blockDefault"])
              unless block_value.empty?
                xml.dt(class: "header") do
                  glossary_term_ref(xml, "TypeBlock",
                                    "Prohibited Substitutions")
                end
                xml.dd(class: "") { xml.text block_value }
              end
            end
          end

          # Fourth DL: Documentation
          dls << generate_documentation_dl

          dls.compact
        end

        # Get base type for complex type (from extension or restriction)
        # Returns base type name or nil
        def get_complex_type_base
          # Check for complexContent/extension
          extension = component.at_xpath("xsd:complexContent/xsd:extension",
                                         "xsd" => XSD_NS)
          return extension["base"] if extension

          # Check for complexContent/restriction
          restriction = component.at_xpath("xsd:complexContent/xsd:restriction",
                                           "xsd" => XSD_NS)
          return restriction["base"] if restriction

          # Check for simpleContent/extension
          extension = component.at_xpath("xsd:simpleContent/xsd:extension",
                                         "xsd" => XSD_NS)
          return extension["base"] if extension

          # Check for simpleContent/restriction
          restriction = component.at_xpath("xsd:simpleContent/xsd:restriction",
                                           "xsd" => XSD_NS)
          restriction["base"] if restriction
        end

        # Check if complex type has properties worth displaying (follows XS3P logic)
        # Only generate Properties DL if has abstract/final/block attributes
        def has_complex_type_properties?
          return true if component["abstract"]

          final_value = get_derivation_set(component["final"] || schema["finalDefault"])
          return true unless final_value.empty?

          block_value = get_derivation_set(component["block"] || schema["blockDefault"])
          !block_value.empty?
        end

        # Generate properties for simple type (xs3p.xsl lines 3297-3412)
        # Returns: [Properties DL, Documentation DL]
        def generate_simple_type_properties
          dls = []

          # First DL: Simple type properties
          dls << build_dl do |xml|
            # Content (with facets)
            xml.dt(class: "header") { xml.text "Content" }
            xml.dd(class: "") do
              print_simple_constraints(xml)
            end

            # Final (Prohibited Derivations)
            final_value = get_simple_derivation_set(component["final"] || schema["finalDefault"])
            unless final_value.empty?
              xml.dt(class: "header") do
                glossary_term_ref(xml, "TypeFinal", "Prohibited Derivations")
              end
              xml.dd(class: "") { xml.text final_value }
            end
          end

          # Second DL: Documentation
          dls << generate_documentation_dl

          dls.compact
        end

        # Generate properties for attribute (xs3p.xsl lines 2322-2435)
        # Returns: [Properties DL, Documentation DL]
        def generate_attribute_properties
          dls = []

          # First DL: Attribute properties
          dls << build_dl do |xml|
            # Type
            xml.dt(class: "header") { xml.text "Type" }
            xml.dd(class: "") do
              type_value = get_attribute_type
              if type_value.start_with?("Locally-defined")
                xml.text type_value
              else
                xml.span(class: "type") { type_ref_link(xml, type_value) }
              end
            end

            # Default Value
            if component["default"]
              xml.dt(class: "header") { xml.text "Default Value" }
              xml.dd(class: "") { xml.text component["default"] }
            end

            # Fixed Value
            if component["fixed"]
              xml.dt(class: "header") { xml.text "Fixed Value" }
              xml.dd(class: "") { xml.text component["fixed"] }
            end
          end

          # Second DL: Documentation
          dls << generate_documentation_dl

          dls.compact
        end

        # Generate properties for attribute group or model group (xs3p.xsl lines 2441-2541)
        # Returns: [Used By DL (optional), Documentation DL]
        def generate_group_properties
          dls = []

          # First DL: Used By (if applicable)
          if component.name == "attributeGroup"
            used_by = find_used_by_for_attribute_group
            if used_by.any?
              dls << build_dl do |xml|
                xml.dt(class: "header") { xml.text "Used By" }
                xml.dd(class: "") do
                  used_by.each_with_index do |type_name, idx|
                    xml.text ", " if idx.positive?
                    xml.span(class: "type") { type_ref_link(xml, type_name) }
                  end
                end
              end
            end
          end

          # Second DL: Documentation
          dls << generate_documentation_dl

          dls.compact
        end

        # Generate properties for notation (xs3p.xsl lines 2989-3082)
        # Returns: [Properties DL, Documentation DL]
        def generate_notation_properties
          dls = []

          # First DL: Notation properties
          dls << build_dl do |xml|
            # Public Identifier
            xml.dt(class: "header") { xml.text "Public Identifier" }
            xml.dd(class: "") { xml.text component["public"] }

            # System Identifier
            if component["system"]
              xml.dt(class: "header") { xml.text "System Identifier" }
              xml.dd(class: "") { xml.text component["system"] }
            end
          end

          # Second DL: Documentation
          dls << generate_documentation_dl

          dls.compact
        end

        # Generate documentation DL for any component
        # Returns nil if no documentation exists
        def generate_documentation_dl
          doc_content = extract_documentation
          return nil unless doc_content

          build_dl do |xml|
            xml.dt { xml.text "Documentation" }
            xml.dd do
              xml.div(class: "annotation documentation",
                      id: "wdoc-#{component.object_id}") do
                xml.div(class: "hidden",
                        id: "#{component.object_id}-doc-raw") do
                  xml.text doc_content
                end
                xml.div(class: "xs3p-doc", id: "#{component.object_id}-doc") do
                  xml.text " "
                end
              end
            end
          end
        end

        # Generate declared namespaces DL for schema
        def build_declared_namespaces_dl
          build_dl do |xml|
            # Header row
            xml.dt(class: "header") { xml.text "Prefix" }
            xml.dd(class: "header") { xml.text "Namespace" }

            # Default namespace
            default_ns = schema.namespaces["xmlns"]
            if default_ns
              xml.dt(class: "") do
                xml.a(id: "ns_") { xml.text "Default namespace" }
              end
              xml.dd(class: "") do
                if default_ns == schema["targetNamespace"]
                  xml.span(class: "targetNS") { xml.text default_ns }
                else
                  xml.text default_ns
                end
              end
            end

            # Namespaces with prefixes
            schema.namespaces.each do |prefix_key, namespace_uri|
              next if prefix_key == "xmlns" # Skip default namespace

              prefix = prefix_key.sub("xmlns:", "")
              xml.dt(class: "") do
                xml.a(id: "ns_#{prefix}") { xml.text prefix }
              end
              xml.dd(class: "") do
                if namespace_uri == schema["targetNamespace"]
                  xml.span(class: "targetNS") { xml.text namespace_uri }
                else
                  xml.text namespace_uri
                end
              end
            end
          end
        end

        # Build a definition list with given content
        def build_dl
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.dl(class: "dl-horizontal") do
              yield(xml)
            end
          end
          builder.doc.root.to_html
        end

        # Print simple constraints for simple types (xs3p.xsl lines 3573-3813)
        def print_simple_constraints(xml)
          restriction = component.at_xpath("xsd:restriction", "xsd" => XSD_NS)
          list_elem = component.at_xpath("xsd:list", "xsd" => XSD_NS)
          union_elem = component.at_xpath("xsd:union", "xsd" => XSD_NS)

          if restriction
            print_simple_restriction(xml, restriction)
          elsif list_elem
            xml.ul do
              xml.li do
                xml.text "List of: "
                if list_elem["itemType"]
                  type_ref_link(xml, list_elem["itemType"])
                else
                  # Locally-defined item type
                  xml.text "Locally defined type"
                end
              end
            end
          elsif union_elem
            xml.ul do
              xml.li do
                xml.text "Union of following types: "
                xml.ul do
                  union_elem["memberTypes"]&.split&.each do |member_type|
                    xml.li { type_ref_link(xml, member_type) }
                  end
                  # Locally-defined member types
                  union_elem.xpath("xsd:simpleType", "xsd" => XSD_NS).each do
                    xml.li { xml.text "Locally defined type" }
                  end
                end
              end
            end
          end
        end

        # Print simple restriction (xs3p.xsl lines 3651-3734)
        def print_simple_restriction(xml, restriction)
          base_type = restriction["base"]

          # Base type
          if base_type
            base_name = base_type.include?(":") ? base_type.split(":").last : base_type
            base_ns = get_namespace_for_prefix(base_type.split(":").first) if base_type.include?(":")

            if base_ns == XSD_NS || !base_type.include?(":")
              xml.ul do
                xml.li do
                  xml.text "Base XSD Type: "
                  xml.text base_name
                end
              end
            else
              # Look up the base type and recurse
              base_type_elem = schema.at_xpath(
                "//xsd:simpleType[@name='#{base_name}']", "xsd" => XSD_NS
              )
              if base_type_elem
                base_gen = self.class.new(base_type_elem, config)
                base_gen.print_simple_constraints(xml)
              end
            end
          end

          # Facets
          print_facets(xml, restriction)
        end

        # Print facets from restriction (xs3p.xsl lines 3737-3811)
        def print_facets(xml, restriction)
          facets_list = []

          # Enumeration
          enums = restriction.xpath("xsd:enumeration", "xsd" => XSD_NS)
          if enums.any?
            facets_list << ->(xml) do
              xml.em { xml.text "value" }
              xml.text " comes from list: {"
              enums.each_with_index do |enum, idx|
                xml.text "|" if idx.positive?
                xml.text "'#{enum['value']}'"
              end
              xml.text "}"
            end
          end

          # Pattern
          pattern = restriction.at_xpath("xsd:pattern", "xsd" => XSD_NS)
          if pattern
            facets_list << ->(xml) do
              xml.em { xml.text "pattern" }
              xml.text " = #{pattern['value']}"
            end
          end

          # Range facets
          range_facet = get_range_facet(restriction)
          if range_facet
            facets_list << ->(xml) { xml << range_facet }
          end

          # Total digits
          total_digits = restriction.at_xpath("xsd:totalDigits",
                                              "xsd" => XSD_NS)
          if total_digits
            facets_list << ->(xml) do
              xml.em { xml.text "total no. of digits" }
              xml.text " = #{total_digits['value']}"
            end
          end

          # Fraction digits
          fraction_digits = restriction.at_xpath("xsd:fractionDigits",
                                                 "xsd" => XSD_NS)
          if fraction_digits
            facets_list << ->(xml) do
              xml.em { xml.text "no. of fraction digits" }
              xml.text " = #{fraction_digits['value']}"
            end
          end

          # Length facets
          length_facet = get_length_facet(restriction)
          if length_facet
            facets_list << ->(xml) { xml << length_facet }
          end

          # Whitespace
          whitespace = restriction.at_xpath("xsd:whiteSpace", "xsd" => XSD_NS)
          if whitespace
            facets_list << ->(xml) do
              xml.em { xml.text "Whitespace policy: " }
              policy_code = case whitespace["value"]
                            when "preserve" then "PreserveWS"
                            when "replace" then "ReplaceWS"
                            when "collapse" then "CollapseWS"
                            end
              if policy_code
                glossary_term_ref(xml, policy_code,
                                  whitespace["value"])
              end
            end
          end

          # Output facets as list if any exist
          return if facets_list.empty?

          xml.ul do
            facets_list.each do |facet_lambda|
              xml.li { facet_lambda.call(xml) }
            end
          end
        end

        # Get range facet string
        def get_range_facet(restriction)
          min_inc = restriction.at_xpath("xsd:minInclusive", "xsd" => XSD_NS)
          min_exc = restriction.at_xpath("xsd:minExclusive", "xsd" => XSD_NS)
          max_inc = restriction.at_xpath("xsd:maxInclusive", "xsd" => XSD_NS)
          max_exc = restriction.at_xpath("xsd:maxExclusive", "xsd" => XSD_NS)

          return nil unless min_inc || min_exc || max_inc || max_exc

          parts = []
          if min_inc
            parts << "#{min_inc['value']} &lt;= <em>value</em>"
          elsif min_exc
            parts << "#{min_exc['value']} &lt; <em>value</em>"
          end

          if max_inc
            parts << "<em>value</em> &lt;= #{max_inc['value']}"
          elsif max_exc
            parts << "<em>value</em> &lt; #{max_exc['value']}"
          end

          parts.join(" and ")
        end

        # Get length facet string
        def get_length_facet(restriction)
          length = restriction.at_xpath("xsd:length", "xsd" => XSD_NS)
          min_length = restriction.at_xpath("xsd:minLength", "xsd" => XSD_NS)
          max_length = restriction.at_xpath("xsd:maxLength", "xsd" => XSD_NS)

          return nil unless length || min_length || max_length

          if length
            "<em>length</em> = #{length['value']}"
          elsif min_length && max_length
            "#{min_length['value']} &lt;= <em>length</em> &lt;= #{max_length['value']}"
          elsif min_length
            "<em>length</em> &gt;= #{min_length['value']}"
          elsif max_length
            "<em>length</em> &lt;= #{max_length['value']}"
          end
        end

        # Find elements that use this element (via ref)
        def find_used_by_for_element
          elem_name = component["name"]
          return [] unless elem_name

          used_by = []
          schema.xpath("//xsd:element[@ref='#{elem_name}']",
                       "xsd" => XSD_NS).each do |ref_elem|
            # Find containing complex type
            parent_type = ref_elem.at_xpath("ancestor::xsd:complexType[@name]",
                                            "xsd" => XSD_NS)
            used_by << parent_type["name"] if parent_type
          end
          used_by.uniq
        end

        # Find elements that use this type
        def find_used_by_for_type
          type_name = component["name"]
          return [] unless type_name

          used_by = schema.xpath(
            "//xsd:element[@type='#{type_name}'] | //xsd:element[@type='#{get_prefixed_name(type_name)}']", "xsd" => XSD_NS
          ).map do |elem|
            elem["name"]
          end
          used_by.uniq.compact
        end

        # Find types that use this attribute group
        def find_used_by_for_attribute_group
          group_name = component["name"]
          return [] unless group_name

          used_by = []
          schema.xpath("//xsd:attributeGroup[@ref='#{group_name}']",
                       "xsd" => XSD_NS).each do |ref|
            parent_type = ref.at_xpath("ancestor::xsd:complexType[@name]",
                                       "xsd" => XSD_NS)
            used_by << parent_type["name"] if parent_type
          end
          used_by.uniq
        end

        # Get element type
        def get_element_type
          if component.at_xpath("xsd:simpleType", "xsd" => XSD_NS)
            "Locally-defined simple type"
          elsif component.at_xpath("xsd:complexType", "xsd" => XSD_NS)
            "Locally-defined complex type"
          elsif component["type"]
            component["type"]
          else
            "anyType"
          end
        end

        # Get attribute type
        def get_attribute_type
          if component.at_xpath("xsd:simpleType", "xsd" => XSD_NS)
            "Locally-defined simple type"
          elsif component["type"]
            component["type"]
          else
            "anySimpleType"
          end
        end

        # Get final value for element
        def get_final_value
          final_attr = component["final"] || schema["finalDefault"]
          translate_derivation_set(final_attr)
        end

        # Get block value for element
        def get_block_value
          block_attr = component["block"] || schema["blockDefault"]
          translate_block_set(block_attr)
        end

        # Translate derivation set (#all -> full list)
        def get_derivation_set(value)
          return "" unless value

          if value == "#all"
            "restriction, extension"
          else
            value
          end
        end

        # Translate simple derivation set (#all -> full list)
        def get_simple_derivation_set(value)
          return "" unless value

          if value == "#all"
            "restriction, list, union"
          else
            value
          end
        end

        # Translate block set (#all -> full list for elements)
        def translate_block_set(value)
          return "" unless value

          if value == "#all"
            "restriction, extension, substitution"
          else
            value
          end
        end

        # Translate derivation set for elements/types
        def translate_derivation_set(value)
          return "" unless value

          if value == "#all"
            "restriction, extension"
          else
            value
          end
        end

        # Print boolean value as yes/no
        def print_boolean(bool_value)
          return "no" unless bool_value

          normalized = bool_value.to_s.downcase
          ["true", "1"].include?(normalized) ? "yes" : "no"
        end

        # Check if schema has imports, includes, or redefines
        def has_schema_composition?
          schema.at_xpath("xsd:import | xsd:include | xsd:redefine",
                          "xsd" => XSD_NS)
        end

        # Generate schema composition info
        def generate_composition_info(xml)
          # Imports
          imports = schema.xpath("xsd:import", "xsd" => XSD_NS)
          if imports.any?
            xml.li do
              xml.text "This schema imports schema(s) from the following namespace(s):"
              xml.ul do
                imports.each do |import_elem|
                  xml.li do
                    xml.em { xml.text import_elem["namespace"] }
                    if import_elem["schemaLocation"]
                      xml.text " (at #{import_elem['schemaLocation']})"
                    end
                  end
                end
              end
            end
          end

          # Includes
          includes = schema.xpath("xsd:include", "xsd" => XSD_NS)
          if includes.any?
            xml.li do
              xml.text "This schema includes components from the following schema document(s):"
              xml.ul do
                includes.each do |include_elem|
                  xml.li { xml.text include_elem["schemaLocation"] }
                end
              end
            end
          end

          # Redefines
          redefines = schema.xpath("xsd:redefine", "xsd" => XSD_NS)
          return unless redefines.any?

          xml.li do
            xml.text "This schema includes components from the following schema document(s), where some of the components have been redefined:"
            xml.ul do
              redefines.each do |redefine_elem|
                xml.li { xml.text redefine_elem["schemaLocation"] }
              end
            end
            xml.text "See "
            xml.a(href: "#Redefinitions") do
              xml.text "Redefined Schema Components"
            end
            xml.text " section."
          end
        end

        # Extract documentation text
        def extract_documentation
          doc_node = component.at_xpath("xsd:annotation/xsd:documentation",
                                        "xsd" => XSD_NS)
          doc_node&.text&.strip
        end

        # Generate glossary term reference link
        def glossary_term_ref(xml, code, term)
          if config.print_glossary
            xml.a(title: "Look up '#{term}' in glossary",
                  href: "#term_#{code}") do
              xml.text term
            end
          else
            xml.text term
          end
        end

        # Generate type reference link
        def type_ref_link(xml, type_ref)
          type_name = type_ref.include?(":") ? type_ref.split(":").last : type_ref
          xml.a(title: "Jump to \"#{type_name}\" type definition.",
                href: "#type_#{type_name}") do
            xml.text type_name
          end
        end

        # Generate element reference link
        def element_ref_link(xml, elem_ref)
          elem_name = elem_ref.include?(":") ? elem_ref.split(":").last : elem_ref
          xml.a(title: "Jump to \"#{elem_name}\" element declaration.",
                href: "#element_#{elem_name}") do
            xml.text elem_name
          end
        end

        # Get prefixed name for type reference
        def get_prefixed_name(name)
          prefix = get_target_namespace_prefix
          prefix ? "#{prefix}:#{name}" : name
        end

        # Get prefix for target namespace
        def get_target_namespace_prefix
          target_ns = schema["targetNamespace"]
          return nil unless target_ns

          schema.namespaces.each do |prefix_key, ns_uri|
            next if prefix_key == "xmlns"

            return prefix_key.sub("xmlns:", "") if ns_uri == target_ns
          end
          nil
        end

        # Get namespace URI for a given prefix
        def get_namespace_for_prefix(prefix)
          return nil unless prefix

          schema.namespaces["xmlns:#{prefix}"]
        end
      end
    end
  end
end
