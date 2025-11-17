# frozen_string_literal: true

require "spec_helper"
require "xseed/documentation/utils/helpers"

RSpec.describe Xseed::Documentation::Utils::Helpers do
  let(:test_class) { Class.new { include Xseed::Documentation::Utils::Helpers } }
  let(:instance) { test_class.new }

  describe "#component_description" do
    it "returns description for attribute" do
      expect(instance.component_description("attribute")).to eq("Attribute")
    end

    it "returns description for attributeGroup" do
      expect(instance.component_description("attributeGroup")).to eq("Attribute Group")
    end

    it "returns description for complexType" do
      expect(instance.component_description("complexType")).to eq("Complex Type")
    end

    it "returns description for element" do
      expect(instance.component_description("element")).to eq("Element")
    end

    it "returns description for simpleType" do
      expect(instance.component_description("simpleType")).to eq("Simple Type")
    end

    it "returns description for group" do
      expect(instance.component_description("group")).to eq("Model Group")
    end

    it "returns description for notation" do
      expect(instance.component_description("notation")).to eq("Notation")
    end

    it "returns description for all" do
      expect(instance.component_description("all")).to eq("All Model Group")
    end

    it "returns description for choice" do
      expect(instance.component_description("choice")).to eq("Choice Model Group")
    end

    it "returns description for sequence" do
      expect(instance.component_description("sequence")).to eq("Sequence Model Group")
    end

    it "returns unknown for unrecognized component" do
      expect(instance.component_description("unknown")).to eq("Unknown Component")
    end
  end

  describe "#generate_component_id" do
    it "generates ID for element" do
      expect(instance.generate_component_id("element",
                                            "MyElement")).to eq("elem-MyElement")
    end

    it "generates ID for attribute" do
      expect(instance.generate_component_id("attribute",
                                            "myattr")).to eq("attr-myattr")
    end

    it "generates ID for complexType" do
      expect(instance.generate_component_id("complexType",
                                            "MyType")).to eq("ctype-MyType")
    end

    it "generates ID for simpleType" do
      expect(instance.generate_component_id("simpleType",
                                            "StringType")).to eq("stype-StringType")
    end

    it "generates ID for group" do
      expect(instance.generate_component_id("group",
                                            "MyGroup")).to eq("grp-MyGroup")
    end

    it "generates ID for attributeGroup" do
      expect(instance.generate_component_id("attributeGroup",
                                            "AttrGrp")).to eq("attrgrp-AttrGrp")
    end

    it "generates ID for notation" do
      expect(instance.generate_component_id("notation",
                                            "MyNotation")).to eq("nota-MyNotation")
    end

    it "returns schema for schema component" do
      expect(instance.generate_component_id("schema", nil)).to eq("schema")
    end
  end

  describe "#format_occurs" do
    context "with default values" do
      it "returns [1] for 1..1" do
        expect(instance.format_occurs(1, 1)).to eq("[1]")
      end

      it "returns [1] for nil values (defaults)" do
        expect(instance.format_occurs(nil, nil)).to eq("[1]")
      end
    end

    context "with custom values" do
      it "formats 0..1 as [0..1]" do
        expect(instance.format_occurs(0, 1)).to eq("[0..1]")
      end

      it "formats 1..5 as [1..5]" do
        expect(instance.format_occurs(1, 5)).to eq("[1..5]")
      end

      it "formats 0..unbounded as [0..*]" do
        expect(instance.format_occurs(0, "unbounded")).to eq("[0..*]")
      end

      it "formats 1..unbounded as [1..*]" do
        expect(instance.format_occurs(1, "unbounded")).to eq("[1..*]")
      end
    end

    context "with string values" do
      it "converts string numbers" do
        expect(instance.format_occurs("2", "10")).to eq("[2..10]")
      end
    end
  end

  describe "#format_uri" do
    context "with HTTP URI" do
      it "creates clickable link" do
        uri = "http://example.com/schema"
        result = instance.format_uri(uri)
        expect(result).to include("<a")
        expect(result).to include('href="http://example.com/schema"')
        expect(result).to include(">http://example.com/schema</a>")
      end

      it "creates link for HTTPS" do
        uri = "https://example.com/schema"
        result = instance.format_uri(uri)
        expect(result).to include('href="https://example.com/schema"')
      end
    end

    context "with non-HTTP URI" do
      it "returns plain text for file URI" do
        uri = "file:///path/to/schema.xsd"
        result = instance.format_uri(uri)
        expect(result).to eq(uri)
        expect(result).not_to include("<a")
      end

      it "returns plain text for relative path" do
        uri = "schema/types.xsd"
        result = instance.format_uri(uri)
        expect(result).to eq(uri)
        expect(result).not_to include("<a")
      end
    end

    context "with nil or empty URI" do
      it "returns empty string for nil" do
        expect(instance.format_uri(nil)).to eq("")
      end

      it "returns empty string for empty string" do
        expect(instance.format_uri("")).to eq("")
      end
    end
  end

  describe "#format_boolean" do
    context "with true values" do
      it "returns yes for true" do
        expect(instance.format_boolean(true)).to eq("yes")
      end

      it "returns yes for 'true' string" do
        expect(instance.format_boolean("true")).to eq("yes")
      end

      it "returns yes for 'TRUE' string" do
        expect(instance.format_boolean("TRUE")).to eq("yes")
      end

      it "returns yes for '1' string" do
        expect(instance.format_boolean("1")).to eq("yes")
      end

      it "returns yes for 1 number" do
        expect(instance.format_boolean(1)).to eq("yes")
      end
    end

    context "with false values" do
      it "returns no for false" do
        expect(instance.format_boolean(false)).to eq("no")
      end

      it "returns no for 'false' string" do
        expect(instance.format_boolean("false")).to eq("no")
      end

      it "returns no for '0' string" do
        expect(instance.format_boolean("0")).to eq("no")
      end

      it "returns no for nil" do
        expect(instance.format_boolean(nil)).to eq("no")
      end
    end
  end

  describe "#format_block_set" do
    it "expands #all to full set" do
      result = instance.format_block_set("#all")
      expect(result).to eq("restriction, extension, substitution")
    end

    it "returns value as-is for specific blocks" do
      expect(instance.format_block_set("restriction")).to eq("restriction")
    end

    it "returns value for multiple blocks" do
      expect(instance.format_block_set("restriction extension")).to eq("restriction extension")
    end

    it "returns empty string for nil" do
      expect(instance.format_block_set(nil)).to eq("")
    end

    it "returns empty string for empty string" do
      expect(instance.format_block_set("")).to eq("")
    end
  end

  describe "#format_derivation_set" do
    it "expands #all to restriction and extension" do
      result = instance.format_derivation_set("#all")
      expect(result).to eq("restriction, extension")
    end

    it "returns value as-is for specific derivations" do
      expect(instance.format_derivation_set("restriction")).to eq("restriction")
    end

    it "returns value for multiple derivations" do
      expect(instance.format_derivation_set("restriction extension")).to eq("restriction extension")
    end

    it "returns empty string for nil" do
      expect(instance.format_derivation_set(nil)).to eq("")
    end

    it "returns empty string for empty string" do
      expect(instance.format_derivation_set("")).to eq("")
    end
  end

  describe "#format_simple_derivation_set" do
    it "expands #all to full set" do
      result = instance.format_simple_derivation_set("#all")
      expect(result).to eq("restriction, list, union")
    end

    it "returns value as-is for specific derivations" do
      expect(instance.format_simple_derivation_set("restriction")).to eq("restriction")
    end

    it "returns value for multiple derivations" do
      expect(instance.format_simple_derivation_set("restriction list")).to eq("restriction list")
    end

    it "returns empty string for nil" do
      expect(instance.format_simple_derivation_set(nil)).to eq("")
    end

    it "returns empty string for empty string" do
      expect(instance.format_simple_derivation_set("")).to eq("")
    end
  end
end
