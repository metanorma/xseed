# frozen_string_literal: true

require_relative "symbol"

module Xseed
  module Svg
    # Factory for creating SVG symbols from XSD nodes
    # Handles mapping between XSD node types and symbol classes
    class SymbolFactory
      # Creates a symbol from an XSD node
      # @param xsd_node [Object] The XSD node to create a symbol from
      # @return [Symbol::Base, nil] The created symbol or nil if type not recognized
      def self.create(xsd_node)
        return nil unless xsd_node

        node_type = xsd_node.name
        symbol_class = Symbol::SYMBOL_CLASSES[node_type]

        return nil unless symbol_class

        # Extract name from node attributes or use node name
        name = extract_name(xsd_node)

        symbol_class.new(
          name: name,
          type: node_type,
          xsd_node: xsd_node
        )
      end

      # Builds a complete symbol tree from XSD parser output
      # @param parser [Xseed::Parser::XsdParser] The XSD parser instance
      # @return [Hash] Hash containing root symbols by type
      def self.build_tree(_parser)
        {
          elements: [],
          types: [],
          groups: [],
          attributes: []
        }

        # Process parser output and create symbols
        # This is a placeholder - actual implementation depends on parser API
        # For now, return empty tree structure
      end

      # Creates symbol hierarchy from element data
      # @param element_data [Hash] Element data from parser
      # @param parent_symbol [Symbol::Base, nil] Parent symbol
      # @return [Symbol::ElementSymbol] Created element symbol
      def self.create_element(element_data, parent_symbol = nil)
        xsd_node = create_xsd_node(element_data)
        element = Symbol::ElementSymbol.new(
          name: element_data[:name],
          type: "element",
          xsd_node: xsd_node
        )

        parent_symbol&.add_child(element)

        # Process children if present
        element_data[:children]&.each do |child_data|
          create_element(child_data, element)
        end

        element
      end

      # Creates symbol from complex type data
      # @param type_data [Hash] Type data from parser
      # @return [Symbol::ComplexTypeSymbol] Created complex type symbol
      def self.create_complex_type(type_data)
        xsd_node = create_xsd_node(type_data)
        complex_type = Symbol::ComplexTypeSymbol.new(
          name: type_data[:name],
          type: "complexType",
          xsd_node: xsd_node
        )

        # Set content model if specified
        if type_data[:content_model]
          complex_type.content_model = type_data[:content_model]
        end

        # Add attributes if present
        type_data[:attributes]&.each do |attr_data|
          attribute = create_attribute(attr_data)
          complex_type.add_attribute(attribute)
        end

        # Add child elements if present
        type_data[:elements]&.each do |elem_data|
          element = create_element(elem_data)
          complex_type.add_child(element)
        end

        complex_type
      end

      # Creates symbol from simple type data
      # @param type_data [Hash] Type data from parser
      # @return [Symbol::SimpleTypeSymbol] Created simple type symbol
      def self.create_simple_type(type_data)
        xsd_node = create_xsd_node(type_data)
        simple_type = Symbol::SimpleTypeSymbol.new(
          name: type_data[:name],
          type: "simpleType",
          xsd_node: xsd_node
        )

        # Set variety if specified
        simple_type.variety = type_data[:variety] if type_data[:variety]

        # Set base type if specified
        simple_type.base_type = type_data[:base_type] if type_data[:base_type]

        # Add facets if present
        type_data[:facets]&.each do |facet|
          simple_type.add_facet(facet)
        end

        simple_type
      end

      # Creates symbol from attribute data
      # @param attr_data [Hash] Attribute data from parser
      # @return [Symbol::AttributeSymbol] Created attribute symbol
      def self.create_attribute(attr_data)
        xsd_node = create_xsd_node(attr_data)
        Symbol::AttributeSymbol.new(
          name: attr_data[:name],
          type: "attribute",
          xsd_node: xsd_node
        )
      end

      # Creates a sequence group symbol
      # @param children [Array] Child symbols
      # @return [Symbol::SequenceSymbol] Created sequence symbol
      def self.create_sequence(children = [])
        xsd_node = create_xsd_node(name: "sequence")
        sequence = Symbol::SequenceSymbol.new(
          name: "sequence",
          type: "sequence",
          xsd_node: xsd_node
        )

        children.each { |child| sequence.add_child(child) }
        sequence
      end

      # Creates a choice group symbol
      # @param children [Array] Child symbols
      # @return [Symbol::ChoiceSymbol] Created choice symbol
      def self.create_choice(children = [])
        xsd_node = create_xsd_node(name: "choice")
        choice = Symbol::ChoiceSymbol.new(
          name: "choice",
          type: "choice",
          xsd_node: xsd_node
        )

        children.each { |child| choice.add_child(child) }
        choice
      end

      # Creates an all group symbol
      # @param children [Array] Child symbols
      # @return [Symbol::AllSymbol] Created all symbol
      def self.create_all(children = [])
        xsd_node = create_xsd_node(name: "all")
        all_group = Symbol::AllSymbol.new(
          name: "all",
          type: "all",
          xsd_node: xsd_node
        )

        children.each { |child| all_group.add_child(child) }
        all_group
      end

      # Creates an anyAttribute symbol
      # @param xsd_node [Object] XSD node data
      # @return [Symbol::AnyAttributeSymbol] Created anyAttribute symbol
      def self.create_any_attribute(xsd_node)
        Symbol::AnyAttributeSymbol.new(xsd_node: xsd_node)
      end

      # Creates a key identity constraint symbol
      # @param name [String] Key name
      # @param xsd_node [Object] XSD node data
      # @return [Symbol::KeySymbol] Created key symbol
      def self.create_key(name, xsd_node)
        Symbol::KeySymbol.new(name: name, xsd_node: xsd_node)
      end

      # Creates a unique identity constraint symbol
      # @param name [String] Unique constraint name
      # @param xsd_node [Object] XSD node data
      # @return [Symbol::UniqueSymbol] Created unique symbol
      def self.create_unique(name, xsd_node)
        Symbol::UniqueSymbol.new(name: name, xsd_node: xsd_node)
      end

      # Creates a keyref identity constraint symbol
      # @param name [String] Keyref name
      # @param xsd_node [Object] XSD node data
      # @return [Symbol::KeyrefSymbol] Created keyref symbol
      def self.create_keyref(name, xsd_node)
        Symbol::KeyrefSymbol.new(name: name, xsd_node: xsd_node)
      end

      # Private helper methods

      # Extracts name from XSD node
      # @param xsd_node [Object] The XSD node
      # @return [String] The extracted name
      def self.extract_name(xsd_node)
        if xsd_node.respond_to?(:attributes) && xsd_node.attributes.is_a?(Hash)
          xsd_node.attributes["name"] || xsd_node.attributes["ref"] || xsd_node.name
        else
          xsd_node.name
        end
      end
      private_class_method :extract_name

      # Creates a mock XSD node from hash data
      # @param data [Hash] Data to create node from
      # @return [Object] Mock XSD node
      def self.create_xsd_node(data = {})
        data = {} unless data.is_a?(Hash)

        # Create a simple struct to act as XSD node
        OpenStruct.new(
          name: data[:name] || data["name"] || "unknown",
          namespace: data[:namespace] || data["namespace"],
          namespace_prefix: data[:namespace_prefix] || data["namespace_prefix"],
          attributes: data[:attributes] || data["attributes"] || {},
          annotation: data[:annotation] || data["annotation"]
        )
      end
      private_class_method :create_xsd_node
    end
  end
end
