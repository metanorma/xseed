# frozen_string_literal: true

require "spec_helper"
require "xseed/svg/symbol/unique_symbol"

RSpec.describe Xseed::Svg::Symbol::UniqueSymbol do
  describe "#initialization" do
    let(:xsd_node) do
      double("xsd_node",
             name: "unique",
             attributes: { "name" => "uniqueConstraint" },
             selector: double("selector", "xpath" => ".//item"),
             field: [double("field", "xpath" => "@code")])
    end

    subject { described_class.new(name: "uniqueConstraint", xsd_node: xsd_node) }

    it "sets the type to 'unique'" do
      expect(subject.type).to eq("unique")
    end

    it "extracts selector and fields" do
      expect(subject.selector).not_to be_nil
      expect(subject.fields).not_to be_empty
    end
  end

  describe "#selector_xpath and #field_xpaths" do
    let(:xsd_node) do
      double("xsd_node",
             name: "unique",
             attributes: {},
             selector: double("selector", "xpath" => ".//product"),
             field: [
               double("field", "xpath" => "@sku"),
               double("field", "xpath" => "@version")
             ])
    end

    subject { described_class.new(name: "productUnique", xsd_node: xsd_node) }

    it "returns correct selector xpath" do
      expect(subject.selector_xpath).to eq(".//product")
    end

    it "returns array of field xpaths" do
      expect(subject.field_xpaths).to eq(["@sku", "@version"])
    end
  end

  describe "#calculate_bounds" do
    let(:xsd_node) do
      double("xsd_node",
             name: "unique",
             attributes: {},
             selector: nil,
             field: [])
    end

    it "uses compact MID_HEIGHT" do
      symbol = described_class.new(name: "test", xsd_node: xsd_node)
      expect(symbol.height).to eq(Xseed::Svg::Symbol::Base::MID_HEIGHT)
    end

    it "calculates width based on name length" do
      short = described_class.new(name: "u", xsd_node: xsd_node)
      long = described_class.new(name: "veryLongUniqueName", xsd_node: xsd_node)
      expect(long.width).to be > short.width
    end
  end
end