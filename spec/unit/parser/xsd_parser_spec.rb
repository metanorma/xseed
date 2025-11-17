# frozen_string_literal: true

require "spec_helper"
require "xseed/parser/xsd_parser"

RSpec.describe Xseed::Parser::XsdParser do
  def fixture_path(relative_path)
    File.join(File.dirname(__FILE__), "../../fixtures", relative_path)
  end

  describe "#initialize" do
    context "with valid XSD file" do
      let(:xsd_file_path) { fixture_path("simple/element_only.xsd") }
      let(:parser) { described_class.new(xsd_file_path) }

      it "creates a parser instance" do
        expect(parser).to be_a(described_class)
      end

      it "parses the XML document" do
        expect(parser.document).to be_a(Nokogiri::XML::Document)
      end

      it "extracts the schema root element" do
        expect(parser.schema).to be_a(Nokogiri::XML::Element)
        expect(parser.schema.name).to eq("schema")
      end

      it "extracts the target namespace" do
        expect(parser.target_namespace).to eq("http://example.com/test")
      end
    end

    context "with non-existent file" do
      let(:xsd_file_path) { fixture_path("non_existent.xsd") }

      it "raises an error" do
        expect { described_class.new(xsd_file_path) }
          .to raise_error(Errno::ENOENT)
      end
    end
  end

  describe "#target_namespace" do
    context "with element_only.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/element_only.xsd"))
      end

      it "returns the target namespace" do
        expect(parser.target_namespace).to eq("http://example.com/test")
      end
    end

    context "with complex_type.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/complex_type.xsd"))
      end

      it "returns the target namespace" do
        expect(parser.target_namespace).to eq("http://example.com/complex")
      end
    end

    context "with simple_type.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/simple_type.xsd"))
      end

      it "returns the target namespace" do
        expect(parser.target_namespace).to eq("http://example.com/simple")
      end
    end
  end

  describe "#element_form_default" do
    let(:parser) do
      described_class.new(fixture_path("simple/element_only.xsd"))
    end

    it "returns the elementFormDefault attribute" do
      expect(parser.element_form_default).to eq("qualified")
    end
  end

  describe "#schema_version" do
    context "when schema has version attribute" do
      let(:parser) do
        described_class.new(fixture_path("real_world/unitsml-v1.0.xsd"))
      end

      it "returns the version" do
        expect(parser.schema_version).not_to be_nil
      end
    end

    context "when schema has no version attribute" do
      let(:parser) do
        described_class.new(fixture_path("simple/element_only.xsd"))
      end

      it "returns nil" do
        expect(parser.schema_version).to be_nil
      end
    end
  end

  describe "#elements" do
    context "with element_only.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/element_only.xsd"))
      end

      it "returns all global elements" do
        elements = parser.elements
        expect(elements).to respond_to(:size)
        expect(elements.size).to eq(5)
      end

      it "extracts element names" do
        element_names = parser.elements.map { |el| el["name"] }
        expect(element_names).to include("root", "title", "count",
                                         "active", "timestamp")
      end

      it "extracts element types" do
        root_element = parser.elements.find { |el| el["name"] == "root" }
        expect(root_element["type"]).to eq("xs:string")
      end
    end

    context "with complex_type.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/complex_type.xsd"))
      end

      it "returns global elements" do
        elements = parser.elements
        expect(elements.size).to eq(2)
        element_names = elements.map { |el| el["name"] }
        expect(element_names).to include("person", "contact")
      end
    end

    context "with simple_type.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/simple_type.xsd"))
      end

      it "returns global elements" do
        elements = parser.elements
        expect(elements.size).to eq(4)
        element_names = elements.map { |el| el["name"] }
        expect(element_names).to include("status", "age", "email", "code")
      end
    end
  end

  describe "#complex_types" do
    context "with element_only.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/element_only.xsd"))
      end

      it "returns empty array when no complex types" do
        expect(parser.complex_types.to_a).to eq([])
      end
    end

    context "with complex_type.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/complex_type.xsd"))
      end

      it "returns all complex types" do
        types = parser.complex_types
        expect(types.size).to eq(2)
      end

      it "extracts complex type names" do
        type_names = parser.complex_types.map { |t| t["name"] }
        expect(type_names).to include("PersonType", "ContactType")
      end
    end
  end

  describe "#simple_types" do
    context "with element_only.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/element_only.xsd"))
      end

      it "returns empty array when no simple types" do
        expect(parser.simple_types.to_a).to eq([])
      end
    end

    context "with simple_type.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/simple_type.xsd"))
      end

      it "returns all simple types" do
        types = parser.simple_types
        expect(types.size).to eq(4)
      end

      it "extracts simple type names" do
        type_names = parser.simple_types.map { |t| t["name"] }
        expect(type_names).to include("StatusType", "AgeType",
                                      "EmailType", "CodeType")
      end
    end
  end

  describe "#types" do
    context "with complex_type.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/complex_type.xsd"))
      end

      it "returns both complex and simple types" do
        types = parser.types
        expect(types.size).to eq(2)
      end
    end

    context "with simple_type.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/simple_type.xsd"))
      end

      it "returns all types" do
        types = parser.types
        expect(types.size).to eq(4)
      end
    end
  end

  describe "#groups" do
    context "with recursive_groups.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/recursive_groups.xsd"))
      end

      it "returns all groups" do
        groups = parser.groups
        expect(groups).to respond_to(:size)
        expect(groups.size).to be > 0
      end
    end

    context "with schema without groups" do
      let(:parser) do
        described_class.new(fixture_path("simple/element_only.xsd"))
      end

      it "returns empty array" do
        expect(parser.groups.to_a).to eq([])
      end
    end
  end

  describe "#attribute_groups" do
    context "with schema without attribute groups" do
      let(:parser) do
        described_class.new(fixture_path("simple/element_only.xsd"))
      end

      it "returns empty array" do
        expect(parser.attribute_groups.to_a).to eq([])
      end
    end
  end

  describe "#namespaces" do
    context "with element_only.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/element_only.xsd"))
      end

      it "returns namespace mappings" do
        namespaces = parser.namespaces
        expect(namespaces).to be_a(Hash)
        expect(namespaces["xs"]).to eq("http://www.w3.org/2001/XMLSchema")
        expect(namespaces["tns"]).to eq("http://example.com/test")
      end
    end
  end

  describe "#documentation" do
    context "with element_only.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/element_only.xsd"))
      end

      it "extracts schema-level documentation" do
        doc = parser.documentation
        expect(doc).to be_a(String)
        expect(doc).to include("Simple XSD with only element definitions")
      end
    end

    context "with schema without documentation" do
      let(:parser) do
        described_class.new(fixture_path("simple/recursive_groups.xsd"))
      end

      it "returns nil or empty string" do
        doc = parser.documentation
        expect(doc).to be_nil.or(be_empty)
      end
    end
  end

  describe "#element_documentation" do
    context "with element_only.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/element_only.xsd"))
      end

      it "extracts documentation for named element" do
        doc = parser.element_documentation("root")
        expect(doc).to include("Root element of type string")
      end

      it "returns nil for element without documentation" do
        doc = parser.element_documentation("nonexistent")
        expect(doc).to be_nil
      end
    end
  end

  describe "#type_documentation" do
    context "with simple_type.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/simple_type.xsd"))
      end

      it "extracts documentation for named type" do
        doc = parser.type_documentation("StatusType")
        expect(doc).to include("Status enumeration")
      end
    end

    context "with complex_type.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/complex_type.xsd"))
      end

      it "extracts documentation for complex type" do
        doc = parser.type_documentation("PersonType")
        expect(doc).to include("A person with name and age")
      end
    end
  end

  describe "#imports" do
    context "with schema without imports" do
      let(:parser) do
        described_class.new(fixture_path("simple/element_only.xsd"))
      end

      it "returns empty array" do
        expect(parser.imports.to_a).to eq([])
      end
    end
  end

  describe "#includes" do
    context "with schema without includes" do
      let(:parser) do
        described_class.new(fixture_path("simple/element_only.xsd"))
      end

      it "returns empty array" do
        expect(parser.includes.to_a).to eq([])
      end
    end
  end

  describe "integration with real-world XSD" do
    context "with unitsml-v1.0.xsd" do
      let(:parser) do
        described_class.new(fixture_path("real_world/unitsml-v1.0.xsd"))
      end

      it "successfully parses the schema" do
        expect(parser.document).to be_a(Nokogiri::XML::Document)
      end

      it "extracts target namespace" do
        expect(parser.target_namespace).not_to be_nil
        expect(parser.target_namespace).to be_a(String)
      end

      it "extracts elements" do
        elements = parser.elements
        expect(elements).to respond_to(:size)
        expect(elements.size).to be > 0
      end

      it "extracts types" do
        types = parser.types
        expect(types).to respond_to(:size)
        expect(types.size).to be > 0
      end
    end

    context "with recursive_groups.xsd" do
      let(:parser) do
        described_class.new(fixture_path("simple/recursive_groups.xsd"))
      end

      it "successfully parses the schema" do
        expect(parser.document).to be_a(Nokogiri::XML::Document)
      end

      it "extracts groups" do
        groups = parser.groups
        expect(groups).to respond_to(:size)
      end
    end
  end
end
