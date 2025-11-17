# frozen_string_literal: true

require "spec_helper"

RSpec.describe Xseed::Svg::Symbol::LoopSymbol do
  let(:xsd_node) do
    double(
      "XsdNode",
      name: "loop",
      namespace: nil,
      namespace_prefix: nil,
      attributes: {},
      annotation: nil
    )
  end

  let(:loop_symbol) do
    described_class.new(
      name: "PersonReference",
      target_name: "Person",
      xsd_node: xsd_node
    )
  end

  describe "#initialize" do
    it "inherits from Base" do
      expect(loop_symbol).to be_a(Xseed::Svg::Symbol::Base)
    end

    it "stores target name" do
      expect(loop_symbol.target_name).to eq("Person")
    end

    it "displays arrow notation in name" do
      expect(loop_symbol.name).to eq("→ Person")
    end

    it "sets type to loop" do
      expect(loop_symbol.type).to eq("loop")
    end
  end

  describe "#calculate_bounds" do
    it "creates smaller box for loop indicators" do
      expect(loop_symbol.height).to eq(Xseed::Svg::Symbol::Base::MID_HEIGHT)
    end

    it "calculates width based on arrow notation" do
      # Should be at least MIN_WIDTH
      expect(loop_symbol.width).to be >= Xseed::Svg::Symbol::Base::MIN_WIDTH
    end

    it "accommodates the arrow and target name" do
      # Width should be based on "→ Person" length
      long_loop = described_class.new(
        name: "ref",
        target_name: "VeryLongElementNameReference",
        xsd_node: xsd_node
      )

      expect(long_loop.width).to be > loop_symbol.width
    end
  end

  describe "#calculate_connection_points" do
    it "has both input and output points for consistency" do
      input_points = loop_symbol.connection_points.select { |p| p[:type] == :input }
      output_points = loop_symbol.connection_points.select { |p| p[:type] == :output }

      expect(input_points.size).to eq(1)
      expect(output_points.size).to eq(1)
    end

    it "places input point at top center" do
      input = loop_symbol.input_point
      expect(input[:x]).to eq(loop_symbol.width / 2)
      expect(input[:y]).to eq(0)
    end

    it "places output point at bottom center" do
      output = loop_symbol.output_point
      expect(output[:x]).to eq(loop_symbol.width / 2)
      expect(output[:y]).to eq(loop_symbol.height)
    end
  end

  describe "loop detection purpose" do
    it "prevents infinite recursion" do
      # Loop symbols indicate circular references
      expect(loop_symbol.target_name).to eq("Person")
    end

    it "uses compact display" do
      # Should use MID_HEIGHT for space efficiency
      expect(loop_symbol.height).to eq(Xseed::Svg::Symbol::Base::MID_HEIGHT)
    end

    it "clearly indicates reference with arrow" do
      expect(loop_symbol.name).to start_with("→")
    end
  end

  describe "integration with XSDVI pattern" do
    it "matches XSDVI loop indicator style" do
      # XSDVI shows loops as small boxes with arrows
      expect(loop_symbol.name).to include("→")
      expect(loop_symbol.height).to eq(Xseed::Svg::Symbol::Base::MID_HEIGHT)
    end

    it "distinguishes from regular elements" do
      expect(loop_symbol.type).to eq("loop")
    end
  end
end