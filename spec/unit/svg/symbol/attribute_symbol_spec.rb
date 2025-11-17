# frozen_string_literal: true

require "spec_helper"

RSpec.describe Xseed::Svg::Symbol::AttributeSymbol do
  let(:xsd_node) do
    double(
      "XsdNode",
      name: "id",
      namespace: "http://example.com",
      namespace_prefix: nil,
      attributes: {
        "use" => "required",
        "type" => "xs:string"
      },
      annotation: nil
    )
  end

  let(:attribute) do
    described_class.new(
      name: "id",
      type: "attribute",
      xsd_node: xsd_node
    )
  end

  describe "#initialize" do
    it "inherits from Base" do
      expect(attribute).to be_a(Xseed::Svg::Symbol::Base)
    end

    it "extracts use from xsd_node" do
      expect(attribute.use).to eq("required")
    end

    it "extracts type from xsd_node" do
      expect(attribute.type_ref).to eq("xs:string")
    end

    context "with default values" do
      let(:default_node) do
        double(
          "DefaultNode",
          name: "optional",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: {},
          annotation: nil
        )
      end

      let(:default_attr) do
        described_class.new(
          name: "optional",
          type: "attribute",
          xsd_node: default_node
        )
      end

      it "defaults use to optional" do
        expect(default_attr.use).to eq("optional")
      end
    end
  end

  describe "#use" do
    it "returns use value" do
      expect(attribute.use).to eq("required")
    end

    it "accepts valid use values" do
      %w[required optional prohibited].each do |use_val|
        node = double(
          "Node",
          name: "attr",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "use" => use_val },
          annotation: nil
        )
        attr = described_class.new(name: "attr", type: "attribute",
                                   xsd_node: node)
        expect(attr.use).to eq(use_val)
      end
    end
  end

  describe "#required?" do
    it "returns true when use is required" do
      expect(attribute.required?).to be true
    end

    it "returns false when use is optional" do
      node = double(
        "Node",
        name: "attr",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: { "use" => "optional" },
        annotation: nil
      )
      attr = described_class.new(name: "attr", type: "attribute",
                                 xsd_node: node)
      expect(attr.required?).to be false
    end

    it "returns false when use is prohibited" do
      node = double(
        "Node",
        name: "attr",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: { "use" => "prohibited" },
        annotation: nil
      )
      attr = described_class.new(name: "attr", type: "attribute",
                                 xsd_node: node)
      expect(attr.required?).to be false
    end
  end

  describe "#optional?" do
    it "returns false when use is required" do
      expect(attribute.optional?).to be false
    end

    it "returns true when use is optional" do
      node = double(
        "Node",
        name: "attr",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: { "use" => "optional" },
        annotation: nil
      )
      attr = described_class.new(name: "attr", type: "attribute",
                                 xsd_node: node)
      expect(attr.optional?).to be true
    end
  end

  describe "#prohibited?" do
    it "returns true when use is prohibited" do
      node = double(
        "Node",
        name: "attr",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: { "use" => "prohibited" },
        annotation: nil
      )
      attr = described_class.new(name: "attr", type: "attribute",
                                 xsd_node: node)
      expect(attr.prohibited?).to be true
    end

    it "returns false otherwise" do
      expect(attribute.prohibited?).to be false
    end
  end

  describe "#type_ref" do
    it "returns type reference" do
      expect(attribute.type_ref).to eq("xs:string")
    end

    context "when no type attribute" do
      let(:no_type_node) do
        double(
          "NoTypeNode",
          name: "attr",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: {},
          annotation: nil
        )
      end

      let(:no_type_attr) do
        described_class.new(
          name: "attr",
          type: "attribute",
          xsd_node: no_type_node
        )
      end

      it "returns nil" do
        expect(no_type_attr.type_ref).to be_nil
      end
    end
  end

  describe "#type_ref=" do
    it "allows setting type reference" do
      attribute.type_ref = "custom:CustomType"
      expect(attribute.type_ref).to eq("custom:CustomType")
    end
  end

  describe "#default_value" do
    context "when default attribute is present" do
      let(:default_node) do
        double(
          "DefaultNode",
          name: "attr",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "default" => "defaultValue" },
          annotation: nil
        )
      end

      let(:default_attr) do
        described_class.new(
          name: "attr",
          type: "attribute",
          xsd_node: default_node
        )
      end

      it "returns default value" do
        expect(default_attr.default_value).to eq("defaultValue")
      end
    end

    context "when no default" do
      it "returns nil" do
        expect(attribute.default_value).to be_nil
      end
    end
  end

  describe "#fixed_value" do
    context "when fixed attribute is present" do
      let(:fixed_node) do
        double(
          "FixedNode",
          name: "attr",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "fixed" => "fixedValue" },
          annotation: nil
        )
      end

      let(:fixed_attr) do
        described_class.new(
          name: "attr",
          type: "attribute",
          xsd_node: fixed_node
        )
      end

      it "returns fixed value" do
        expect(fixed_attr.fixed_value).to eq("fixedValue")
      end
    end

    context "when no fixed value" do
      it "returns nil" do
        expect(attribute.fixed_value).to be_nil
      end
    end
  end

  describe "#form" do
    context "when form attribute is present" do
      let(:qualified_node) do
        double(
          "QualifiedNode",
          name: "attr",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "form" => "qualified" },
          annotation: nil
        )
      end

      let(:qualified_attr) do
        described_class.new(
          name: "attr",
          type: "attribute",
          xsd_node: qualified_node
        )
      end

      it "returns form value" do
        expect(qualified_attr.form).to eq("qualified")
      end
    end

    context "when no form attribute" do
      it "returns nil" do
        expect(attribute.form).to be_nil
      end
    end
  end

  describe "#resolve_type_reference" do
    let(:type_registry) do
      {
        "xs:string" => double("StringType", name: "string"),
        "custom:CustomType" => double("CustomType", name: "CustomType")
      }
    end

    context "when type_ref exists in registry" do
      it "returns resolved type symbol" do
        resolved = attribute.resolve_type_reference(type_registry)
        expect(resolved.name).to eq("string")
      end
    end

    context "when type_ref does not exist" do
      it "returns nil" do
        attribute.type_ref = "unknown:Type"
        expect(attribute.resolve_type_reference(type_registry)).to be_nil
      end
    end

    context "when attribute has no type_ref" do
      let(:no_type_node) do
        double(
          "NoTypeNode",
          name: "attr",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: {},
          annotation: nil
        )
      end

      let(:no_type_attr) do
        described_class.new(
          name: "attr",
          type: "attribute",
          xsd_node: no_type_node
        )
      end

      it "returns nil" do
        expect(no_type_attr.resolve_type_reference(type_registry)).to be_nil
      end
    end
  end

  describe "visual representation" do
    describe "#calculate_bounds" do
      it "calculates width based on name and type" do
        expect(attribute.width).to be > 60
      end

      it "is smaller than element symbols" do
        elem_node = double(
          "ElementNode",
          name: "element",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: {},
          annotation: nil
        )
        elem = Xseed::Svg::Symbol::ElementSymbol.new(
          name: "element",
          type: "element",
          xsd_node: elem_node
        )
        expect(attribute.height).to be < elem.height
      end
    end

    describe "#display_label" do
      it "includes @ prefix for attributes" do
        expect(attribute.display_label).to match(/@id/)
      end

      it "includes use indicator for required" do
        expect(attribute.display_label).to match(/required|!/)
      end

      context "with optional attribute" do
        let(:optional_node) do
          double(
            "OptionalNode",
            name: "optAttr",
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: { "use" => "optional" },
            annotation: nil
          )
        end

        let(:optional_attr) do
          described_class.new(
            name: "optAttr",
            type: "attribute",
            xsd_node: optional_node
          )
        end

        it "includes attribute name" do
          expect(optional_attr.display_label).to include("@optAttr")
        end
      end

      context "with type reference" do
        it "includes type information" do
          label = attribute.display_label
          expect(label).to match(/string|xs:string/)
        end
      end

      context "with default value" do
        let(:default_node) do
          double(
            "DefaultNode",
            name: "attr",
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: { "default" => "defaultValue" },
            annotation: nil
          )
        end

        let(:default_attr) do
          described_class.new(
            name: "attr",
            type: "attribute",
            xsd_node: default_node
          )
        end

        it "indicates default value" do
          expect(default_attr.display_label).to match(/default|=/)
        end
      end
    end
  end

  describe "#ref" do
    context "when ref attribute is present" do
      let(:ref_node) do
        double(
          "RefNode",
          name: nil,
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "ref" => "common:Id" },
          annotation: nil
        )
      end

      let(:ref_attr) do
        described_class.new(
          name: "refAttr",
          type: "attribute",
          xsd_node: ref_node
        )
      end

      it "returns ref value" do
        expect(ref_attr.ref).to eq("common:Id")
      end
    end

    context "when no ref attribute" do
      it "returns nil" do
        expect(attribute.ref).to be_nil
      end
    end
  end

  describe "#is_reference?" do
    it "returns true when has ref attribute" do
      ref_node = double(
        "RefNode",
        name: nil,
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: { "ref" => "common:Id" },
        annotation: nil
      )
      ref_attr = described_class.new(
        name: "refAttr",
        type: "attribute",
        xsd_node: ref_node
      )
      expect(ref_attr.is_reference?).to be true
    end

    it "returns false when no ref" do
      expect(attribute.is_reference?).to be false
    end
  end
end
