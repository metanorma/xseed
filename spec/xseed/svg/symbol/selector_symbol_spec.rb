# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../lib/xseed/svg/symbol/selector_symbol"

RSpec.describe Xseed::Svg::Symbol::SelectorSymbol do
  describe "#initialize" do
    context "with xpath attribute in hash format" do
      let(:xsd_node) { { "xpath" => "./ns:element" } }
      let(:symbol) { described_class.new(xsd_node: xsd_node) }

      it "creates a selector symbol with correct name" do
        expect(symbol.name).to eq("selector: ./ns:element")
      end

      it "sets type to 'selector'" do
        expect(symbol.type).to eq("selector")
      end

      it "extracts xpath correctly" do
        expect(symbol.xpath).to eq("./ns:element")
      end

      it "uses compact height" do
        expect(symbol.height).to eq(described_class::MID_HEIGHT)
      end
    end

    context "with xpath attribute as symbol" do
      let(:xsd_node) { { xpath: "@id" } }
      let(:symbol) { described_class.new(xsd_node: xsd_node) }

      it "extracts xpath from symbol key" do
        expect(symbol.xpath).to eq("@id")
      end
    end

    context "with xpath method" do
      let(:xsd_node) do
        double("xsd_node", xpath: "./parent/child")
      end
      let(:symbol) { described_class.new(xsd_node: xsd_node) }

      it "extracts xpath from method" do
        expect(symbol.xpath).to eq("./parent/child")
      end
    end

    context "with xpath in attributes hash" do
      let(:xsd_node) do
        double("xsd_node", attributes: { "xpath" => ".//descendant" })
      end
      let(:symbol) { described_class.new(xsd_node: xsd_node) }

      it "extracts xpath from attributes" do
        expect(symbol.xpath).to eq(".//descendant")
      end
    end

    context "without xpath" do
      let(:xsd_node) { {} }
      let(:symbol) { described_class.new(xsd_node: xsd_node) }

      it "defaults to '.'" do
        expect(symbol.xpath).to eq(".")
      end
    end
  end

  describe "#calculate_bounds" do
    let(:xsd_node) { { "xpath" => "./element" } }
    let(:symbol) { described_class.new(xsd_node: xsd_node) }

    it "calculates width based on name length" do
      expect(symbol.width).to be >= described_class::MIN_WIDTH
    end

    it "uses MID_HEIGHT for compact display" do
      expect(symbol.height).to eq(described_class::MID_HEIGHT)
    end

    context "with long xpath" do
      let(:xsd_node) { { "xpath" => "./very/long/xpath/expression/here" } }
      let(:symbol) { described_class.new(xsd_node: xsd_node) }

      it "calculates appropriate width for long path" do
        expected_width = ("selector: ./very/long/xpath/expression/here".length * described_class::CHAR_WIDTH) +
                         described_class::NAME_PADDING
        expect(symbol.width).to be >= [described_class::MIN_WIDTH, expected_width].max
      end
    end
  end
end