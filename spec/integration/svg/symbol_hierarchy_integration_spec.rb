# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Symbol Hierarchy Integration" do
  let(:simple_xsd_node) do
    double(
      "SimpleXsdNode",
      name: "Person",
      namespace: "http://example.com",
      namespace_prefix: nil,
      attributes: {},
      annotation: nil
    )
  end

  describe "Building symbol trees" do
    it "creates a simple element hierarchy" do
      root = Xseed::Svg::Symbol::ElementSymbol.new(
        name: "Person",
        type: "element",
        xsd_node: simple_xsd_node
      )

      name_node = double(
        "NameNode",
        name: "name",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      name_element = Xseed::Svg::Symbol::ElementSymbol.new(
        name: "name",
        type: "element",
        xsd_node: name_node
      )

      root.add_child(name_element)

      expect(root.children).to include(name_element)
      expect(name_element.parent).to eq(root)
      expect(root.depth).to eq(0)
      expect(name_element.depth).to eq(1)
    end

    it "creates a complex type with elements and attributes" do
      type_node = double(
        "TypeNode",
        name: "PersonType",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      complex_type = Xseed::Svg::Symbol::ComplexTypeSymbol.new(
        name: "PersonType",
        type: "complexType",
        xsd_node: type_node
      )

      # Add element
      elem_node = double(
        "ElementNode",
        name: "fullName",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      element = Xseed::Svg::Symbol::ElementSymbol.new(
        name: "fullName",
        type: "element",
        xsd_node: elem_node
      )
      complex_type.add_child(element)

      # Add attribute
      attr_node = double(
        "AttributeNode",
        name: "id",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: { "use" => "required" },
        annotation: nil
      )
      attribute = Xseed::Svg::Symbol::AttributeSymbol.new(
        name: "id",
        type: "attribute",
        xsd_node: attr_node
      )
      complex_type.add_attribute(attribute)

      expect(complex_type.children.size).to eq(1)
      expect(complex_type.attributes.size).to eq(1)
      expect(complex_type.has_attributes?).to be true
    end

    it "creates a sequence group with multiple children" do
      seq_node = double(
        "SequenceNode",
        name: "sequence",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      sequence = Xseed::Svg::Symbol::SequenceSymbol.new(
        name: "sequence",
        type: "sequence",
        xsd_node: seq_node
      )

      %w[firstName lastName email].each do |elem_name|
        elem_node = double(
          "#{elem_name}Node",
          name: elem_name,
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: {},
          annotation: nil
        )
        element = Xseed::Svg::Symbol::ElementSymbol.new(
          name: elem_name,
          type: "element",
          xsd_node: elem_node
        )
        sequence.add_child(element)
      end

      expect(sequence.children.size).to eq(3)
      expect(sequence.ordered?).to be true
      sequence.children.each do |child|
        expect(child.parent).to eq(sequence)
      end
    end
  end

  describe "Parent/child relationships" do
    it "maintains bidirectional relationships" do
      parent_node = double(
        "ParentNode",
        name: "parent",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      parent = Xseed::Svg::Symbol::Base.new(
        name: "parent",
        type: "element",
        xsd_node: parent_node
      )

      child_node = double(
        "ChildNode",
        name: "child",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      child = Xseed::Svg::Symbol::Base.new(
        name: "child",
        type: "element",
        xsd_node: child_node
      )

      parent.add_child(child)

      expect(child.parent).to eq(parent)
      expect(parent.children).to include(child)
      expect(child.root?).to be false
      expect(parent.root?).to be true
    end

    it "handles deep hierarchies correctly" do
      nodes = (0..5).map do |i|
        double(
          "Node#{i}",
          name: "level#{i}",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: {},
          annotation: nil
        )
      end

      symbols = nodes.map.with_index do |node, i|
        Xseed::Svg::Symbol::Base.new(
          name: "level#{i}",
          type: "element",
          xsd_node: node
        )
      end

      # Build hierarchy
      symbols.each_cons(2) do |parent, child|
        parent.add_child(child)
      end

      expect(symbols[0].depth).to eq(0)
      expect(symbols[5].depth).to eq(5)
      expect(symbols[5].ancestors.size).to eq(5)
      expect(symbols[0].descendants.size).to eq(5)
    end

    it "supports removing children" do
      parent_node = double(
        "ParentNode",
        name: "parent",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      parent = Xseed::Svg::Symbol::Base.new(
        name: "parent",
        type: "element",
        xsd_node: parent_node
      )

      child_node = double(
        "ChildNode",
        name: "child",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      child = Xseed::Svg::Symbol::Base.new(
        name: "child",
        type: "element",
        xsd_node: child_node
      )

      parent.add_child(child)
      expect(parent.children).to include(child)

      parent.remove_child(child)
      expect(parent.children).not_to include(child)
      expect(child.parent).to be_nil
    end
  end

  describe "Bounding box calculations" do
    it "calculates dimensions based on content" do
      elem_node = double(
        "ElementNode",
        name: "VeryLongElementNameForTesting",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      element = Xseed::Svg::Symbol::ElementSymbol.new(
        name: "VeryLongElementNameForTesting",
        type: "element",
        xsd_node: elem_node
      )

      box = element.bounding_box
      expect(box[:width]).to be > 120
      expect(box[:height]).to be > 0
    end

    it "allows manual positioning" do
      elem_node = double(
        "ElementNode",
        name: "element",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      element = Xseed::Svg::Symbol::ElementSymbol.new(
        name: "element",
        type: "element",
        xsd_node: elem_node
      )

      element.set_position(100, 200)
      box = element.bounding_box
      expect(box[:x]).to eq(100)
      expect(box[:y]).to eq(200)
    end

    it "adjusts complex type dimensions for children" do
      type_node = double(
        "TypeNode",
        name: "ComplexType",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      complex_type = Xseed::Svg::Symbol::ComplexTypeSymbol.new(
        name: "ComplexType",
        type: "complexType",
        xsd_node: type_node
      )

      initial_height = complex_type.height

      # Add multiple children
      5.times do |i|
        elem_node = double(
          "ElementNode#{i}",
          name: "element#{i}",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: {},
          annotation: nil
        )
        element = Xseed::Svg::Symbol::ElementSymbol.new(
          name: "element#{i}",
          type: "element",
          xsd_node: elem_node
        )
        complex_type.add_child(element)
      end

      # Trigger recalculation
      complex_type.send(:calculate_bounds)

      expect(complex_type.height).to be > initial_height
    end
  end

  describe "Symbol-specific behaviors" do
    it "handles element occurrences correctly" do
      optional_node = double(
        "OptionalNode",
        name: "optional",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: { "minOccurs" => "0", "maxOccurs" => "unbounded" },
        annotation: nil
      )
      optional = Xseed::Svg::Symbol::ElementSymbol.new(
        name: "optional",
        type: "element",
        xsd_node: optional_node
      )

      expect(optional.optional?).to be true
      expect(optional.repeatable?).to be true
      expect(optional.min_occurs).to eq(0)
      expect(optional.max_occurs).to eq(Float::INFINITY)
    end

    it "resolves simple type facets" do
      simple_node = double(
        "SimpleNode",
        name: "CodeType",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      simple_type = Xseed::Svg::Symbol::SimpleTypeSymbol.new(
        name: "CodeType",
        type: "simpleType",
        xsd_node: simple_node
      )

      simple_type.add_facet(type: :pattern, value: "[A-Z]{3}")
      simple_type.add_facet(type: :enumeration, value: "USD")
      simple_type.add_facet(type: :enumeration, value: "EUR")

      expect(simple_type.has_facets?).to be true
      expect(simple_type.pattern_value).to eq("[A-Z]{3}")
      expect(simple_type.enumeration_values).to eq(%w[USD EUR])
    end

    it "handles group references" do
      group_node = double(
        "GroupNode",
        name: "PersonGroup",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: { "ref" => "common:PersonGroup" },
        annotation: nil
      )
      group = Xseed::Svg::Symbol::GroupSymbol.new(
        name: "PersonGroup",
        type: "group",
        xsd_node: group_node
      )

      expect(group.is_reference?).to be true
      expect(group.ref).to eq("common:PersonGroup")
    end
  end

  describe "Performance" do
    it "builds moderate-sized symbol tree efficiently" do
      start_time = Time.now

      # Create a tree with 100 nodes
      root_node = double(
        "RootNode",
        name: "root",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      root = Xseed::Svg::Symbol::ComplexTypeSymbol.new(
        name: "root",
        type: "complexType",
        xsd_node: root_node
      )

      100.times do |i|
        elem_node = double(
          "ElementNode#{i}",
          name: "element#{i}",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: {},
          annotation: nil
        )
        element = Xseed::Svg::Symbol::ElementSymbol.new(
          name: "element#{i}",
          type: "element",
          xsd_node: elem_node
        )
        root.add_child(element)
      end

      elapsed = Time.now - start_time

      expect(root.children.size).to eq(100)
      expect(elapsed).to be < 1.0 # Should complete in under 1 second
    end
  end
end
