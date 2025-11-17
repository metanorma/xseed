# frozen_string_literal: true

require "spec_helper"
require "xseed/svg/symbol/element_root_symbol"

RSpec.describe Xseed::Svg::Symbol::ElementRootSymbol do
  let(:mock_xsd_node) do
    instance_double(
      "XsdNode",
      name: "element",
      attributes: {},
      respond_to?: true
    )
  end

  describe "#initialize" do
    it "creates an element root symbol with element name" do
      symbol = described_class.new(
        element_name: "Order",
        xsd_node: mock_xsd_node
      )

      expect(symbol.element_name).to eq("Order")
      expect(symbol.name).to eq("Order")
      expect(symbol.type).to eq("element_root")
    end

    it "stores target namespace when provided" do
      symbol = described_class.new(
        element_name: "Order",
        target_namespace: "http://example.com/ns",
        xsd_node: mock_xsd_node
      )

      expect(symbol.target_namespace).to eq("http://example.com/ns")
    end

    it "handles nil target namespace" do
      symbol = described_class.new(
        element_name: "Order",
        target_namespace: nil,
        xsd_node: mock_xsd_node
      )

      expect(symbol.target_namespace).to be_nil
    end
  end

  describe "#bounding_box" do
    it "is sized like elements not schema" do
      symbol = described_class.new(
        element_name: "Order",
        xsd_node: mock_xsd_node
      )

      # Should use DEFAULT_HEIGHT (46) not schema height
      expect(symbol.height).to eq(Xseed::Svg::Symbol::Base::DEFAULT_HEIGHT)
      expect(symbol.height).to eq(46)
    end

    it "calculates width based on element name" do
      symbol = described_class.new(
        element_name: "Order",
        xsd_node: mock_xsd_node
      )

      # Width should be at least MIN_WIDTH (153)
      expect(symbol.width).to be >= Xseed::Svg::Symbol::Base::MIN_WIDTH
    end

    it "accounts for target namespace in width calculation" do
      short_symbol = described_class.new(
        element_name: "Order",
        xsd_node: mock_xsd_node
      )

      long_symbol = described_class.new(
        element_name: "Order",
        target_namespace: "http://example.com/very/long/namespace",
        xsd_node: mock_xsd_node
      )

      # Symbol with namespace should be wider
      expect(long_symbol.width).to be > short_symbol.width
    end
  end

  describe "#connection_points" do
    it "has both input and output connection points" do
      symbol = described_class.new(
        element_name: "Order",
        xsd_node: mock_xsd_node
      )

      expect(symbol.connection_points.length).to eq(2)
    end

    it "has input point at top center" do
      symbol = described_class.new(
        element_name: "Order",
        xsd_node: mock_xsd_node
      )

      input_point = symbol.input_point
      expect(input_point).not_to be_nil
      expect(input_point[:type]).to eq(:input)
      expect(input_point[:x]).to eq(symbol.width / 2)
      expect(input_point[:y]).to eq(0)
    end

    it "has output point at bottom center" do
      symbol = described_class.new(
        element_name: "Order",
        xsd_node: mock_xsd_node
      )

      output_point = symbol.output_point
      expect(output_point).not_to be_nil
      expect(output_point[:type]).to eq(:output)
      expect(output_point[:x]).to eq(symbol.width / 2)
      expect(output_point[:y]).to eq(symbol.height)
    end
  end

  describe "comparison with ElementSymbol and SchemaSymbol" do
    let(:element_symbol) do
      Xseed::Svg::Symbol::ElementSymbol.new(
        name: "Order",
        type: "element",
        xsd_node: mock_xsd_node
      )
    end

    let(:schema_symbol) do
      Xseed::Svg::Symbol::SchemaSymbol.new(
        name: "Order",
        type: "schema",
        xsd_node: mock_xsd_node,
        namespace: "http://example.com/ns"
      )
    end

    let(:element_root_symbol) do
      described_class.new(
        element_name: "Order",
        target_namespace: "http://example.com/ns",
        xsd_node: mock_xsd_node
      )
    end

    it "has same height as ElementSymbol" do
      expect(element_root_symbol.height).to eq(element_symbol.height)
    end

    it "has both input and output points like ElementSymbol" do
      expect(element_root_symbol.connection_points.length).to eq(
        element_symbol.connection_points.length
      )
      expect(element_root_symbol.input_point).not_to be_nil
      expect(element_root_symbol.output_point).not_to be_nil
    end

    it "does not behave like SchemaSymbol (which has no input point)" do
      expect(schema_symbol.input_point).to be_nil
      expect(element_root_symbol.input_point).not_to be_nil
    end
  end
end