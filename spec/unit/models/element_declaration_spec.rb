# frozen_string_literal: true

require "spec_helper"
require "xseed/models/element_declaration"

RSpec.describe Xseed::Models::ElementDeclaration do
  describe ".from_xsd_node" do
    let(:xsd_content) do
      <<~XSD
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" targetNamespace="http://example.com">
          <xs:element name="Person" type="PersonType" minOccurs="0" maxOccurs="unbounded" nillable="true">
            <xs:annotation>
              <xs:documentation>Represents a person entity</xs:documentation>
            </xs:annotation>
          </xs:element>
        </xs:schema>
      XSD
    end

    let(:document) { Nokogiri::XML(xsd_content) }
    let(:element_node) do
      document.at_xpath("//xs:element", "xs" => "http://www.w3.org/2001/XMLSchema")
    end

    it "parses element name" do
      element = described_class.from_xsd_node(element_node)
      expect(element.name).to eq("Person")
    end

    it "parses element type" do
      element = described_class.from_xsd_node(element_node)
      expect(element.type).to eq("PersonType")
    end

    it "parses min_occurs" do
      element = described_class.from_xsd_node(element_node)
      expect(element.min_occurs).to eq(0)
    end

    it "parses max_occurs" do
      element = described_class.from_xsd_node(element_node)
      expect(element.max_occurs).to eq("unbounded")
    end

    it "parses nillable attribute" do
      element = described_class.from_xsd_node(element_node)
      expect(element.nillable).to be true
    end

    it "parses documentation" do
      element = described_class.from_xsd_node(element_node)
      expect(element.documentation).to eq("Represents a person entity")
    end
  end

  describe "default values" do
    it "sets min_occurs to 1 by default" do
      element = described_class.new(name: "Test")
      expect(element.min_occurs).to eq(1)
    end

    it "sets max_occurs to '1' by default" do
      element = described_class.new(name: "Test")
      expect(element.max_occurs).to eq("1")
    end

    it "sets nillable to false by default" do
      element = described_class.new(name: "Test")
      expect(element.nillable).to be false
    end

    it "sets abstract to false by default" do
      element = described_class.new(name: "Test")
      expect(element.abstract).to be false
    end
  end

  describe "#optional?" do
    it "returns true when min_occurs is 0" do
      element = described_class.new(name: "Test", min_occurs: 0)
      expect(element.optional?).to be true
    end

    it "returns false when min_occurs is greater than 0" do
      element = described_class.new(name: "Test", min_occurs: 1)
      expect(element.optional?).to be false
    end
  end

  describe "#unbounded?" do
    it "returns true when max_occurs is 'unbounded'" do
      element = described_class.new(name: "Test", max_occurs: "unbounded")
      expect(element.unbounded?).to be true
    end

    it "returns false when max_occurs is a number" do
      element = described_class.new(name: "Test", max_occurs: "5")
      expect(element.unbounded?).to be false
    end
  end

  describe "serialization" do
    it "serializes to YAML" do
      element = described_class.new(
        name: "Test",
        type: "string",
        min_occurs: 0,
        max_occurs: "1",
        documentation: "Test element",
      )
      yaml = element.to_yaml
      expect(yaml).to include("name: Test")
      expect(yaml).to include("type: string")
      expect(yaml).to include("min_occurs: 0")
    end
  end
end
