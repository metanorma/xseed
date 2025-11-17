# frozen_string_literal: true

require "spec_helper"
require "xseed/svg/symbol/key_symbol"

RSpec.describe Xseed::Svg::Symbol::KeySymbol do
  describe "#initialization" do
    let(:xsd_node) do
      double("xsd_node",
             name: "key",
             attributes: { "name" => "testKey" },
             selector: double("selector", "xpath" => ".//test"),
             field: [double("field", "xpath" => "@id")])
    end

    subject { described_class.new(name: "testKey", xsd_node: xsd_node) }

    it "sets the name correctly" do
      expect(subject.name).to eq("testKey")
    end

    it "sets the type to 'key'" do
      expect(subject.type).to eq("key")
    end

    it "stores the xsd_node" do
      expect(subject.xsd_node).to eq(xsd_node)
    end

    it "extracts selector" do
      expect(subject.selector).not_to be_nil
    end

    it "extracts fields" do
      expect(subject.fields).not_to be_empty
    end
  end

  describe "#selector_xpath" do
    context "when selector is present" do
      let(:xsd_node) do
        double("xsd_node",
               name: "key",
               attributes: {},
               selector: double("selector", "xpath" => ".//test"),
               field: [])
      end

      subject { described_class.new(name: "testKey", xsd_node: xsd_node) }

      it "returns the selector xpath" do
        expect(subject.selector_xpath).to eq(".//test")
      end
    end

    context "when selector is not present" do
      let(:xsd_node) do
        double("xsd_node",
               name: "key",
               attributes: {},
               field: [])
      end

      subject { described_class.new(name: "testKey", xsd_node: xsd_node) }

      it "returns nil" do
        expect(subject.selector_xpath).to be_nil
      end
    end
  end

  describe "#field_xpaths" do
    context "with multiple fields" do
      let(:xsd_node) do
        double("xsd_node",
               name: "key",
               attributes: {},
               selector: nil,
               field: [
                 double("field", "xpath" => "@id"),
                 double("field", "xpath" => "@name")
               ])
      end

      subject { described_class.new(name: "testKey", xsd_node: xsd_node) }

      it "returns array of field xpaths" do
        expect(subject.field_xpaths).to eq(["@id", "@name"])
      end
    end

    context "with single field" do
      let(:xsd_node) do
        double("xsd_node",
               name: "key",
               attributes: {},
               selector: nil,
               field: double("field", "xpath" => "@id"))
      end

      subject { described_class.new(name: "testKey", xsd_node: xsd_node) }

      it "returns array with one field xpath" do
        expect(subject.field_xpaths).to eq(["@id"])
      end
    end

    context "with no fields" do
      let(:xsd_node) do
        double("xsd_node",
               name: "key",
               attributes: {},
               selector: nil,
               field: [])
      end

      subject { described_class.new(name: "testKey", xsd_node: xsd_node) }

      it "returns empty array" do
        expect(subject.field_xpaths).to eq([])
      end
    end
  end

  describe "#calculate_bounds" do
    let(:xsd_node) do
      double("xsd_node",
             name: "key",
             attributes: {},
             selector: nil,
             field: [])
    end

    it "uses compact MID_HEIGHT" do
      symbol = described_class.new(name: "testKey", xsd_node: xsd_node)
      expect(symbol.height).to eq(Xseed::Svg::Symbol::Base::MID_HEIGHT)
    end

    it "calculates width based on name length" do
      short_symbol = described_class.new(name: "key", xsd_node: xsd_node)
      long_symbol = described_class.new(name: "veryLongKeyName", xsd_node: xsd_node)

      expect(long_symbol.width).to be > short_symbol.width
    end

    it "respects minimum width" do
      symbol = described_class.new(name: "k", xsd_node: xsd_node)
      expect(symbol.width).to be >= Xseed::Svg::Symbol::Base::MIN_COMPACT_WIDTH
    end
  end
end