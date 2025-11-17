# frozen_string_literal: true

require "spec_helper"

RSpec.describe Xseed::Svg::Symbol::SchemaSymbol do
  let(:xsd_node) do
    double(
      "XsdNode",
      name: "schema",
      namespace: "http://www.w3.org/2001/XMLSchema",
      namespace_prefix: "xs",
      attributes: {},
      annotation: nil
    )
  end

  let(:schema_symbol) do
    described_class.new(
      name: "UserSchema",
      type: "schema",
      xsd_node: xsd_node,
      namespace: "http://example.com/user"
    )
  end

  describe "#initialize" do
    it "inherits from Base" do
      expect(schema_symbol).to be_a(Xseed::Svg::Symbol::Base)
    end

    it "stores namespace" do
      expect(schema_symbol.namespace).to eq("http://example.com/user")
    end

    it "accepts nil namespace" do
      symbol = described_class.new(
        name: "Schema",
        type: "schema",
        xsd_node: xsd_node,
        namespace: nil
      )
      expect(symbol.namespace).to be_nil
    end
  end

  describe "#calculate_bounds" do
    it "calculates width based on name and namespace" do
      # Width should accommodate both name and namespace
      expect(schema_symbol.width).to be >= Xseed::Svg::Symbol::Base::MIN_WIDTH
    end

    it "provides extra width for namespace display" do
      # Schema with namespace should be wider than simple symbol
      simple_node = double(
        "SimpleNode",
        name: "schema",
        namespace: nil,
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      simple_symbol = described_class.new(
        name: "S",
        type: "schema",
        xsd_node: simple_node,
        namespace: nil
      )

      expect(schema_symbol.width).to be > simple_symbol.width
    end

    it "uses MAX_HEIGHT for schema boxes" do
      expect(schema_symbol.height).to eq(Xseed::Svg::Symbol::Base::MAX_HEIGHT)
    end
  end

  describe "#calculate_connection_points" do
    it "has only output connection point (no input)" do
      output_points = schema_symbol.connection_points.select { |p| p[:type] == :output }
      input_points = schema_symbol.connection_points.select { |p| p[:type] == :input }

      expect(output_points.size).to eq(1)
      expect(input_points.size).to eq(0)
    end

    it "places output point at bottom center" do
      output = schema_symbol.output_point
      expect(output[:x]).to eq(schema_symbol.width / 2)
      expect(output[:y]).to eq(schema_symbol.height)
    end

    it "has no input point (root symbol)" do
      expect(schema_symbol.input_point).to be_nil
    end
  end

  describe "schema as root symbol" do
    it "represents schema root" do
      expect(schema_symbol.type).to eq("schema")
    end

    it "is suitable as root element" do
      # Schema symbols should not have input points since they're always root
      expect(schema_symbol.input_point).to be_nil
    end
  end
end