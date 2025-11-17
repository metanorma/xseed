# frozen_string_literal: true

require "spec_helper"
require "xseed/svg/symbol/any_attribute_symbol"

RSpec.describe Xseed::Svg::Symbol::AnyAttributeSymbol do
  describe "#initialization" do
    let(:xsd_node) do
      double("xsd_node",
             name: "anyAttribute",
             attributes: {
               "namespace" => "##other",
               "processContents" => "lax"
             })
    end

    subject { described_class.new(xsd_node: xsd_node) }

    it "sets name to 'anyAttribute'" do
      expect(subject.name).to eq("anyAttribute")
    end

    it "sets type to 'anyAttribute'" do
      expect(subject.type).to eq("anyAttribute")
    end

    it "extracts namespace attribute" do
      expect(subject.namespace).to eq("##other")
    end

    it "extracts processContents attribute" do
      expect(subject.process_contents).to eq("lax")
    end
  end

  describe "#initialization with defaults" do
    let(:xsd_node) do
      double("xsd_node",
             name: "anyAttribute",
             attributes: {})
    end

    subject { described_class.new(xsd_node: xsd_node) }

    it "defaults namespace to '##any'" do
      expect(subject.namespace).to eq("##any")
    end

    it "defaults processContents to 'strict'" do
      expect(subject.process_contents).to eq("strict")
    end
  end

  describe "#display_label" do
    context "with custom namespace" do
      let(:xsd_node) do
        double("xsd_node",
               name: "anyAttribute",
               attributes: { "namespace" => "http://example.com" })
      end

      subject { described_class.new(xsd_node: xsd_node) }

      it "includes namespace in label" do
        expect(subject.display_label).to eq("anyAttribute: http://example.com")
      end
    end

    context "with default namespace" do
      let(:xsd_node) do
        double("xsd_node",
               name: "anyAttribute",
               attributes: {})
      end

      subject { described_class.new(xsd_node: xsd_node) }

      it "uses ##any as namespace" do
        expect(subject.display_label).to eq("anyAttribute: ##any")
      end
    end
  end

  describe "#processContents values" do
    %w[strict lax skip].each do |value|
      context "when processContents is #{value}" do
        let(:xsd_node) do
          double("xsd_node",
                 name: "anyAttribute",
                 attributes: { "processContents" => value })
        end

        subject { described_class.new(xsd_node: xsd_node) }

        it "stores the processContents value" do
          expect(subject.process_contents).to eq(value)
        end
      end
    end
  end

  describe "#calculate_bounds" do
    let(:xsd_node) do
      double("xsd_node",
             name: "anyAttribute",
             attributes: {})
    end

    it "uses compact MID_HEIGHT" do
      symbol = described_class.new(xsd_node: xsd_node)
      expect(symbol.height).to eq(Xseed::Svg::Symbol::Base::MID_HEIGHT)
    end

    it "calculates width based on label length" do
      short_ns = double("xsd_node",
                        name: "anyAttribute",
                        attributes: { "namespace" => "##any" })
      long_ns = double("xsd_node",
                       name: "anyAttribute",
                       attributes: { "namespace" => "http://example.com/extremely/long/namespace/path/that/is/significantly/longer" })

      short = described_class.new(xsd_node: short_ns)
      long = described_class.new(xsd_node: long_ns)

      expect(long.width).to be >= short.width
    end
  end
end