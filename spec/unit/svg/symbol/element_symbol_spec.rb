# frozen_string_literal: true

require "spec_helper"

RSpec.describe Xseed::Svg::Symbol::ElementSymbol do
  let(:xsd_node) do
    double(
      "XsdNode",
      name: "testElement",
      namespace: "http://example.com",
      namespace_prefix: nil,
      attributes: {
        "minOccurs" => "1",
        "maxOccurs" => "1",
        "nillable" => "false"
      },
      annotation: nil
    )
  end

  let(:element_symbol) do
    described_class.new(
      name: "TestElement",
      type: "element",
      xsd_node: xsd_node
    )
  end

  describe "#initialize" do
    it "inherits from Base" do
      expect(element_symbol).to be_a(Xseed::Svg::Symbol::Base)
    end

    it "extracts minOccurs from xsd_node" do
      expect(element_symbol.min_occurs).to eq(1)
    end

    it "extracts maxOccurs from xsd_node" do
      expect(element_symbol.max_occurs).to eq(1)
    end

    it "extracts nillable from xsd_node" do
      expect(element_symbol.nillable?).to be false
    end

    context "with unbounded maxOccurs" do
      let(:unbounded_node) do
        double(
          "UnboundedNode",
          name: "testElement",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: {
            "minOccurs" => "0",
            "maxOccurs" => "unbounded"
          },
          annotation: nil
        )
      end

      let(:unbounded_element) do
        described_class.new(
          name: "UnboundedElement",
          type: "element",
          xsd_node: unbounded_node
        )
      end

      it "sets maxOccurs to infinity" do
        expect(unbounded_element.max_occurs).to eq(Float::INFINITY)
      end
    end

    context "with default values" do
      let(:default_node) do
        double(
          "DefaultNode",
          name: "testElement",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: {},
          annotation: nil
        )
      end

      let(:default_element) do
        described_class.new(
          name: "DefaultElement",
          type: "element",
          xsd_node: default_node
        )
      end

      it "defaults minOccurs to 1" do
        expect(default_element.min_occurs).to eq(1)
      end

      it "defaults maxOccurs to 1" do
        expect(default_element.max_occurs).to eq(1)
      end

      it "defaults nillable to false" do
        expect(default_element.nillable?).to be false
      end
    end
  end

  describe "#min_occurs" do
    it "returns integer value" do
      expect(element_symbol.min_occurs).to be_an(Integer)
    end

    it "allows zero" do
      node = double(
        "Node",
        name: "element",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: { "minOccurs" => "0" },
        annotation: nil
      )
      elem = described_class.new(name: "Test", type: "element", xsd_node: node)
      expect(elem.min_occurs).to eq(0)
    end
  end

  describe "#max_occurs" do
    it "returns integer value for bounded" do
      expect(element_symbol.max_occurs).to be_an(Integer)
    end

    it "returns infinity for unbounded" do
      node = double(
        "Node",
        name: "element",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: { "maxOccurs" => "unbounded" },
        annotation: nil
      )
      elem = described_class.new(name: "Test", type: "element", xsd_node: node)
      expect(elem.max_occurs).to eq(Float::INFINITY)
    end
  end

  describe "#nillable?" do
    it "returns boolean" do
      expect([true, false]).to include(element_symbol.nillable?)
    end

    context "when nillable is true" do
      let(:nillable_node) do
        double(
          "NillableNode",
          name: "element",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "nillable" => "true" },
          annotation: nil
        )
      end

      let(:nillable_element) do
        described_class.new(
          name: "NillableElement",
          type: "element",
          xsd_node: nillable_node
        )
      end

      it "returns true" do
        expect(nillable_element.nillable?).to be true
      end
    end
  end

  describe "#optional?" do
    context "when minOccurs is 0" do
      let(:optional_node) do
        double(
          "OptionalNode",
          name: "element",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "minOccurs" => "0" },
          annotation: nil
        )
      end

      let(:optional_element) do
        described_class.new(
          name: "OptionalElement",
          type: "element",
          xsd_node: optional_node
        )
      end

      it "returns true" do
        expect(optional_element.optional?).to be true
      end
    end

    context "when minOccurs is greater than 0" do
      it "returns false" do
        expect(element_symbol.optional?).to be false
      end
    end
  end

  describe "#required?" do
    it "returns opposite of optional?" do
      expect(element_symbol.required?).to eq(!element_symbol.optional?)
    end

    context "when minOccurs is 0" do
      let(:optional_node) do
        double(
          "OptionalNode",
          name: "element",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "minOccurs" => "0" },
          annotation: nil
        )
      end

      let(:optional_element) do
        described_class.new(
          name: "OptionalElement",
          type: "element",
          xsd_node: optional_node
        )
      end

      it "returns false" do
        expect(optional_element.required?).to be false
      end
    end
  end

  describe "#repeatable?" do
    context "when maxOccurs is 1" do
      it "returns false" do
        expect(element_symbol.repeatable?).to be false
      end
    end

    context "when maxOccurs is greater than 1" do
      let(:repeatable_node) do
        double(
          "RepeatableNode",
          name: "element",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "maxOccurs" => "5" },
          annotation: nil
        )
      end

      let(:repeatable_element) do
        described_class.new(
          name: "RepeatableElement",
          type: "element",
          xsd_node: repeatable_node
        )
      end

      it "returns true" do
        expect(repeatable_element.repeatable?).to be true
      end
    end

    context "when maxOccurs is unbounded" do
      let(:unbounded_node) do
        double(
          "UnboundedNode",
          name: "element",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "maxOccurs" => "unbounded" },
          annotation: nil
        )
      end

      let(:unbounded_element) do
        described_class.new(
          name: "UnboundedElement",
          type: "element",
          xsd_node: unbounded_node
        )
      end

      it "returns true" do
        expect(unbounded_element.repeatable?).to be true
      end
    end
  end

  describe "#type_ref" do
    context "when element has type attribute" do
      let(:typed_node) do
        double(
          "TypedNode",
          name: "element",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "type" => "xs:string" },
          annotation: nil
        )
      end

      let(:typed_element) do
        described_class.new(
          name: "TypedElement",
          type: "element",
          xsd_node: typed_node
        )
      end

      it "returns type reference" do
        expect(typed_element.type_ref).to eq("xs:string")
      end
    end

    context "when element has no type attribute" do
      it "returns nil" do
        expect(element_symbol.type_ref).to be_nil
      end
    end
  end

  describe "#type_ref=" do
    it "allows setting type reference" do
      element_symbol.type_ref = "custom:CustomType"
      expect(element_symbol.type_ref).to eq("custom:CustomType")
    end
  end

  describe "#substitution_group" do
    context "when element has substitutionGroup attribute" do
      let(:subst_node) do
        double(
          "SubstitutionNode",
          name: "element",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "substitutionGroup" => "base:BaseElement" },
          annotation: nil
        )
      end

      let(:subst_element) do
        described_class.new(
          name: "SubstitutionElement",
          type: "element",
          xsd_node: subst_node
        )
      end

      it "returns substitution group name" do
        expect(subst_element.substitution_group).to eq("base:BaseElement")
      end
    end

    context "when element has no substitutionGroup" do
      it "returns nil" do
        expect(element_symbol.substitution_group).to be_nil
      end
    end
  end

  describe "#abstract?" do
    context "when element has abstract=true" do
      let(:abstract_node) do
        double(
          "AbstractNode",
          name: "element",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "abstract" => "true" },
          annotation: nil
        )
      end

      let(:abstract_element) do
        described_class.new(
          name: "AbstractElement",
          type: "element",
          xsd_node: abstract_node
        )
      end

      it "returns true" do
        expect(abstract_element.abstract?).to be true
      end
    end

    context "when element is not abstract" do
      it "returns false" do
        expect(element_symbol.abstract?).to be false
      end
    end
  end

  describe "#default_value" do
    context "when element has default attribute" do
      let(:default_node) do
        double(
          "DefaultNode",
          name: "element",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "default" => "defaultValue" },
          annotation: nil
        )
      end

      let(:default_element) do
        described_class.new(
          name: "DefaultElement",
          type: "element",
          xsd_node: default_node
        )
      end

      it "returns default value" do
        expect(default_element.default_value).to eq("defaultValue")
      end
    end

    context "when element has no default" do
      it "returns nil" do
        expect(element_symbol.default_value).to be_nil
      end
    end
  end

  describe "#fixed_value" do
    context "when element has fixed attribute" do
      let(:fixed_node) do
        double(
          "FixedNode",
          name: "element",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "fixed" => "fixedValue" },
          annotation: nil
        )
      end

      let(:fixed_element) do
        described_class.new(
          name: "FixedElement",
          type: "element",
          xsd_node: fixed_node
        )
      end

      it "returns fixed value" do
        expect(fixed_element.fixed_value).to eq("fixedValue")
      end
    end

    context "when element has no fixed value" do
      it "returns nil" do
        expect(element_symbol.fixed_value).to be_nil
      end
    end
  end

  describe "#form" do
    context "when element has form attribute" do
      let(:qualified_node) do
        double(
          "QualifiedNode",
          name: "element",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "form" => "qualified" },
          annotation: nil
        )
      end

      let(:qualified_element) do
        described_class.new(
          name: "QualifiedElement",
          type: "element",
          xsd_node: qualified_node
        )
      end

      it "returns form value" do
        expect(qualified_element.form).to eq("qualified")
      end
    end

    context "when element has no form attribute" do
      it "returns nil" do
        expect(element_symbol.form).to be_nil
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
      let(:typed_node) do
        double(
          "TypedNode",
          name: "element",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "type" => "xs:string" },
          annotation: nil
        )
      end

      let(:typed_element) do
        described_class.new(
          name: "TypedElement",
          type: "element",
          xsd_node: typed_node
        )
      end

      it "returns resolved type symbol" do
        resolved = typed_element.resolve_type_reference(type_registry)
        expect(resolved.name).to eq("string")
      end
    end

    context "when type_ref does not exist" do
      it "returns nil" do
        element_symbol.type_ref = "unknown:Type"
        expect(element_symbol.resolve_type_reference(type_registry)).to be_nil
      end
    end

    context "when element has no type_ref" do
      it "returns nil" do
        expect(element_symbol.resolve_type_reference(type_registry)).to be_nil
      end
    end
  end

  describe "visual representation" do
    describe "#calculate_bounds" do
      it "calculates width based on name length" do
        expect(element_symbol.width).to be > 80
      end

      it "includes space for occurrence indicators" do
        optional_node = double(
          "OptionalNode",
          name: "element",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "minOccurs" => "0", "maxOccurs" => "unbounded" },
          annotation: nil
        )
        optional_elem = described_class.new(
          name: "Opt",
          type: "element",
          xsd_node: optional_node
        )
        expect(optional_elem.width).to be > 100
      end
    end

    describe "#display_label" do
      it "includes element name" do
        expect(element_symbol.display_label).to include("TestElement")
      end

      context "when optional" do
        let(:optional_node) do
          double(
            "OptionalNode",
            name: "element",
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: { "minOccurs" => "0" },
            annotation: nil
          )
        end

        let(:optional_element) do
          described_class.new(
            name: "OptionalElement",
            type: "element",
            xsd_node: optional_node
          )
        end

        it "includes occurrence indicator" do
          expect(optional_element.display_label).to match(/\[0\.\.1\]/)
        end
      end

      context "when repeatable" do
        let(:repeatable_node) do
          double(
            "RepeatableNode",
            name: "element",
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: { "maxOccurs" => "unbounded" },
            annotation: nil
          )
        end

        let(:repeatable_element) do
          described_class.new(
            name: "RepeatableElement",
            type: "element",
            xsd_node: repeatable_node
          )
        end

        it "includes occurrence indicator" do
          expect(repeatable_element.display_label).to match(/\[1\.\.\*\]/)
        end
      end
    end
  end
end
