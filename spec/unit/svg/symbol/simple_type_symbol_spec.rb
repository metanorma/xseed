# frozen_string_literal: true

require "spec_helper"

RSpec.describe Xseed::Svg::Symbol::SimpleTypeSymbol do
  let(:xsd_node) do
    double(
      "XsdNode",
      name: "CodeType",
      namespace: "http://example.com",
      namespace_prefix: nil,
      attributes: {},
      annotation: nil
    )
  end

  let(:simple_type) do
    described_class.new(
      name: "CodeType",
      type: "simpleType",
      xsd_node: xsd_node
    )
  end

  describe "#initialize" do
    it "inherits from Base" do
      expect(simple_type).to be_a(Xseed::Svg::Symbol::Base)
    end

    it "initializes variety as nil" do
      expect(simple_type.variety).to be_nil
    end

    it "initializes base_type as nil" do
      expect(simple_type.base_type).to be_nil
    end
  end

  describe "#variety" do
    it "allows setting variety" do
      simple_type.variety = :restriction
      expect(simple_type.variety).to eq(:restriction)
    end

    it "accepts valid varieties" do
      %i[restriction list union].each do |variety|
        simple_type.variety = variety
        expect(simple_type.variety).to eq(variety)
      end
    end
  end

  describe "#variety?" do
    it "returns true for matching variety" do
      simple_type.variety = :restriction
      expect(simple_type.variety?(:restriction)).to be true
    end

    it "returns false for non-matching variety" do
      simple_type.variety = :restriction
      expect(simple_type.variety?(:list)).to be false
    end
  end

  describe "#restriction?" do
    it "returns true when variety is restriction" do
      simple_type.variety = :restriction
      expect(simple_type.restriction?).to be true
    end

    it "returns false otherwise" do
      simple_type.variety = :list
      expect(simple_type.restriction?).to be false
    end
  end

  describe "#list?" do
    it "returns true when variety is list" do
      simple_type.variety = :list
      expect(simple_type.list?).to be true
    end

    it "returns false otherwise" do
      simple_type.variety = :restriction
      expect(simple_type.list?).to be false
    end
  end

  describe "#union?" do
    it "returns true when variety is union" do
      simple_type.variety = :union
      expect(simple_type.union?).to be true
    end

    it "returns false otherwise" do
      simple_type.variety = :restriction
      expect(simple_type.union?).to be false
    end
  end

  describe "#base_type" do
    it "allows setting base type" do
      simple_type.base_type = "xs:string"
      expect(simple_type.base_type).to eq("xs:string")
    end

    it "defaults to nil" do
      expect(simple_type.base_type).to be_nil
    end
  end

  describe "#facets" do
    it "returns array of facets" do
      expect(simple_type.facets).to be_an(Array)
    end

    it "initializes as empty array" do
      expect(simple_type.facets).to be_empty
    end
  end

  describe "#add_facet" do
    it "adds facet to facets array" do
      facet = { type: :minLength, value: "5" }
      simple_type.add_facet(facet)
      expect(simple_type.facets).to include(facet)
    end

    it "returns the facet" do
      facet = { type: :maxLength, value: "10" }
      result = simple_type.add_facet(facet)
      expect(result).to eq(facet)
    end

    it "accepts different facet types" do
      facets = [
        { type: :minLength, value: "1" },
        { type: :maxLength, value: "100" },
        { type: :pattern, value: "[A-Z]{3}" },
        { type: :enumeration, value: "USD" },
        { type: :minInclusive, value: "0" },
        { type: :maxInclusive, value: "100" }
      ]

      facets.each do |facet|
        simple_type.add_facet(facet)
      end

      expect(simple_type.facets.size).to eq(6)
    end
  end

  describe "#has_facets?" do
    it "returns false when no facets" do
      expect(simple_type.has_facets?).to be false
    end

    it "returns true when has facets" do
      simple_type.add_facet({ type: :minLength, value: "1" })
      expect(simple_type.has_facets?).to be true
    end
  end

  describe "#facet" do
    it "returns facet by type" do
      pattern_facet = { type: :pattern, value: "[A-Z]{3}" }
      simple_type.add_facet(pattern_facet)
      simple_type.add_facet({ type: :minLength, value: "1" })

      expect(simple_type.facet(:pattern)).to eq(pattern_facet)
    end

    it "returns nil when facet not found" do
      expect(simple_type.facet(:pattern)).to be_nil
    end
  end

  describe "#facets_of_type" do
    it "returns all facets of given type" do
      enum1 = { type: :enumeration, value: "USD" }
      enum2 = { type: :enumeration, value: "EUR" }
      enum3 = { type: :enumeration, value: "GBP" }

      simple_type.add_facet(enum1)
      simple_type.add_facet({ type: :minLength, value: "1" })
      simple_type.add_facet(enum2)
      simple_type.add_facet(enum3)

      enums = simple_type.facets_of_type(:enumeration)
      expect(enums).to include(enum1, enum2, enum3)
      expect(enums.size).to eq(3)
    end

    it "returns empty array when no facets of type" do
      expect(simple_type.facets_of_type(:pattern)).to eq([])
    end
  end

  describe "#enumeration_values" do
    it "returns array of enumeration values" do
      simple_type.add_facet({ type: :enumeration, value: "USD" })
      simple_type.add_facet({ type: :enumeration, value: "EUR" })
      simple_type.add_facet({ type: :enumeration, value: "GBP" })

      expect(simple_type.enumeration_values).to eq(%w[USD EUR GBP])
    end

    it "returns empty array when no enumerations" do
      expect(simple_type.enumeration_values).to eq([])
    end
  end

  describe "#pattern_value" do
    it "returns pattern value" do
      simple_type.add_facet({ type: :pattern, value: "[A-Z]{3}" })
      expect(simple_type.pattern_value).to eq("[A-Z]{3}")
    end

    it "returns nil when no pattern" do
      expect(simple_type.pattern_value).to be_nil
    end
  end

  describe "#min_length" do
    it "returns minLength value" do
      simple_type.add_facet({ type: :minLength, value: "5" })
      expect(simple_type.min_length).to eq("5")
    end

    it "returns nil when no minLength" do
      expect(simple_type.min_length).to be_nil
    end
  end

  describe "#max_length" do
    it "returns maxLength value" do
      simple_type.add_facet({ type: :maxLength, value: "100" })
      expect(simple_type.max_length).to eq("100")
    end

    it "returns nil when no maxLength" do
      expect(simple_type.max_length).to be_nil
    end
  end

  describe "#length" do
    it "returns length value" do
      simple_type.add_facet({ type: :length, value: "10" })
      expect(simple_type.length).to eq("10")
    end

    it "returns nil when no length" do
      expect(simple_type.length).to be_nil
    end
  end

  describe "#item_type" do
    context "for list variety" do
      it "allows setting item type" do
        simple_type.variety = :list
        simple_type.item_type = "xs:string"
        expect(simple_type.item_type).to eq("xs:string")
      end

      it "defaults to nil" do
        expect(simple_type.item_type).to be_nil
      end
    end
  end

  describe "#member_types" do
    context "for union variety" do
      it "returns array of member types" do
        expect(simple_type.member_types).to be_an(Array)
      end

      it "initializes as empty array" do
        expect(simple_type.member_types).to be_empty
      end

      it "allows adding member types" do
        simple_type.variety = :union
        simple_type.member_types << "xs:string"
        simple_type.member_types << "xs:integer"
        expect(simple_type.member_types).to eq(%w[xs:string xs:integer])
      end
    end
  end

  describe "#add_member_type" do
    it "adds member type to array" do
      simple_type.add_member_type("xs:string")
      expect(simple_type.member_types).to include("xs:string")
    end

    it "returns the member type" do
      result = simple_type.add_member_type("xs:integer")
      expect(result).to eq("xs:integer")
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
          attributes: { "final" => "restriction" },
          annotation: nil
        )
      end

      let(:final_type) do
        described_class.new(
          name: "FinalType",
          type: "simpleType",
          xsd_node: final_node
        )
      end

      it "returns final value" do
        expect(final_type.final).to eq("restriction")
      end
    end

    context "when no final attribute" do
      it "returns nil" do
        expect(simple_type.final).to be_nil
      end
    end
  end

  describe "#primitive_type" do
    it "allows setting primitive type" do
      simple_type.primitive_type = "string"
      expect(simple_type.primitive_type).to eq("string")
    end

    it "defaults to nil" do
      expect(simple_type.primitive_type).to be_nil
    end

    it "accepts common primitive types" do
      primitives = %w[
        string boolean decimal float double
        duration dateTime time date
        anyURI QName NOTATION
      ]

      primitives.each do |prim|
        simple_type.primitive_type = prim
        expect(simple_type.primitive_type).to eq(prim)
      end
    end
  end

  describe "#built_in?" do
    it "returns true for built-in types" do
      built_in_node = double(
        "BuiltInNode",
        name: "string",
        namespace: "http://www.w3.org/2001/XMLSchema",
        namespace_prefix: "xs",
        attributes: {},
        annotation: nil
      )
      built_in = described_class.new(
        name: "string",
        type: "simpleType",
        xsd_node: built_in_node
      )

      expect(built_in.built_in?).to be true
    end

    it "returns false for user-defined types" do
      expect(simple_type.built_in?).to be false
    end
  end

  describe "visual representation" do
    describe "#calculate_bounds" do
      it "calculates width based on type name" do
        expect(simple_type.width).to be > 80
      end

      it "adjusts for variety" do
        simple_type.variety = :restriction
        expect(simple_type.width).to be > 100
      end

      it "has reasonable default height" do
        expect(simple_type.height).to be > 30
      end
    end

    describe "#display_label" do
      it "includes type name" do
        expect(simple_type.display_label).to include("CodeType")
      end

      context "with restriction" do
        it "includes base type" do
          simple_type.variety = :restriction
          simple_type.base_type = "xs:string"
          label = simple_type.display_label
          expect(label).to match(/restriction/i)
          expect(label).to include("xs:string")
        end
      end

      context "with list" do
        it "includes item type" do
          simple_type.variety = :list
          simple_type.item_type = "xs:integer"
          label = simple_type.display_label
          expect(label).to match(/list/i)
          expect(label).to include("xs:integer")
        end
      end

      context "with union" do
        it "includes member types count" do
          simple_type.variety = :union
          simple_type.add_member_type("xs:string")
          simple_type.add_member_type("xs:integer")
          label = simple_type.display_label
          expect(label).to match(/union/i)
        end
      end

      context "with enumerations" do
        it "shows enumeration count" do
          3.times do |i|
            simple_type.add_facet({ type: :enumeration, value: "VAL#{i}" })
          end
          label = simple_type.display_label
          expect(label).to match(/3.*enum/i)
        end
      end
    end

    describe "#facet_summary" do
      it "summarizes all facets" do
        simple_type.add_facet({ type: :minLength, value: "1" })
        simple_type.add_facet({ type: :maxLength, value: "100" })
        simple_type.add_facet({ type: :pattern, value: "[A-Z]+" })

        summary = simple_type.facet_summary
        expect(summary).to be_a(String)
        expect(summary).to include("minLength")
        expect(summary).to include("maxLength")
        expect(summary).to include("pattern")
      end

      it "returns empty string when no facets" do
        expect(simple_type.facet_summary).to eq("")
      end
    end
  end

  describe "#resolve_base_type" do
    let(:type_registry) do
      {
        "xs:string" => double("StringType", name: "string"),
        "custom:CustomType" => double("CustomType", name: "CustomType")
      }
    end

    context "when base_type exists in registry" do
      it "returns resolved type symbol" do
        simple_type.base_type = "xs:string"
        resolved = simple_type.resolve_base_type(type_registry)
        expect(resolved.name).to eq("string")
      end
    end

    context "when base_type does not exist" do
      it "returns nil" do
        simple_type.base_type = "unknown:Type"
        expect(simple_type.resolve_base_type(type_registry)).to be_nil
      end
    end

    context "when has no base_type" do
      it "returns nil" do
        expect(simple_type.resolve_base_type(type_registry)).to be_nil
      end
    end
  end
end
