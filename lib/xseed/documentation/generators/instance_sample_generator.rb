# frozen_string_literal: true

require "nokogiri"
require_relative "../config"
require_relative "../constants"

module Xseed
  module Documentation
    module Generators
      # Generates XML instance samples for schema components
      # Ported from XS3P instance-samples-*.xsl modules
      class InstanceSampleGenerator
        include Constants

        attr_reader :component, :parser, :config

        # Initialize the instance sample generator
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
          @indent_level = 0
          @type_stack = [] # Track types to prevent infinite recursion
          @group_stack = [] # Track groups to prevent infinite recursion
          @recursion_depth = 0
          @max_recursion_depth = 10
        end

        # Generate HTML with XML instance sample
        #
        # @return [String] HTML markup
        def generate
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.pre(class: "codehilite") do
              xml << generate_xml_sample_with_highlighting
            end
          end
          builder.doc.root.to_html
        end

        private

        # Generate XML sample with syntax highlighting
        #
        # @return [String] HTML with highlighted XML
        def generate_xml_sample_with_highlighting
          xml_text = generate_xml_sample
          highlight_xml(xml_text)
        end

        # Generate XML sample based on component type
        #
        # @return [String] XML sample text
        def generate_xml_sample
          case component.name
          when "element"
            generate_element_sample
          when "complexType"
            generate_complex_type_sample
          when "simpleType"
            generate_simple_type_sample
          else
            "<!-- Unsupported component type: #{component.name} -->"
          end
        end

        # Apply syntax highlighting to XML
        #
        # @param xml [String] Plain XML text
        # @return [String] HTML with syntax highlighting
        def highlight_xml(xml)
          result = xml.dup

          # Highlight XML tags
          result.gsub!(/<(\/?)([\w:]+)([^>]*)>/) do
            tag_close = Regexp.last_match(1)
            tag_name = Regexp.last_match(2)
            rest = Regexp.last_match(3)

            highlighted = "<span class=\"nt\">&lt;#{tag_close}#{tag_name}"
            highlighted += rest if rest && !rest.empty?
            "#{highlighted}&gt;</span>"
          end

          # Highlight type information
          result.gsub!(/\b(xsd:\w+)\b/) do
            type_name = Regexp.last_match(1)
            "<span class=\"type\">#{type_name}</span>"
          end

          # Highlight occurrence info [min..max]
          result.gsub(/(\[[\d∞]+\.\.[\d∞]+\])/) do
            "<span class=\"cs\">#{Regexp.last_match(1)}</span>"
          end
        end

        # Generate sample for element declaration
        #
        # @return [String] XML sample
        def generate_element_sample
          return "" if prohibited_element?

          result = []
          indent = "  " * @indent_level

          # Start tag with namespace
          start_tag = "<#{element_tag}"

          # Add namespace declaration for root element
          if @indent_level.zero? && target_namespace
            start_tag += " xmlns=\"#{target_namespace}\""
          end

          # Add attributes if complex type or has local complexType
          type_node = nil
          if component.at_xpath("xsd:complexType", "xsd" => XSD_NS)
            type_node = component.at_xpath("xsd:complexType", "xsd" => XSD_NS)
          elsif component["type"]
            type_node = resolve_type
          end

          if type_node
            attrs = collect_attributes(type_node)
            if attrs && !attrs.empty?
              result << (indent + start_tag) unless start_tag.empty?
              attrs.each do |attr|
                result << "#{indent}  #{attr}"
              end
              start_tag = ""
            end
          end

          # Generate content
          content = generate_element_content

          if content.empty? && start_tag.end_with?('"')
            # Self-closing tag with attributes
            result << "#{indent}#{start_tag}/>" unless start_tag.empty?
          elsif content.empty?
            # Self-closing tag
            result << "#{indent}#{start_tag}/>"
          else
            # Element with content
            result << "#{indent}#{start_tag}>" if start_tag && !start_tag.empty?
            result << content
            result << "#{indent}</#{element_tag}>"
          end

          add_occurrence_info(result)
          result.join("\n")
        end

        # Generate sample for complex type
        #
        # @return [String] XML sample
        def generate_complex_type_sample
          return "" unless component.name == "complexType"

          type_name = component["name"]
          return "" if circular_type?(type_name)

          push_type(type_name) if type_name

          result = []
          indent = "  " * @indent_level

          # Show type structure
          result << "#{indent}<!-- ComplexType: #{type_name} -->" if type_name

          # Generate content based on content model
          content_result = generate_type_content(component)
          result << content_result unless content_result.empty?

          pop_type if type_name

          result.join("\n")
        end

        # Generate sample for simple type
        #
        # @return [String] XML sample
        def generate_simple_type_sample
          type_name = component["name"]
          restriction = component.at_xpath("xsd:restriction", "xsd" => XSD_NS)

          return "<!-- SimpleType: #{type_name} -->" unless restriction

          base_type = restriction["base"] || "string"
          constraints = collect_simple_constraints(restriction)

          if constraints.empty?
            base_type
          else
            "#{base_type} (#{constraints.join(', ')})"
          end
        end

        # Generate content for element
        #
        # @return [String] Content text
        def generate_element_content
          return component["fixed"] if component["fixed"]

          if component["type"]
            type_node = resolve_type
            unless type_node && type_node.name == "complexType"
              return component["type"].split(":").last
            end

            @indent_level += 1
            content = generate_type_content(type_node)
            @indent_level -= 1
            return content

          end

          # Local complex type
          if (local_type = component.at_xpath("xsd:complexType",
                                              "xsd" => XSD_NS))
            @indent_level += 1
            content = generate_type_content(local_type)
            @indent_level -= 1
            return content
          end

          # Local simple type
          if (local_type = component.at_xpath("xsd:simpleType",
                                              "xsd" => XSD_NS))
            return generate_simple_type_content(local_type)
          end

          "..."
        end

        # Generate content for complex type
        #
        # @param type [Nokogiri::XML::Element] Complex type node
        # @return [String] Type content
        def generate_type_content(type)
          # Check for complexContent
          if (complex_content = type.at_xpath("xsd:complexContent",
                                              "xsd" => XSD_NS))
            return generate_complex_content(complex_content)
          end

          # Check for simpleContent
          if (simple_content = type.at_xpath("xsd:simpleContent",
                                             "xsd" => XSD_NS))
            return generate_simple_content(simple_content)
          end

          # Process model groups
          %w[sequence choice all].each do |group_name|
            if (group = type.at_xpath("xsd:#{group_name}", "xsd" => XSD_NS))
              return generate_model_group(group)
            end
          end

          ""
        end

        # Generate complex content (extension/restriction)
        #
        # @param complex_content [Nokogiri::XML::Element] complexContent node
        # @return [String] Content
        def generate_complex_content(complex_content)
          parts = []

          if (extension = complex_content.at_xpath("xsd:extension",
                                                   "xsd" => XSD_NS))
            # Get base type content first
            base_type_name = extension["base"]
            if base_type_name
              base_type = find_type(base_type_name)
              if base_type && !circular_type?(strip_namespace(base_type_name))
                push_type(strip_namespace(base_type_name))
                parts << generate_type_content(base_type)
                pop_type
              end
            end

            # Add extension content
            %w[sequence choice all].each do |group_name|
              if (group = extension.at_xpath("xsd:#{group_name}",
                                             "xsd" => XSD_NS))
                parts << generate_model_group(group)
              end
            end
          elsif (restriction = complex_content.at_xpath("xsd:restriction",
                                                        "xsd" => XSD_NS))
            # For restriction, show only the restricted content
            %w[sequence choice all].each do |group_name|
              if (group = restriction.at_xpath("xsd:#{group_name}",
                                               "xsd" => XSD_NS))
                parts << generate_model_group(group)
              end
            end
          end

          parts.reject(&:empty?).join("\n")
        end

        # Generate simple content
        #
        # @param simple_content [Nokogiri::XML::Element] simpleContent node
        # @return [String] Content
        def generate_simple_content(simple_content)
          if (extension = simple_content.at_xpath("xsd:extension",
                                                  "xsd" => XSD_NS))
            base = extension["base"]
            return base ? strip_namespace(base) : "string"
          elsif (restriction = simple_content.at_xpath("xsd:restriction",
                                                       "xsd" => XSD_NS))
            return generate_simple_restriction(restriction)
          end

          "string"
        end

        # Generate model group (sequence/choice/all)
        #
        # @param group [Nokogiri::XML::Element] Model group node
        # @return [String] Group content
        def generate_model_group(group)
          return "" if group["maxOccurs"] == "0"

          # Check recursion depth
          @recursion_depth += 1
          if @recursion_depth > @max_recursion_depth
            @recursion_depth -= 1
            indent = "  " * @indent_level
            return "#{indent}<!-- Max recursion depth reached -->"
          end

          result = []
          indent = "  " * @indent_level
          group_name = group.name.capitalize

          # Show group indicators for choice and occurrence > 1
          show_group = group.name == "choice" ||
            (group["minOccurs"] && group["minOccurs"] != "1") ||
            (group["maxOccurs"] && group["maxOccurs"] != "1")

          if show_group
            result << "#{indent}<!-- Start #{group_name} #{format_occurs(group)} -->"
          end

          # Process child elements
          @indent_level += 1 if show_group

          group.xpath("xsd:element", "xsd" => XSD_NS).each do |elem|
            result << generate_child_element(elem)
          end

          group.xpath("xsd:group", "xsd" => XSD_NS).each do |grp_ref|
            result << generate_group_reference(grp_ref)
          end

          @indent_level -= 1 if show_group

          result << "#{indent}<!-- End #{group_name} -->" if show_group

          @recursion_depth -= 1
          result.reject(&:empty?).join("\n")
        end

        # Generate child element within model group
        #
        # @param elem [Nokogiri::XML::Element] Element node
        # @return [String] Element sample
        def generate_child_element(elem)
          return "" if elem["maxOccurs"] == "0"

          indent = "  " * @indent_level
          elem_name = elem["name"] || strip_namespace(elem["ref"] || "element")

          # Simple content with type
          if elem["type"]
            type_value = strip_namespace(elem["type"])
            occurs = format_occurs(elem)
            return "#{indent}<#{elem_name}>#{type_value}</#{elem_name}> #{occurs}".rstrip
          end

          # Complex type
          if (local_type = elem.at_xpath("xsd:complexType", "xsd" => XSD_NS))
            result = []
            result << "#{indent}<#{elem_name}>"
            @indent_level += 1
            content = generate_type_content(local_type)
            result << content unless content.empty?
            @indent_level -= 1
            occurs = format_occurs(elem)
            result << "#{indent}</#{elem_name}> #{occurs}".rstrip
            return result.join("\n")
          end

          # Simple element
          occurs = format_occurs(elem)
          "#{indent}<#{elem_name}>...</#{elem_name}> #{occurs}".rstrip
        end

        # Generate group reference
        #
        # @param grp_ref [Nokogiri::XML::Element] Group reference node
        # @return [String] Group content
        def generate_group_reference(grp_ref)
          ref_name = strip_namespace(grp_ref["ref"])

          # Check for circular group reference
          if @group_stack.include?(ref_name)
            indent = "  " * @indent_level
            return "#{indent}<!-- Circular reference to group #{ref_name} -->"
          end

          group_def = find_group(ref_name)
          return "<!-- Group reference: #{ref_name} -->" unless group_def

          # Track group to prevent circular references
          @group_stack.push(ref_name)

          # Find the model group within the group definition
          result = ""
          %w[sequence choice all].each do |group_name|
            if (group = group_def.at_xpath("xsd:#{group_name}",
                                           "xsd" => XSD_NS))
              result = generate_model_group(group)
              break
            end
          end

          @group_stack.pop
          result
        end

        # Collect attributes from type
        #
        # @param type [Nokogiri::XML::Element] Type node
        # @return [Array<String>] Attribute samples
        def collect_attributes(type)
          return [] unless type

          attrs = []

          # Check simpleContent/extension for attributes
          if (simple_content = type.at_xpath("xsd:simpleContent",
                                             "xsd" => XSD_NS))
            if (extension = simple_content.at_xpath("xsd:extension",
                                                    "xsd" => XSD_NS))
              attrs.concat(collect_direct_attributes(extension))
            elsif (restriction = simple_content.at_xpath("xsd:restriction",
                                                         "xsd" => XSD_NS))
              attrs.concat(collect_direct_attributes(restriction))
            end
          end

          # Check complexContent/extension for attributes
          if (complex_content = type.at_xpath("xsd:complexContent",
                                              "xsd" => XSD_NS))
            if (extension = complex_content.at_xpath("xsd:extension",
                                                     "xsd" => XSD_NS))
              # Get base type attributes first
              base_type_name = extension["base"]
              if base_type_name
                base_type = find_type(base_type_name)
                if base_type && !circular_type?(strip_namespace(base_type_name))
                  attrs.concat(collect_attributes(base_type))
                end
              end
              attrs.concat(collect_direct_attributes(extension))
            elsif (restriction = complex_content.at_xpath("xsd:restriction",
                                                          "xsd" => XSD_NS))
              attrs.concat(collect_direct_attributes(restriction))
            end
          end

          # Direct attributes (for types without simpleContent/complexContent)
          attrs.concat(collect_direct_attributes(type))

          attrs
        end

        # Collect direct attributes from a node
        #
        # @param node [Nokogiri::XML::Element] Node to search
        # @return [Array<String>] Attribute samples
        def collect_direct_attributes(node)
          attrs = []

          # Direct attributes
          node.xpath("xsd:attribute", "xsd" => XSD_NS).each do |attr|
            next if attr["use"] == "prohibited"

            attr_name = attr["name"] || strip_namespace(attr["ref"] || "attr")
            attr_value = attr["fixed"] || attr["type"] || "string"
            attr_value = strip_namespace(attr_value)

            use_indicator = attr["use"] == "required" ? "" : "?"
            attrs << "#{attr_name}=\"#{attr_value}\" #{use_indicator}".rstrip
          end

          # Attribute groups
          node.xpath("xsd:attributeGroup", "xsd" => XSD_NS).each do |attr_grp|
            ref_name = strip_namespace(attr_grp["ref"])
            grp_def = find_attribute_group(ref_name)
            attrs.concat(collect_attributes(grp_def)) if grp_def
          end

          attrs
        end

        # Collect simple type constraints
        #
        # @param restriction [Nokogiri::XML::Element] Restriction node
        # @return [Array<String>] Constraint descriptions
        def collect_simple_constraints(restriction)
          constraints = []

          # Enumeration
          enums = restriction.xpath("xsd:enumeration", "xsd" => XSD_NS)
          if enums.any?
            values = enums.map { |e| e["value"] }.join("|")
            constraints << "enumeration: #{values}"
          end

          # Pattern
          if (pattern = restriction.at_xpath("xsd:pattern", "xsd" => XSD_NS))
            constraints << "pattern: #{pattern['value']}"
          end

          # Length constraints
          if (min_len = restriction.at_xpath("xsd:minLength", "xsd" => XSD_NS))
            constraints << "minLength: #{min_len['value']}"
          end
          if (max_len = restriction.at_xpath("xsd:maxLength", "xsd" => XSD_NS))
            constraints << "maxLength: #{max_len['value']}"
          end

          # Range constraints
          if (min_inc = restriction.at_xpath("xsd:minInclusive",
                                             "xsd" => XSD_NS))
            constraints << "min: #{min_inc['value']}"
          end
          if (max_inc = restriction.at_xpath("xsd:maxInclusive",
                                             "xsd" => XSD_NS))
            constraints << "max: #{max_inc['value']}"
          end

          constraints
        end

        # Generate simple restriction content
        #
        # @param restriction [Nokogiri::XML::Element] Restriction node
        # @return [String] Content
        def generate_simple_restriction(restriction)
          base = strip_namespace(restriction["base"] || "string")
          constraints = collect_simple_constraints(restriction)

          if constraints.empty?
            base
          else
            "#{base} (#{constraints.join(', ')})"
          end
        end

        # Generate simple type content
        #
        # @param simple_type [Nokogiri::XML::Element] Simple type node
        # @return [String] Content
        def generate_simple_type_content(simple_type)
          if (restriction = simple_type.at_xpath("xsd:restriction",
                                                 "xsd" => XSD_NS))
            return generate_simple_restriction(restriction)
          end

          "string"
        end

        # Format occurrence information
        #
        # @param node [Nokogiri::XML::Element] Node with occurrence attributes
        # @return [String] Formatted occurrence
        def format_occurs(node)
          min = node["minOccurs"] || "1"
          max = node["maxOccurs"] || "1"

          return "" if min == "1" && max == "1"

          max = "∞" if max == "unbounded"
          "[#{min}..#{max}]"
        end

        # Add occurrence info to result
        #
        # @param result [Array<String>] Result array
        def add_occurrence_info(result)
          return if global_component?

          occurs = format_occurs(component)
          return if occurs.empty?

          result[-1] = "#{result[-1]} #{occurs}" if result.any?
        end

        # Get element tag with namespace prefix if needed
        #
        # @return [String] Element tag
        def element_tag
          component["name"] || strip_namespace(component["ref"] || "element")
        end

        # Resolve type reference to type definition
        #
        # @return [Nokogiri::XML::Element, nil] Type node
        def resolve_type
          type_ref = component["type"]
          return nil unless type_ref

          find_type(type_ref)
        end

        # Find type definition by name
        #
        # @param type_name [String] Type name
        # @return [Nokogiri::XML::Element, nil] Type node
        def find_type(type_name)
          local_name = strip_namespace(type_name)

          # Check complex types
          parser.complex_types.find { |t| t["name"] == local_name } ||
            # Check simple types
            parser.simple_types.find { |t| t["name"] == local_name }
        end

        # Find group definition by name
        #
        # @param group_name [String] Group name
        # @return [Nokogiri::XML::Element, nil] Group node
        def find_group(group_name)
          parser.groups.find { |g| g["name"] == group_name }
        end

        # Find attribute group definition by name
        #
        # @param group_name [String] Attribute group name
        # @return [Nokogiri::XML::Element, nil] Attribute group node
        def find_attribute_group(group_name)
          parser.attribute_groups.find { |ag| ag["name"] == group_name }
        end

        # Check if element has complex type
        #
        # @return [Boolean]
        def has_complex_type?
          return true if component.at_xpath("xsd:complexType", "xsd" => XSD_NS)
          return false unless component["type"]

          type_node = resolve_type
          type_node && type_node.name == "complexType"
        end

        # Check if element is prohibited
        #
        # @return [Boolean]
        def prohibited_element?
          component["maxOccurs"] == "0"
        end

        # Check if component is global
        #
        # @return [Boolean]
        def global_component?
          component.parent&.name == "schema"
        end

        # Get target namespace
        #
        # @return [String, nil] Target namespace
        def target_namespace
          schema = component.document.root
          schema["targetNamespace"] if schema
        end

        # Strip namespace prefix from name
        #
        # @param name [String] Qualified name
        # @return [String] Local name
        def strip_namespace(name)
          name.to_s.split(":").last
        end

        # Check if type is circular
        #
        # @param type_name [String] Type name
        # @return [Boolean]
        def circular_type?(type_name)
          return false unless type_name

          @type_stack.include?(type_name)
        end

        # Push type onto stack
        #
        # @param type_name [String] Type name
        def push_type(type_name)
          @type_stack.push(type_name) if type_name
        end

        # Pop type from stack
        def pop_type
          @type_stack.pop
        end
      end
    end
  end
end
