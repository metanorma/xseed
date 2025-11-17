# frozen_string_literal: true

require "ostruct"
require "fileutils"
require_relative "layout_engine"
require_relative "svg_renderer"
require_relative "symbol_factory"
require_relative "../parser/xsd_parser"
require_relative "simplification/simplification_config"
require_relative "simplification/pattern_registry"
require_relative "simplification/type_reference_cache"
require_relative "symbol/collapsed_symbol"

module Xseed
  module Svg
    # Orchestrates the complete SVG generation workflow
    # Combines XSD parsing, symbol tree building, layout, and rendering
    class SvgGenerator
      attr_reader :xsd_file_path, :target_element

      def initialize(xsd_file_path, simplification_mode: nil, element: nil)
        @xsd_file_path = xsd_file_path
        @target_element = element
        @element_stack = [] # Track elements being processed for loop detection
        @group_stack = [] # Track groups being processed for recursion detection
        @group_expansion_count = Hash.new(0) # Track expansion count per group
        @element_expansion_count = Hash.new(0) # Track expansion count per element

        # Initialize simplification components
        @simplification_config = Simplification::SimplificationConfig.new(
          mode: simplification_mode
        )
        @pattern_registry = Simplification::PatternRegistry.new
        @type_cache = Simplification::TypeReferenceCache.new(
          always_inline: !element.nil?
        )

        validate_file!
      end

      # Generates complete SVG diagram from XSD file
      # @return [String] SVG XML as string
      def generate
        # Parse XSD file
        parser = Parser::XsdParser.new(@xsd_file_path)

        # Build symbol tree from parser
        root_symbol = build_symbol_tree(parser)

        # Apply layout to position symbols
        layout_engine = LayoutEngine.new(root_symbol)
        layout_engine.layout
        viewport = layout_engine.viewport

        # Render to SVG
        renderer = SvgRenderer.new(root_symbol, viewport: viewport)
        renderer.render
      rescue StandardError => e
        raise GenerationError, "Failed to generate SVG: #{e.message}"
      end

      # Generates SVG and writes to file
      # @param output_path [String] Path to output SVG file
      def generate_file(output_path)
        # Ensure output directory exists
        output_dir = File.dirname(output_path)
        FileUtils.mkdir_p(output_dir)

        # Generate and write SVG
        svg_content = generate
        File.write(output_path, svg_content)

        output_path
      end

      # Returns list of all global element names in the schema
      # @return [Array<String>] Array of element names
      def all_element_names
        parser = Parser::XsdParser.new(@xsd_file_path)
        schema = parser.schema

        element_names = []

        # Handle parsed schema object
        if schema.respond_to?(:elements) && schema.elements.is_a?(Array)
          schema.elements.each do |element|
            name = extract_element_name(element)
            # Skip non-element nodes
            next if name.nil? || name == "annotation"
            next if element.respond_to?(:name) && element.name != "element"

            element_names << name
          end
        end

        # Handle Nokogiri XML document
        if schema.respond_to?(:xpath)
          elements = schema.xpath(
            "xs:element[@name]",
            "xs" => "http://www.w3.org/2001/XMLSchema"
          )
          elements.each do |element|
            name = element["name"]
            element_names << name if name
          end
        end

        element_names.uniq.sort
      end

      private

      # Validates that the XSD file exists and is valid
      def validate_file!
        unless File.exist?(@xsd_file_path)
          raise ArgumentError, "File not found: #{@xsd_file_path}"
        end

        unless @xsd_file_path.end_with?(".xsd")
          raise ArgumentError, "File must be an XSD file: #{@xsd_file_path}"
        end

        # Try to read and parse as XML to validate
        begin
          doc = Nokogiri::XML(File.read(@xsd_file_path), &:strict)
          unless doc.root && doc.root.name == "schema"
            raise ArgumentError,
                  "Invalid XSD file: root element must be 'schema'"
          end
        rescue Nokogiri::XML::SyntaxError => e
          raise ArgumentError, "Invalid XSD file: #{e.message}"
        end
      end

      # Builds symbol tree from parsed XSD
      # @param parser [Parser::XsdParser] The XSD parser instance
      # @return [Symbol::Base] Root symbol of the tree
      def build_symbol_tree(parser)
        # Check if single-element mode is enabled
        if @target_element
          return build_element_root_tree(parser, @target_element)
        end

        # Get the schema document from parser
        schema = parser.schema

        # Extract targetNamespace from parser
        target_namespace = parser.target_namespace

        # Create root symbol for schema
        root = create_schema_root(schema)

        # Process ONLY top-level elements (following XSDVI model)
        # Do NOT process standalone complex types separately
        if schema.respond_to?(:elements) && schema.elements
          schema.elements.each do |element|
            # Skip annotation and other non-element nodes
            element_name = extract_element_name(element)
            next if element_name.nil? || element_name == "annotation"

            # Skip complexType definitions - they should only be inlined via references
            next if element.respond_to?(:name) && element.name == "complexType"
            next if element.respond_to?(:[]) && element["name"] && element.name == "complexType"

            # Skip simpleType definitions - they should only be inlined via references
            next if element.respond_to?(:name) && element.name == "simpleType"
            next if element.respond_to?(:[]) && element["name"] && element.name == "simpleType"

            # Skip group definitions - they should only be expanded via references
            next if element.respond_to?(:name) && element.name == "group"
            next if element.respond_to?(:[]) && element["name"] && element.name == "group"

            element_symbol = create_element_symbol(element, target_namespace)
            root.add_child(element_symbol) if element_symbol
          end
        end

        # If no children were added, create a placeholder
        if root.children.empty?
          placeholder = create_placeholder_symbol
          root.add_child(placeholder)
        end

        root
      end

      # Builds symbol tree for a single element (single-element mode)
      # @param parser [Parser::XsdParser] The XSD parser instance
      # @param element_name [String] The name of the target element
      # @return [Symbol::ElementRootSymbol] Root symbol for the element
      def build_element_root_tree(parser, element_name)
        schema = parser.schema
        target_namespace = parser.target_namespace

        # Find the global element
        element_node = find_global_element(schema, element_name)
        raise ArgumentError, "Element '#{element_name}' not found in schema" unless element_node

        # Create ElementRootSymbol as the root
        root = Symbol::ElementRootSymbol.new(
          element_name: element_name,
          target_namespace: target_namespace,
          xsd_node: element_node
        )

        # Process the element's content (type definitions, etc.)
        process_element_content(root, element_node, depth: 0)

        root
      end

      # Finds a global element in the schema by name
      # @param schema [Object] The schema object
      # @param element_name [String] The name of the element to find
      # @return [Nokogiri::XML::Element, nil] The element node or nil
      def find_global_element(schema, element_name)
        return nil unless element_name

        # Handle parsed schema object
        if schema.respond_to?(:elements) && schema.elements.is_a?(Array)
          schema.elements.each do |element|
            name = extract_element_name(element)
            return element if name == element_name
          end
        end

        # Handle Nokogiri XML document
        if schema.respond_to?(:xpath)
          element = schema.xpath(
            "xs:element[@name='#{element_name}']",
            "xs" => "http://www.w3.org/2001/XMLSchema"
          ).first
          return element if element
        end

        nil
      end

      # Extracts element name from an element node
      def extract_element_name(element)
        if element.respond_to?(:[])
          element["name"]&.to_s || element.name
        elsif element.respond_to?(:name)
          element.name
        end
      end

      # Creates element symbol from XSD element
      def create_element_symbol(element, target_namespace = nil, depth: 0)
        # Extract name from element, with fallback
        element_name = extract_element_name(element)

        return nil if element_name.nil? || element_name == "element"

        # DEPTH LIMITING: Check if depth exceeds max depth
        if @simplification_config.should_limit_depth?(depth)
          # Create collapsed symbol instead of expanding further
          return create_collapsed_element_symbol(element, depth)
        end

        # LOOP DETECTION: Check if element is already in processing stack
        element_id = element_identifier(element)
        current_count = @element_expansion_count[element_id]

        if @element_stack.include?(element_id) && current_count >= 2
          # Create loop symbol after 2+ expansions
          return create_loop_symbol(element_name)
        end

        # Register element pattern for future simplification decisions
        @pattern_registry.register_element_pattern(element_name)

        # Add element to stack before processing
        @element_stack.push(element_id)
        @element_expansion_count[element_id] += 1

        element_symbol = Symbol::ElementSymbol.new(
          name: element_name,
          type: "element",
          xsd_node: element,
          target_namespace: target_namespace
        )

        # Recursively process element's content with incremented depth
        process_element_content(element_symbol, element, depth: depth)

        # Remove element from stack after processing
        @element_stack.pop
        @element_expansion_count[element_id] -= 1

        element_symbol
      end

      # Creates root schema symbol
      def create_schema_root(schema)
        target_namespace = if schema.respond_to?(:target_namespace)
                             schema.target_namespace
                           end

        name = target_namespace || "Schema"

        Symbol::SchemaSymbol.new(
          name: name,
          type: "schema",
          xsd_node: schema,
          namespace: target_namespace
        )
      end

      # Processes all content within an element (complex type, attributes, etc.)
      def process_element_content(element_symbol, element, depth: 0)
        # Process inline complex type
        if element.respond_to?(:complex_type) && element.complex_type
          process_complex_type_content(element_symbol, element.complex_type, depth: depth)
        end

        # Handle inline complexType for Nokogiri::XML::Element
        if element.is_a?(Nokogiri::XML::Element)
          complex_type_node = element.at_xpath(
            'xs:complexType',
            'xs' => 'http://www.w3.org/2001/XMLSchema'
          )
          if complex_type_node
            # Get target namespace for child elements
            target_ns = element_symbol.respond_to?(:target_namespace) ? element_symbol.target_namespace : nil
            process_complex_type_xml(element_symbol, complex_type_node, target_ns, depth: depth)
          end
        end

        # Process type reference (if element references a named type)
        if element.respond_to?(:[]) && element["type"]
          # Resolve and expand the type reference
          type_name = element["type"]

          # Skip built-in XML Schema types
          return if type_name.start_with?("xs:")

          # Register complex type usage
          @pattern_registry.register_complex_type(type_name) unless type_name.start_with?("xs:")

          # Check if we should inline or reference this type
          if @type_cache.should_inline?(type_name)
            # First usage: inline the full type content
            resolved_type = resolve_type_reference(type_name, element)

            if resolved_type
              # Mark this type as expanded
              element_id = element_identifier(element)
              @type_cache.mark_expanded(type_name, element_id)

              # Get target namespace for child elements
              target_ns = element_symbol.respond_to?(:target_namespace) ? element_symbol.target_namespace : nil
              # Process the resolved XML node structure
              process_complex_type_xml(element_symbol, resolved_type, target_ns, depth: depth)
            end
          else
            # Subsequent usage: create a type reference symbol
            type_ref_symbol = create_type_reference_symbol(type_name, element)
            element_symbol.add_child(type_ref_symbol) if type_ref_symbol
          end
        end

        # Process attributes at element level if present
        process_attributes(element_symbol, element) if element.respond_to?(:attributes)
      end

      # Processes complex type content from a raw XML node (for resolved type references)
      # @param parent_symbol [Symbol::Base] The parent symbol to add children to
      # @param complex_type_node [Nokogiri::XML::Element] The complexType XML node
      # @param target_namespace [String, nil] The target namespace for child elements
      # @param depth [Integer] Current depth in the tree (for depth limiting)
      def process_complex_type_xml(parent_symbol, complex_type_node, target_namespace = nil, depth: 0)
        # Increment depth for children
        child_depth = depth + 1

        # At group recursion boundary (depth 2), skip creating sequence symbol
        # but still process contents to allow group references to create LOOP
        at_group_boundary = @group_stack.length == 2

        # Process sequence
        sequence = complex_type_node.at_xpath(
          'xs:sequence',
          'xs' => 'http://www.w3.org/2001/XMLSchema'
        )
        if sequence
          if at_group_boundary
            # Skip sequence symbol, attach contents directly to parent
            # Process elements directly
            elements = sequence.xpath(
              'xs:element',
              'xs' => 'http://www.w3.org/2001/XMLSchema'
            )
            elements.each do |elem|
              element_symbol = create_element_symbol(elem, target_namespace, depth: child_depth)
              parent_symbol.add_child(element_symbol) if element_symbol
            end

            # Process group references directly (will create LOOP)
            process_group_references(parent_symbol, sequence, depth: child_depth)
          else
            # Normal sequence processing with symbol
            sequence_symbol = Symbol::SequenceSymbol.new(
              name: 'sequence',
              type: 'sequence',
              xsd_node: sequence
            )
            parent_symbol.add_child(sequence_symbol)

            # Process elements in sequence
            elements = sequence.xpath(
              'xs:element',
              'xs' => 'http://www.w3.org/2001/XMLSchema'
            )
            elements.each do |elem|
              element_symbol = create_element_symbol(elem, target_namespace, depth: child_depth)
              sequence_symbol.add_child(element_symbol) if element_symbol
            end

            # Process group references in sequence
            process_group_references(sequence_symbol, sequence, depth: child_depth)
          end
        end

        # Process choice
        choice = complex_type_node.at_xpath(
          'xs:choice',
          'xs' => 'http://www.w3.org/2001/XMLSchema'
        )
        if choice
          choice_symbol = Symbol::ChoiceSymbol.new(
            name: 'choice',
            type: 'choice',
            xsd_node: choice
          )
          parent_symbol.add_child(choice_symbol)

          # Process elements in choice
          elements = choice.xpath(
            'xs:element',
            'xs' => 'http://www.w3.org/2001/XMLSchema'
          )
          elements.each do |elem|
            element_symbol = create_element_symbol(elem, target_namespace, depth: child_depth)
            choice_symbol.add_child(element_symbol) if element_symbol
          end

          # Process group references in choice
          process_group_references(choice_symbol, choice, depth: child_depth)
        end

        # Process all
        all_group = complex_type_node.at_xpath(
          'xs:all',
          'xs' => 'http://www.w3.org/2001/XMLSchema'
        )
        if all_group
          all_symbol = Symbol::AllSymbol.new(
            name: 'all',
            type: 'all',
            xsd_node: all_group
          )
          parent_symbol.add_child(all_symbol)

          # Process elements in all
          elements = all_group.xpath(
            'xs:element',
            'xs' => 'http://www.w3.org/2001/XMLSchema'
          )
          elements.each do |elem|
            element_symbol = create_element_symbol(elem, target_namespace, depth: child_depth)
            all_symbol.add_child(element_symbol) if element_symbol
          end

          # Process group references in all
          process_group_references(all_symbol, all_group, depth: child_depth)
        end

        # Process attributes from complex type
        attributes = complex_type_node.xpath(
          'xs:attribute',
          'xs' => 'http://www.w3.org/2001/XMLSchema'
        )
        attributes.each do |attr|
          attr_symbol = create_attribute_symbol(attr)
          parent_symbol.add_child(attr_symbol) if attr_symbol
        end
      end

      # Resolves a type reference to its complex type definition
      # @param type_name [String] The type reference (e.g., "tns:PersonType" or "xs:string")
      # @param context_element [Nokogiri::XML::Element] The element containing the reference
      # @return [Nokogiri::XML::Element, nil] The complex type node or nil
      def resolve_type_reference(type_name, context_element)
        return nil unless type_name

        # Extract local name from qualified name (strip namespace prefix)
        local_name = type_name.include?(":") ? type_name.split(":").last : type_name

        # Skip built-in XML Schema types (xs:string, xs:integer, etc.)
        return nil if type_name.start_with?("xs:")

        # Get the schema root to search for the type
        schema_root = context_element.document.root
        return nil unless schema_root

        # Search for complex type with matching name
        complex_type = schema_root.at_xpath(
          "xs:complexType[@name='#{local_name}']",
          "xs" => "http://www.w3.org/2001/XMLSchema"
        )

        return complex_type if complex_type

        # Could also search for simple types here if needed
        # For now, only handling complex types
        nil
      end

      # Creates a loop symbol for circular references
      def create_loop_symbol(target_name)
        mock_node = OpenStruct.new(
          name: "loop",
          annotation: nil,
          namespace: nil,
          namespace_prefix: nil
        )

        Symbol::LoopSymbol.new(
          name: "loop",
          target_name: target_name,
          xsd_node: mock_node
        )
      end

      # Creates a type reference symbol for repeated type usage
      def create_type_reference_symbol(type_name, element)
        # Get reference location if this type was already expanded
        reference_location = @type_cache.get_reference(type_name)

        mock_node = OpenStruct.new(
          name: type_name,
          annotation: nil,
          namespace: nil,
          namespace_prefix: nil
        )

        Symbol::TypeReferenceSymbol.new(
          name: type_name,
          type_name: type_name,
          xsd_node: mock_node,
          reference_location: reference_location
        )
      end

      # Creates a collapsed symbol representation for complex structures
      def create_collapsed_element_symbol(element, depth)
        element_name = extract_element_name(element)
        collapsed_name = "#{element_name} (+#{depth})"
        mock_node = OpenStruct.new(
          name: collapsed_name,
          annotation: nil,
          namespace: nil,
          namespace_prefix: nil
        )

        Symbol::CollapsedSymbol.new(
          name: collapsed_name,
          type: "element",
          xsd_node: mock_node
        )
      end

      # Generates unique identifier for element (for loop detection)
      def element_identifier(element)
        # Use name + object_id to uniquely identify this element
        name = if element.respond_to?(:[])
                 element["name"]&.to_s || element.name
               elsif element.respond_to?(:name)
                 element.name
               else
                 "unknown"
               end

        "#{name}_#{element.object_id}"
      end

      # Process complex type content (sequence, choice, etc.)
      def process_complex_type_content(parent_symbol, complex_type, depth: 0)
        # Increment depth for children
        child_depth = depth + 1

        # Process sequence
        if complex_type.respond_to?(:sequence) && complex_type.sequence
          sequence = complex_type.sequence
          process_sequence(parent_symbol, sequence, depth: child_depth)
        end

        # Process choice
        if complex_type.respond_to?(:choice) && complex_type.choice
          choice = complex_type.choice
          process_choice(parent_symbol, choice, depth: child_depth)
        end

        # Process all
        if complex_type.respond_to?(:all) && complex_type.all
          all_group = complex_type.all
          process_all(parent_symbol, all_group, depth: child_depth)
        end

        # Process attributes from complex type
        process_attributes(parent_symbol, complex_type)
      end

      # Processes attributes and anyAttribute wildcards
      def process_attributes(parent_symbol, node)
        # Process regular attributes
        if node.respond_to?(:attributes) && node.attributes.is_a?(Array)
          node.attributes.each do |attr|
            attr_symbol = create_attribute_symbol(attr)
            parent_symbol.add_child(attr_symbol) if attr_symbol
          end
        end

        # Process anyAttribute wildcard
        return unless node.respond_to?(:any_attribute) && node.any_attribute

        any_attr_symbol = create_any_attribute_symbol(node.any_attribute)
        parent_symbol.add_child(any_attr_symbol) if any_attr_symbol
      end

      # Creates attribute symbol from XSD attribute
      def create_attribute_symbol(attribute)
        attr_name = if attribute.respond_to?(:[])
                      attribute["name"]&.to_s || "attribute"
                    elsif attribute.respond_to?(:name)
                      attribute.name || "attribute"
                    else
                      "attribute"
                    end

        return nil if attr_name == "attribute" && !attribute.respond_to?(:name)

        Symbol::AttributeSymbol.new(
          name: attr_name,
          type: "attribute",
          xsd_node: attribute
        )
      end

      # Creates anyAttribute wildcard symbol
      def create_any_attribute_symbol(any_attribute)
        Symbol::AnyAttributeSymbol.new(
          xsd_node: any_attribute
        )
      end

      # Processes sequence compositor
      def process_sequence(parent_symbol, sequence, depth: 0)
        sequence_symbol = Symbol::SequenceSymbol.new(
          name: "sequence",
          type: "sequence",
          xsd_node: sequence
        )

        parent_symbol.add_child(sequence_symbol)

        # Process elements in sequence - recursively expand them
        if sequence.respond_to?(:elements) && sequence.elements
          sequence.elements.each do |element|
            element_symbol = create_element_symbol(element, nil, depth: depth)
            sequence_symbol.add_child(element_symbol) if element_symbol
          end
        end

        # Process group references in sequence
        process_group_references(sequence_symbol, sequence, depth: depth)

        # Process nested groups in sequence
        process_nested_groups(sequence_symbol, sequence, depth: depth)
      end

      # Processes choice compositor
      def process_choice(parent_symbol, choice, depth: 0)
        choice_symbol = Symbol::ChoiceSymbol.new(
          name: "choice",
          type: "choice",
          xsd_node: choice
        )

        parent_symbol.add_child(choice_symbol)

        # Process elements in choice - recursively expand them
        if choice.respond_to?(:elements) && choice.elements
          choice.elements.each do |element|
            element_symbol = create_element_symbol(element, nil, depth: depth)
            choice_symbol.add_child(element_symbol) if element_symbol
          end
        end

        # Process group references in choice
        process_group_references(choice_symbol, choice, depth: depth)

        # Process nested groups in choice
        process_nested_groups(choice_symbol, choice, depth: depth)
      end

      # Processes all compositor
      def process_all(parent_symbol, all_group, depth: 0)
        all_symbol = Symbol::AllSymbol.new(
          name: "all",
          type: "all",
          xsd_node: all_group
        )

        parent_symbol.add_child(all_symbol)

        # Process elements in all - recursively expand them
        if all_group.respond_to?(:elements) && all_group.elements
          all_group.elements.each do |element|
            element_symbol = create_element_symbol(element, nil, depth: depth)
            all_symbol.add_child(element_symbol) if element_symbol
          end
        end

        # Process group references in all
        process_group_references(all_symbol, all_group, depth: depth)

        # Process nested groups in all
        process_nested_groups(all_symbol, all_group, depth: depth)
      end

      # Processes group references within compositors
      # Expands group definitions inline
      def process_group_references(parent_symbol, compositor_node, depth: 0)
        # Handle both parsed objects and XML nodes
        group_refs = []

        if compositor_node.respond_to?(:groups) && compositor_node.groups
          group_refs = compositor_node.groups
        elsif compositor_node.is_a?(Nokogiri::XML::Element)
          # Find group references in XML node
          group_refs = compositor_node.xpath(
            'xs:group[@ref]',
            'xs' => 'http://www.w3.org/2001/XMLSchema'
          )
        end

        group_refs.each do |group_ref|
          # Get the ref attribute
          ref_name = if group_ref.respond_to?(:[])
                       group_ref['ref']
                     elsif group_ref.respond_to?(:ref)
                       group_ref.ref
                     end

          next unless ref_name

          # Resolve the group definition first
          group_def = resolve_group_reference(ref_name, compositor_node)
          next unless group_def

          # Check for recursion BEFORE expanding - count how many times this group is already in the stack
          stack_count = @group_stack.count(ref_name)
          if stack_count > 1
            # Create loop symbol on second reference (third occurrence)
            loop_symbol = create_loop_symbol(ref_name)
            parent_symbol.add_child(loop_symbol)
            next
          end

          # Track this group to detect recursion
          @group_stack.push(ref_name)
          @group_expansion_count[ref_name] += 1

          # Expand the group contents inline
          expand_group_contents(parent_symbol, group_def, depth: depth)

          # Remove from stack after processing
          @group_stack.pop
          @group_expansion_count[ref_name] -= 1
        end
      end

      # Resolves a group reference to its definition
      # @param ref_name [String] The group reference name
      # @param context_node [Object] The node containing the reference
      # @return [Nokogiri::XML::Element, nil] The group definition node
      def resolve_group_reference(ref_name, context_node)
        return nil unless ref_name

        # Get the schema root to search for the group
        schema_root = if context_node.respond_to?(:document)
                        context_node.document.root
                      elsif context_node.respond_to?(:parent)
                        # Walk up to find schema root
                        node = context_node
                        node = node.parent while node.respond_to?(:parent) && node.parent
                        node
                      end

        return nil unless schema_root

        # Search for group definition with matching name
        group_def = schema_root.at_xpath(
          "xs:group[@name='#{ref_name}']",
          "xs" => "http://www.w3.org/2001/XMLSchema"
        )

        group_def
      end

      # Expands group contents inline into the parent
      # @param parent_symbol [Symbol::Base] The parent to add children to
      # @param group_def [Nokogiri::XML::Element] The group definition
      # @param depth [Integer] Current depth in the tree
      def expand_group_contents(parent_symbol, group_def, depth: 0)
        # A group definition contains a compositor (sequence/choice/all)
        # Extract and process that compositor

        # Look for sequence in group
        sequence = group_def.at_xpath(
          'xs:sequence',
          'xs' => 'http://www.w3.org/2001/XMLSchema'
        )
        if sequence
          process_sequence_xml(parent_symbol, sequence, depth: depth)
          return
        end

        # Look for choice in group
        choice = group_def.at_xpath(
          'xs:choice',
          'xs' => 'http://www.w3.org/2001/XMLSchema'
        )
        if choice
          process_choice_xml(parent_symbol, choice, depth: depth)
          return
        end

        # Look for all in group
        all_group = group_def.at_xpath(
          'xs:all',
          'xs' => 'http://www.w3.org/2001/XMLSchema'
        )
        return unless all_group

        process_all_xml(parent_symbol, all_group, depth: depth)
      end

      # Processes a sequence from XML node (for group expansion)
      def process_sequence_xml(parent_symbol, sequence_node, depth: 0)
        # Always create sequence symbol for group expansions
        sequence_symbol = Symbol::SequenceSymbol.new(
          name: 'sequence',
          type: 'sequence',
          xsd_node: sequence_node
        )
        parent_symbol.add_child(sequence_symbol)

        # Process elements in sequence
        elements = sequence_node.xpath(
          'xs:element',
          'xs' => 'http://www.w3.org/2001/XMLSchema'
        )
        elements.each do |elem|
          element_symbol = create_element_symbol(elem, nil, depth: depth)
          sequence_symbol.add_child(element_symbol) if element_symbol
        end

        # Process group references in this sequence
        process_group_references(sequence_symbol, sequence_node, depth: depth)
      end

      # Processes a choice from XML node (for group expansion)
      def process_choice_xml(parent_symbol, choice_node, depth: 0)
        choice_symbol = Symbol::ChoiceSymbol.new(
          name: 'choice',
          type: 'choice',
          xsd_node: choice_node
        )
        parent_symbol.add_child(choice_symbol)

        # Process elements in choice
        elements = choice_node.xpath(
          'xs:element',
          'xs' => 'http://www.w3.org/2001/XMLSchema'
        )
        elements.each do |elem|
          element_symbol = create_element_symbol(elem, nil, depth: depth)
          choice_symbol.add_child(element_symbol) if element_symbol
        end

        # Process group references in this choice
        process_group_references(choice_symbol, choice_node, depth: depth)
      end

      # Processes an all group from XML node (for group expansion)
      def process_all_xml(parent_symbol, all_node, depth: 0)
        all_symbol = Symbol::AllSymbol.new(
          name: 'all',
          type: 'all',
          xsd_node: all_node
        )
        parent_symbol.add_child(all_symbol)

        # Process elements in all
        elements = all_node.xpath(
          'xs:element',
          'xs' => 'http://www.w3.org/2001/XMLSchema'
        )
        elements.each do |elem|
          element_symbol = create_element_symbol(elem, nil, depth: depth)
          all_symbol.add_child(element_symbol) if element_symbol
        end

        # Process group references in this all group
        process_group_references(all_symbol, all_node, depth: depth)
      end

      # Processes nested group references (sequence/choice/all within groups)
      def process_nested_groups(parent_symbol, group, depth: 0)
        # Process nested sequences
        if group.respond_to?(:sequences) && group.sequences
          group.sequences.each do |seq|
            process_sequence(parent_symbol, seq, depth: depth)
          end
        end

        # Process nested choices
        if group.respond_to?(:choices) && group.choices
          group.choices.each do |ch|
            process_choice(parent_symbol, ch, depth: depth)
          end
        end

        # Process nested all groups
        return unless group.respond_to?(:alls) && group.alls

        group.alls.each do |all_g|
          process_all(parent_symbol, all_g, depth: depth)
        end
      end

      # Creates placeholder symbol for empty schemas
      def create_placeholder_symbol
        mock_node = OpenStruct.new(
          name: "Empty Schema",
          annotation: nil,
          namespace: nil,
          namespace_prefix: nil
        )

        Symbol::ElementSymbol.new(
          name: "Empty Schema",
          type: "element",
          xsd_node: mock_node
        )
      end
    end

    # Custom error for SVG generation failures
    class GenerationError < StandardError; end
  end
end
