# frozen_string_literal: true

require "spec_helper"

RSpec.describe Xseed::Svg::Symbol::ComplexTypeSymbol do
  let(:xsd_node) do
    double(
      "XsdNode",
      name: "PersonType",
      namespace: "http://example.com",
      namespace_prefix: nil,
      attributes: {
        "mixed" => "false",
        "abstract" => "false"
      },
      annotation: nil
    )
  end

  let(:complex_type) do
    described_class.new(
      name: "PersonType",
      type: "complexType",
      xsd_node: xsd_node
    )
  end

  describe "#initialize" do
    it "inherits from Base" do
      expect(complex_type).to be_a(Xseed::Svg::Symbol::Base)
    end

    it "extracts mixed from xsd_node" do
      expect(complex_type.mixed?).to be false
    end

    it "extracts abstract from xsd_node" do
      expect(complex_type.abstract?).to be false
    end

    context "with default values" do
      let(:default_node) do
        double(
          "DefaultNode",
          name: "DefaultType",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: {},
          annotation: nil
        )
      end

      let(:default_type) do
        described_class.new(
          name: "DefaultType",
          type: "complexType",
          xsd_node: default_node
        )
      end

      it "defaults mixed to false" do
        expect(default_type.mixed?).to be false
      end

      it "defaults abstract to false" do
        expect(default_type.abstract?).to be false
      end
    end
  end

  describe "#mixed?" do
    context "when mixed is true" do
      let(:mixed_node) do
        double(
          "MixedNode",
          name: "MixedType",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "mixed" => "true" },
          annotation: nil
        )
      end

      let(:mixed_type) do
        described_class.new(
          name: "MixedType",
          type: "complexType",
          xsd_node: mixed_node
        )
      end

      it "returns true" do
        expect(mixed_type.mixed?).to be true
      end
    end

    context "when mixed is false" do
      it "returns false" do
        expect(complex_type.mixed?).to be false
      end
    end
  end

  describe "#abstract?" do
    context "when abstract is true" do
      let(:abstract_node) do
        double(
          "AbstractNode",
          name: "AbstractType",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "abstract" => "true" },
          annotation: nil
        )
      end

      let(:abstract_type) do
        described_class.new(
          name: "AbstractType",
          type: "complexType",
          xsd_node: abstract_node
        )
      end

      it "returns true" do
        expect(abstract_type.abstract?).to be true
      end
    end

    context "when abstract is false" do
      it "returns false" do
        expect(complex_type.abstract?).to be false
      end
    end
  end

  describe "#content_model" do
    it "allows setting content model" do
      complex_type.content_model = :sequence
      expect(complex_type.content_model).to eq(:sequence)
    end

    it "defaults to nil" do
      expect(complex_type.content_model).to be_nil
    end

    it "accepts valid content models" do
      %i[sequence choice all simple_content complex_content
         empty].each do |model|
        complex_type.content_model = model
        expect(complex_type.content_model).to eq(model)
      end
    end
  end

  describe "#simple_content?" do
    it "returns true when content_model is simple_content" do
      complex_type.content_model = :simple_content
      expect(complex_type.simple_content?).to be true
    end

    it "returns false otherwise" do
      complex_type.content_model = :sequence
      expect(complex_type.simple_content?).to be false
    end
  end

  describe "#complex_content?" do
    it "returns true when content_model is complex_content" do
      complex_type.content_model = :complex_content
      expect(complex_type.complex_content?).to be true
    end

    it "returns false otherwise" do
      complex_type.content_model = :sequence
      expect(complex_type.complex_content?).to be false
    end
  end

  describe "#empty_content?" do
    it "returns true when content_model is empty" do
      complex_type.content_model = :empty
      expect(complex_type.empty_content?).to be true
    end

    it "returns false otherwise" do
      complex_type.content_model = :sequence
      expect(complex_type.empty_content?).to be false
    end

    it "returns true when has no children and no content model" do
      expect(complex_type.children).to be_empty
      expect(complex_type.content_model).to be_nil
      expect(complex_type.empty_content?).to be true
    end
  end

  describe "#base_type" do
    context "with extension or restriction" do
      it "allows setting base type" do
        complex_type.base_type = "xs:string"
        expect(complex_type.base_type).to eq("xs:string")
      end

      it "defaults to nil" do
        expect(complex_type.base_type).to be_nil
      end
    end
  end

  describe "#derivation_method" do
    it "allows setting derivation method" do
      complex_type.derivation_method = :extension
      expect(complex_type.derivation_method).to eq(:extension)
    end

    it "defaults to nil" do
      expect(complex_type.derivation_method).to be_nil
    end

    it "accepts valid derivation methods" do
      %i[extension restriction].each do |method|
        complex_type.derivation_method = method
        expect(complex_type.derivation_method).to eq(method)
      end
    end
  end

  describe "#derived_by_extension?" do
    it "returns true when derivation_method is extension" do
      complex_type.derivation_method = :extension
      expect(complex_type.derived_by_extension?).to be true
    end

    it "returns false otherwise" do
      complex_type.derivation_method = :restriction
      expect(complex_type.derived_by_extension?).to be false
    end
  end

  describe "#derived_by_restriction?" do
    it "returns true when derivation_method is restriction" do
      complex_type.derivation_method = :restriction
      expect(complex_type.derived_by_restriction?).to be true
    end

    it "returns false otherwise" do
      complex_type.derivation_method = :extension
      expect(complex_type.derived_by_restriction?).to be false
    end
  end

  describe "#attributes" do
    it "returns array of attribute symbols" do
      expect(complex_type.attributes).to be_an(Array)
    end

    it "initializes as empty array" do
      expect(complex_type.attributes).to be_empty
    end

    it "allows adding attributes" do
      attr_node = double(
        "AttributeNode",
        name: "id",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      attr_symbol = Xseed::Svg::Symbol::AttributeSymbol.new(
        name: "id",
        type: "attribute",
        xsd_node: attr_node
      )
      complex_type.attributes << attr_symbol
      expect(complex_type.attributes).to include(attr_symbol)
    end
  end

  describe "#add_attribute" do
    let(:attr_node) do
      double(
        "AttributeNode",
        name: "id",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
    end

    let(:attr_symbol) do
      Xseed::Svg::Symbol::AttributeSymbol.new(
        name: "id",
        type: "attribute",
        xsd_node: attr_node
      )
    end

    it "adds attribute to attributes array" do
      complex_type.add_attribute(attr_symbol)
      expect(complex_type.attributes).to include(attr_symbol)
    end

    it "returns the attribute" do
      result = complex_type.add_attribute(attr_symbol)
      expect(result).to eq(attr_symbol)
    end
  end

  describe "#has_attributes?" do
    it "returns false when no attributes" do
      expect(complex_type.has_attributes?).to be false
    end

    it "returns true when has attributes" do
      attr_node = double(
        "AttributeNode",
        name: "id",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      attr_symbol = Xseed::Svg::Symbol::AttributeSymbol.new(
        name: "id",
        type: "attribute",
        xsd_node: attr_node
      )
      complex_type.add_attribute(attr_symbol)
      expect(complex_type.has_attributes?).to be true
    end
  end

  describe "#element_children" do
    it "returns array of element child symbols" do
      elem_node = double(
        "ElementNode",
        name: "name",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      elem_symbol = Xseed::Svg::Symbol::ElementSymbol.new(
        name: "name",
        type: "element",
        xsd_node: elem_node
      )

      attr_node = double(
        "AttributeNode",
        name: "id",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
      attr_symbol = Xseed::Svg::Symbol::AttributeSymbol.new(
        name: "id",
        type: "attribute",
        xsd_node: attr_node
      )

      complex_type.add_child(elem_symbol)
      complex_type.add_attribute(attr_symbol)

      elements = complex_type.element_children
      expect(elements).to include(elem_symbol)
      expect(elements).not_to include(attr_symbol)
    end
  end

  describe "#block" do
    context "when block attribute is present" do
      let(:blocked_node) do
        double(
          "BlockedNode",
          name: "BlockedType",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "block" => "extension restriction" },
          annotation: nil
        )
      end

      let(:blocked_type) do
        described_class.new(
          name: "BlockedType",
          type: "complexType",
          xsd_node: blocked_node
        )
      end

      it "returns block value" do
        expect(blocked_type.block).to eq("extension restriction")
      end
    end

    context "when no block attribute" do
      it "returns nil" do
        expect(complex_type.block).to be_nil
      end
    end
  end

  describe "#final" do
    context "when final attribute is present" do
      let(:final_node) do
        double(
          "FinalNode",
          name: "FinalType",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "final" => "extension" },
          annotation: nil
        )
      end

      let(:final_type) do
        described_class.new(
          name: "FinalType",
          type: "complexType",
          xsd_node: final_node
        )
      end

      it "returns final value" do
        expect(final_type.final).to eq("extension")
      end
    end

    context "when no final attribute" do
      it "returns nil" do
        expect(complex_type.final).to be_nil
      end
    end
  end

  describe "visual representation" do
    describe "#calculate_bounds" do
      it "calculates width based on type name" do
        expect(complex_type.width).to be > 100
      end

      it "has reasonable default height" do
        expect(complex_type.height).to be > 30
      end
    end

    describe "#display_label" do
      it "includes type name" do
        expect(complex_type.display_label).to include("PersonType")
      end

      it "indicates if abstract" do
        abstract_node = double(
          "AbstractNode",
          name: "AbstractType",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "abstract" => "true" },
          annotation: nil
        )
        abstract_type = described_class.new(
          name: "AbstractType",
          type: "complexType",
          xsd_node: abstract_node
        )
        expect(abstract_type.display_label).to match(/abstract/i)
      end

      it "indicates if mixed content" do
        mixed_node = double(
          "MixedNode",
          name: "MixedType",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "mixed" => "true" },
          annotation: nil
        )
        mixed_type = described_class.new(
          name: "MixedType",
          type: "complexType",
          xsd_node: mixed_node
        )
        expect(mixed_type.display_label).to match(/mixed/i)
      end
    end
  end
end
