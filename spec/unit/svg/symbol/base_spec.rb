# frozen_string_literal: true

require "spec_helper"

RSpec.describe Xseed::Svg::Symbol::Base do
  let(:xsd_node) do
    double(
      "XsdNode",
      name: "testElement",
      namespace: "http://example.com",
      attributes: {},
      annotation: nil
    )
  end

  let(:symbol) do
    described_class.new(
      name: "TestSymbol",
      type: "element",
      xsd_node: xsd_node
    )
  end

  describe "#initialize" do
    it "initializes with name" do
      expect(symbol.name).to eq("TestSymbol")
    end

    it "initializes with type" do
      expect(symbol.type).to eq("element")
    end

    it "initializes with xsd_node" do
      expect(symbol.xsd_node).to eq(xsd_node)
    end

    it "initializes children as empty array" do
      expect(symbol.children).to eq([])
    end

    it "initializes parent as nil" do
      expect(symbol.parent).to be_nil
    end

    it "calculates initial bounds" do
      expect(symbol.width).to be > 0
      expect(symbol.height).to be > 0
    end

    it "raises error without name" do
      expect do
        described_class.new(type: "element", xsd_node: xsd_node)
      end.to raise_error(ArgumentError)
    end

    it "raises error without type" do
      expect do
        described_class.new(name: "Test", xsd_node: xsd_node)
      end.to raise_error(ArgumentError)
    end

    it "raises error without xsd_node" do
      expect do
        described_class.new(name: "Test", type: "element")
      end.to raise_error(ArgumentError)
    end
  end

  describe "#bounding_box" do
    it "returns hash with position and dimensions" do
      box = symbol.bounding_box
      expect(box).to be_a(Hash)
      expect(box).to have_key(:x)
      expect(box).to have_key(:y)
      expect(box).to have_key(:width)
      expect(box).to have_key(:height)
    end

    it "returns current position" do
      symbol.x = 100
      symbol.y = 200
      box = symbol.bounding_box
      expect(box[:x]).to eq(100)
      expect(box[:y]).to eq(200)
    end

    it "returns current dimensions" do
      symbol.width = 150
      symbol.height = 75
      box = symbol.bounding_box
      expect(box[:width]).to eq(150)
      expect(box[:height]).to eq(75)
    end
  end

  describe "#position management" do
    describe "#x, #y" do
      it "allows reading x coordinate" do
        symbol.x = 50
        expect(symbol.x).to eq(50)
      end

      it "allows reading y coordinate" do
        symbol.y = 100
        expect(symbol.y).to eq(100)
      end

      it "defaults x to 0" do
        expect(symbol.x).to eq(0)
      end

      it "defaults y to 0" do
        expect(symbol.y).to eq(0)
      end
    end

    describe "#width, #height" do
      it "allows setting width" do
        symbol.width = 200
        expect(symbol.width).to eq(200)
      end

      it "allows setting height" do
        symbol.height = 150
        expect(symbol.height).to eq(150)
      end
    end

    describe "#set_position" do
      it "sets both x and y coordinates" do
        symbol.set_position(150, 250)
        expect(symbol.x).to eq(150)
        expect(symbol.y).to eq(250)
      end
    end
  end

  describe "parent/child relationships" do
    let(:child_xsd_node) do
      double(
        "ChildXsdNode",
        name: "childElement",
        namespace: "http://example.com",
        attributes: {},
        annotation: nil
      )
    end

    let(:child_symbol) do
      described_class.new(
        name: "ChildSymbol",
        type: "element",
        xsd_node: child_xsd_node
      )
    end

    describe "#add_child" do
      it "adds child to children array" do
        symbol.add_child(child_symbol)
        expect(symbol.children).to include(child_symbol)
      end

      it "sets child's parent to self" do
        symbol.add_child(child_symbol)
        expect(child_symbol.parent).to eq(symbol)
      end

      it "allows multiple children" do
        child2_xsd_node = double(
          "Child2XsdNode",
          name: "child2Element",
          namespace: "http://example.com",
          attributes: {},
          annotation: nil
        )
        child2 = described_class.new(
          name: "Child2",
          type: "element",
          xsd_node: child2_xsd_node
        )

        symbol.add_child(child_symbol)
        symbol.add_child(child2)

        expect(symbol.children.size).to eq(2)
        expect(symbol.children).to include(child_symbol, child2)
      end

      it "returns the child symbol" do
        result = symbol.add_child(child_symbol)
        expect(result).to eq(child_symbol)
      end
    end

    describe "#remove_child" do
      it "removes child from children array" do
        symbol.add_child(child_symbol)
        symbol.remove_child(child_symbol)
        expect(symbol.children).not_to include(child_symbol)
      end

      it "sets child's parent to nil" do
        symbol.add_child(child_symbol)
        symbol.remove_child(child_symbol)
        expect(child_symbol.parent).to be_nil
      end

      it "returns the removed child" do
        symbol.add_child(child_symbol)
        result = symbol.remove_child(child_symbol)
        expect(result).to eq(child_symbol)
      end

      it "returns nil if child not found" do
        other_child = described_class.new(
          name: "Other",
          type: "element",
          xsd_node: child_xsd_node
        )
        result = symbol.remove_child(other_child)
        expect(result).to be_nil
      end
    end

    describe "#parent=" do
      it "sets parent reference" do
        child_symbol.parent = symbol
        expect(child_symbol.parent).to eq(symbol)
      end

      it "allows nil parent" do
        child_symbol.parent = symbol
        child_symbol.parent = nil
        expect(child_symbol.parent).to be_nil
      end
    end
  end

  describe "#documentation" do
    context "when xsd_node has annotation" do
      let(:annotation_text) { "This is a test element" }
      let(:xsd_node_with_annotation) do
        double(
          "XsdNodeWithAnnotation",
          name: "testElement",
          namespace: "http://example.com",
          attributes: {},
          annotation: double("Annotation", documentation: annotation_text)
        )
      end

      let(:symbol_with_doc) do
        described_class.new(
          name: "TestWithDoc",
          type: "element",
          xsd_node: xsd_node_with_annotation
        )
      end

      it "returns documentation text" do
        expect(symbol_with_doc.documentation).to eq(annotation_text)
      end
    end

    context "when xsd_node has no annotation" do
      it "returns nil" do
        expect(symbol.documentation).to be_nil
      end
    end
  end

  describe "#namespace" do
    it "returns namespace from xsd_node" do
      expect(symbol.namespace).to eq("http://example.com")
    end
  end

  describe "#qualified_name" do
    it "returns namespace prefix and name" do
      expect(symbol.qualified_name).to include("TestSymbol")
    end

    context "with namespace prefix" do
      let(:xsd_node_with_prefix) do
        double(
          "XsdNode",
          name: "testElement",
          namespace: "http://example.com",
          namespace_prefix: "ex",
          attributes: {},
          annotation: nil
        )
      end

      let(:symbol_with_prefix) do
        described_class.new(
          name: "TestSymbol",
          type: "element",
          xsd_node: xsd_node_with_prefix
        )
      end

      it "includes prefix in qualified name" do
        expect(symbol_with_prefix.qualified_name).to eq("ex:TestSymbol")
      end
    end
  end

  describe "#leaf?" do
    it "returns true when has no children" do
      expect(symbol.leaf?).to be true
    end

    it "returns false when has children" do
      child = described_class.new(
        name: "Child",
        type: "element",
        xsd_node: xsd_node
      )
      symbol.add_child(child)
      expect(symbol.leaf?).to be false
    end
  end

  describe "#root?" do
    it "returns true when has no parent" do
      expect(symbol.root?).to be true
    end

    it "returns false when has parent" do
      parent = described_class.new(
        name: "Parent",
        type: "complexType",
        xsd_node: xsd_node
      )
      symbol.parent = parent
      expect(symbol.root?).to be false
    end
  end

  describe "#depth" do
    it "returns 0 for root symbol" do
      expect(symbol.depth).to eq(0)
    end

    it "returns depth from root" do
      parent = described_class.new(
        name: "Parent",
        type: "complexType",
        xsd_node: xsd_node
      )
      grandparent = described_class.new(
        name: "Grandparent",
        type: "schema",
        xsd_node: xsd_node
      )

      parent.parent = grandparent
      symbol.parent = parent

      expect(symbol.depth).to eq(2)
    end
  end

  describe "#ancestors" do
    it "returns empty array for root" do
      expect(symbol.ancestors).to eq([])
    end

    it "returns array of ancestor symbols" do
      parent = described_class.new(
        name: "Parent",
        type: "complexType",
        xsd_node: xsd_node
      )
      grandparent = described_class.new(
        name: "Grandparent",
        type: "schema",
        xsd_node: xsd_node
      )

      parent.parent = grandparent
      symbol.parent = parent

      expect(symbol.ancestors).to eq([parent, grandparent])
    end
  end

  describe "#descendants" do
    it "returns empty array when no children" do
      expect(symbol.descendants).to eq([])
    end

    it "returns all descendant symbols" do
      child1 = described_class.new(
        name: "Child1",
        type: "element",
        xsd_node: xsd_node
      )
      child2 = described_class.new(
        name: "Child2",
        type: "element",
        xsd_node: xsd_node
      )
      grandchild = described_class.new(
        name: "Grandchild",
        type: "element",
        xsd_node: xsd_node
      )

      symbol.add_child(child1)
      symbol.add_child(child2)
      child1.add_child(grandchild)

      descendants = symbol.descendants
      expect(descendants).to include(child1, child2, grandchild)
      expect(descendants.size).to eq(3)
    end
  end
end
