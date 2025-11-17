# frozen_string_literal: true

require "spec_helper"
require "xseed/documentation/schema_loader"

RSpec.describe Xseed::Documentation::SchemaLoader do
  let(:fixture_path) do
    File.expand_path("../../fixtures/simple/element_only.xsd", __dir__)
  end
  let(:xsd_content) { File.read(fixture_path) }

  describe ".load" do
    it "loads an XSD file and returns a Lutaml::Xsd::Schema" do
      schema = described_class.load(fixture_path)
      expect(schema).to be_a(Lutaml::Xsd::Schema)
    end

    it "parses schema elements" do
      schema = described_class.load(fixture_path)
      expect(schema.element).not_to be_empty
    end

    it "extracts target namespace" do
      schema = described_class.load(fixture_path)
      expect(schema.target_namespace).not_to be_nil
    end
  end

  describe ".parse" do
    it "parses XSD content from string" do
      schema = described_class.parse(xsd_content,
                                     location: File.dirname(fixture_path))
      expect(schema).to be_a(Lutaml::Xsd::Schema)
    end

    it "handles schema location mappings" do
      mappings = [
        { from: "common.xsd", to: "/local/common.xsd" }
      ]

      schema = described_class.parse(
        xsd_content,
        location: File.dirname(fixture_path),
        schema_mappings: mappings
      )

      expect(schema).to be_a(Lutaml::Xsd::Schema)
    end
  end

  describe "error handling" do
    it "raises informative error for non-existent file" do
      expect do
        described_class.load("nonexistent.xsd")
      end.to raise_error(Xseed::Documentation::SchemaLoader::LoadError,
                         /not found/)
    end

    it "raises informative error for invalid XSD" do
      invalid_xsd = "<invalid>not a schema</invalid>"

      expect do
        described_class.parse(invalid_xsd)
      end.to raise_error(Xseed::Documentation::SchemaLoader::ParseError)
    end
  end

  describe "configuration options" do
    it "accepts config parameter (reserved for future use)" do
      # Config integration will be added once Config supports schema_mappings
      schema = described_class.load(fixture_path, config: nil)
      expect(schema).to be_a(Lutaml::Xsd::Schema)
    end
  end
end
