# frozen_string_literal: true

require "spec_helper"
require "xseed/svg/symbol/keyref_symbol"

RSpec.describe Xseed::Svg::Symbol::KeyrefSymbol do
  describe "#initialization" do
    let(:xsd_node) do
      double("xsd_node",
             name: "keyref",
             attributes: { "name" => "prodKeyRef", "refer" => "prodKey" },
             selector: double("selector", "xpath" => ".//item"),
             field: [double("field", "xpath" => "@productID")])
    end

    subject { described_class.new(name: "prodKeyRef", xsd_node: xsd_node) }

    it "sets the type to 'keyref'" do
      expect(subject.type).to eq("keyref")
    end

    it "extracts refer attribute" do
      expect(subject.refer).to eq("prodKey")
    end

    it "provides refer_name method" do
      expect(subject.refer_name).to eq("prodKey")
    end
  end

  describe "#selector_xpath and #field_xpaths" do
    let(:xsd_node) do
      double("xsd_node",
             name: "keyref",
             attributes: { "refer" => "itemKey" },
             selector: double("selector", "xpath" => ".//order/item"),
             field: [double("field", "xpath" => "@itemId")])
    end

    subject { described_class.new(name: "orderKeyRef", xsd_node: xsd_node) }

    it "returns correct selector xpath" do
      expect(subject.selector_xpath).to eq(".//order/item")
    end

    it "returns array of field xpaths" do
      expect(subject.field_xpaths).to eq(["@itemId"])
    end
  end

  describe "#calculate_bounds" do
    let(:xsd_node) do
      double("xsd_node",
             name: "keyref",
             attributes: { "refer" => "targetKey" },
             selector: nil,
             field: [])
    end

    it "uses compact MID_HEIGHT" do
      symbol = described_class.new(name: "ref", xsd_node: xsd_node)
      expect(symbol.height).to eq(Xseed::Svg::Symbol::Base::MID_HEIGHT)
    end

    it "accounts for refer name in width calculation" do
      short_refer = double("xsd_node",
                           name: "keyref",
                           attributes: { "refer" => "key" },
                           selector: nil,
                           field: [])
      long_refer = double("xsd_node",
                          name: "keyref",
                          attributes: { "refer" => "veryLongKeyNameThatIsSignificantlyLonger" },
                          selector: nil,
                          field: [])

      short = described_class.new(name: "ref", xsd_node: short_refer)
      long = described_class.new(name: "shortRef", xsd_node: long_refer)

      expect(long.width).to be >= short.width
    end

    it "handles missing refer attribute" do
      no_refer = double("xsd_node",
                        name: "keyref",
                        attributes: {},
                        selector: nil,
                        field: [])

      symbol = described_class.new(name: "ref", xsd_node: no_refer)
      expect(symbol.width).to be >= Xseed::Svg::Symbol::Base::MIN_COMPACT_WIDTH
    end
  end
end