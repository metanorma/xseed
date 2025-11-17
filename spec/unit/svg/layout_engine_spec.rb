# frozen_string_literal: true

require "spec_helper"
require "xseed/svg/layout_engine"
require "xseed/svg/symbol/base"
require "xseed/svg/symbol/element_symbol"
require "xseed/svg/symbol/complex_type_symbol"
require "xseed/svg/symbol/sequence_symbol"

RSpec.describe Xseed::Svg::LayoutEngine do
  let(:mock_xsd_node) do
    double("XsdNode",
           annotation: nil,
           namespace: nil,
           namespace_prefix: nil)
  end

  let(:root_symbol) do
    Xseed::Svg::Symbol::ElementSymbol.new(
      name: "root",
      type: "element",
      xsd_node: mock_xsd_node
    )
  end

  let(:layout_engine) { described_class.new(root_symbol) }

  describe "#initialize" do
    it "initializes with a root symbol" do
      expect(layout_engine.instance_variable_get(:@root)).to eq(root_symbol)
    end

    it "initializes viewport dimensions to nil" do
      expect(layout_engine.viewport).to eq({ width: 0, height: 0 })
    end
  end

  describe "#layout" do
    context "with a single root symbol" do
      it "positions the root symbol at root coordinates" do
        layout_engine.layout

        expect(root_symbol.x).to eq(described_class::ROOT_X)
        expect(root_symbol.y).to eq(described_class::ROOT_Y)
      end

      it "calculates viewport to accommodate root symbol" do
        layout_engine.layout
        viewport = layout_engine.viewport

        expect(viewport[:width]).to be > root_symbol.width
        expect(viewport[:height]).to be > root_symbol.height
      end
    end

    context "with parent-child hierarchy" do
      let(:child1) do
        Xseed::Svg::Symbol::ElementSymbol.new(
          name: "child1",
          type: "element",
          xsd_node: mock_xsd_node
        )
      end

      let(:child2) do
        Xseed::Svg::Symbol::ElementSymbol.new(
          name: "child2",
          type: "element",
          xsd_node: mock_xsd_node
        )
      end

      before do
        root_symbol.add_child(child1)
        root_symbol.add_child(child2)
      end

      it "positions children below parent with vertical spacing" do
        layout_engine.layout

        # First child shares parent's Y position (XSDVI behavior)
        expect(child1.y).to eq(root_symbol.y)
        # Second child is positioned with VERTICAL_SPACING from first child's Y position
        expect(child2.y).to eq(child1.y + described_class::VERTICAL_SPACING)
      end

      it "indents children horizontally from parent" do
        layout_engine.layout

        expected_child_x = root_symbol.x + root_symbol.width + described_class::HORIZONTAL_SPACING
        expect(child1.x).to eq(expected_child_x)
        expect(child2.x).to eq(expected_child_x)
      end

      it "spaces children vertically from each other" do
        layout_engine.layout

        # Siblings are spaced by VERTICAL_SPACING only (XSDVI behavior)
        expected_spacing = described_class::VERTICAL_SPACING
        expect(child2.y - child1.y).to eq(expected_spacing)
      end
    end

    context "with nested hierarchy (grandchildren)" do
      let(:child) do
        Xseed::Svg::Symbol::ComplexTypeSymbol.new(
          name: "child",
          type: "complexType",
          xsd_node: mock_xsd_node
        )
      end

      let(:grandchild) do
        Xseed::Svg::Symbol::ElementSymbol.new(
          name: "grandchild",
          type: "element",
          xsd_node: mock_xsd_node
        )
      end

      before do
        root_symbol.add_child(child)
        child.add_child(grandchild)
      end

      it "positions grandchildren relative to their parent" do
        layout_engine.layout

        expected_grandchild_x = child.x + child.width + described_class::HORIZONTAL_SPACING
        # Grandchild shares its parent's Y position (first child behavior)
        expected_grandchild_y = child.y

        expect(grandchild.x).to eq(expected_grandchild_x)
        expect(grandchild.y).to eq(expected_grandchild_y)
      end

      it "calculates correct viewport for nested structure" do
        layout_engine.layout
        viewport = layout_engine.viewport

        # Viewport should accommodate all nested elements
        expect(viewport[:width]).to be > grandchild.x + grandchild.width
        expect(viewport[:height]).to be > grandchild.y + grandchild.height
      end
    end

    context "with multiple children at different depths" do
      let(:child1) do
        Xseed::Svg::Symbol::SequenceSymbol.new(
          name: "sequence1",
          type: "sequence",
          xsd_node: mock_xsd_node
        )
      end

      let(:child2) do
        Xseed::Svg::Symbol::ElementSymbol.new(
          name: "element2",
          type: "element",
          xsd_node: mock_xsd_node
        )
      end

      let(:grandchild1) do
        Xseed::Svg::Symbol::ElementSymbol.new(
          name: "grandchild1",
          type: "element",
          xsd_node: mock_xsd_node
        )
      end

      let(:grandchild2) do
        Xseed::Svg::Symbol::ElementSymbol.new(
          name: "grandchild2",
          type: "element",
          xsd_node: mock_xsd_node
        )
      end

      before do
        root_symbol.add_child(child1)
        root_symbol.add_child(child2)
        child1.add_child(grandchild1)
        child1.add_child(grandchild2)
      end

      it "positions all symbols without overlaps" do
        layout_engine.layout

        symbols = [root_symbol, child1, child2, grandchild1, grandchild2]

        # Check no overlaps
        symbols.combination(2).each do |sym1, sym2|
          # Calculate bounding boxes
          box1 = {
            left: sym1.x,
            right: sym1.x + sym1.width,
            top: sym1.y,
            bottom: sym1.y + sym1.height
          }
          box2 = {
            left: sym2.x,
            right: sym2.x + sym2.width,
            top: sym2.y,
            bottom: sym2.y + sym2.height
          }

          # Check if boxes overlap
          overlaps = !(box1[:right] <= box2[:left] ||
                      box2[:right] <= box1[:left] ||
                      box1[:bottom] <= box2[:top] ||
                      box2[:bottom] <= box1[:top])

          expect(overlaps).to be(false),
                              "#{sym1.name} and #{sym2.name} should not overlap"
        end
      end
    end
  end

  describe "#viewport" do
    it "returns viewport with width and height" do
      viewport = layout_engine.viewport

      expect(viewport).to have_key(:width)
      expect(viewport).to have_key(:height)
    end

    context "after layout calculation" do
      before { layout_engine.layout }

      it "includes margins in viewport calculation" do
        viewport = layout_engine.viewport

        expect(viewport[:width]).to be >=
                                    root_symbol.x + root_symbol.width + described_class::MARGIN
        expect(viewport[:height]).to be >=
                                     root_symbol.y + root_symbol.height + described_class::MARGIN
      end
    end
  end

  describe "constants" do
    it "defines HORIZONTAL_SPACING" do
      expect(described_class::HORIZONTAL_SPACING).to be_a(Integer)
      expect(described_class::HORIZONTAL_SPACING).to be > 0
    end

    it "defines VERTICAL_SPACING" do
      expect(described_class::VERTICAL_SPACING).to be_a(Integer)
      expect(described_class::VERTICAL_SPACING).to be > 0
    end

    it "defines MARGIN" do
      expect(described_class::MARGIN).to be_a(Integer)
      expect(described_class::MARGIN).to be > 0
    end
  end

  describe "collision detection" do
    let(:child1) do
      Xseed::Svg::Symbol::ElementSymbol.new(
        name: "wide_child1",
        type: "element",
        xsd_node: mock_xsd_node
      ).tap { |s| s.instance_variable_set(:@width, 300) }
    end

    let(:child2) do
      Xseed::Svg::Symbol::ElementSymbol.new(
        name: "wide_child2",
        type: "element",
        xsd_node: mock_xsd_node
      ).tap { |s| s.instance_variable_set(:@width, 300) }
    end

    before do
      root_symbol.add_child(child1)
      root_symbol.add_child(child2)
    end

    it "avoids overlaps even with wide symbols" do
      layout_engine.layout

      # Child2 should be positioned below child1 with proper spacing
      expect(child2.y).to be >= child1.y + child1.height
    end
  end
end
