# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Advanced Symbols" do
  let(:base_xsd_node) do
    double(
      "XsdNode",
      name: "testSymbol",
      namespace: "http://example.com",
      namespace_prefix: nil,
      attributes: {},
      annotation: nil
    )
  end

  describe Xseed::Svg::Symbol::ExtensionSymbol do
    let(:extension_node) do
      double(
        "ExtensionNode",
        name: "extension",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: { "base" => "xs:string" },
        annotation: nil
      )
    end

    let(:extension) do
      described_class.new(
        name: "extension",
        type: "extension",
        xsd_node: extension_node
      )
    end

    it "inherits from Base" do
      expect(extension).to be_a(Xseed::Svg::Symbol::Base)
    end

    describe "#base_type" do
      it "returns base type reference" do
        expect(extension.base_type).to eq("xs:string")
      end
    end

    describe "#derivation_method" do
      it "returns :extension" do
        expect(extension.derivation_method).to eq(:extension)
      end
    end

    describe "#resolve_base_type" do
      let(:type_registry) do
        {
          "xs:string" => double("StringType", name: "string")
        }
      end

      it "resolves base type from registry" do
        resolved = extension.resolve_base_type(type_registry)
        expect(resolved.name).to eq("string")
      end

      it "returns nil when not found" do
        expect(extension.resolve_base_type({})).to be_nil
      end
    end

    describe "#display_label" do
      it "indicates extension" do
        expect(extension.display_label).to match(/extension/i)
      end

      it "shows base type" do
        expect(extension.display_label).to include("xs:string")
      end
    end
  end

  describe Xseed::Svg::Symbol::RestrictionSymbol do
    let(:restriction_node) do
      double(
        "RestrictionNode",
        name: "restriction",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: { "base" => "xs:integer" },
        annotation: nil
      )
    end

    let(:restriction) do
      described_class.new(
        name: "restriction",
        type: "restriction",
        xsd_node: restriction_node
      )
    end

    it "inherits from Base" do
      expect(restriction).to be_a(Xseed::Svg::Symbol::Base)
    end

    describe "#base_type" do
      it "returns base type reference" do
        expect(restriction.base_type).to eq("xs:integer")
      end
    end

    describe "#derivation_method" do
      it "returns :restriction" do
        expect(restriction.derivation_method).to eq(:restriction)
      end
    end

    describe "#facets" do
      it "returns array of facets" do
        expect(restriction.facets).to be_an(Array)
      end

      it "initializes as empty" do
        expect(restriction.facets).to be_empty
      end
    end

    describe "#add_facet" do
      it "adds facet to restriction" do
        facet = { type: :minInclusive, value: "0" }
        restriction.add_facet(facet)
        expect(restriction.facets).to include(facet)
      end
    end

    describe "#has_facets?" do
      it "returns false when no facets" do
        expect(restriction.has_facets?).to be false
      end

      it "returns true when has facets" do
        restriction.add_facet({ type: :minInclusive, value: "0" })
        expect(restriction.has_facets?).to be true
      end
    end

    describe "#display_label" do
      it "indicates restriction" do
        expect(restriction.display_label).to match(/restriction/i)
      end

      it "shows base type" do
        expect(restriction.display_label).to include("xs:integer")
      end

      context "with facets" do
        it "indicates facet count" do
          3.times do |i|
            restriction.add_facet({ type: :enumeration, value: i.to_s })
          end
          expect(restriction.display_label).to match(/facet|constraint/)
        end
      end
    end
  end

  describe Xseed::Svg::Symbol::UnionSymbol do
    let(:union_node) do
      double(
        "UnionNode",
        name: "union",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: { "memberTypes" => "xs:string xs:integer" },
        annotation: nil
      )
    end

    let(:union) do
      described_class.new(
        name: "union",
        type: "union",
        xsd_node: union_node
      )
    end

    it "inherits from Base" do
      expect(union).to be_a(Xseed::Svg::Symbol::Base)
    end

    describe "#member_types" do
      it "returns array of member types" do
        expect(union.member_types).to be_an(Array)
      end

      it "parses memberTypes attribute" do
        expect(union.member_types).to include("xs:string", "xs:integer")
      end

      context "without memberTypes attribute" do
        let(:no_members_node) do
          double(
            "NoMembersNode",
            name: "union",
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: {},
            annotation: nil
          )
        end

        let(:no_members_union) do
          described_class.new(
            name: "union",
            type: "union",
            xsd_node: no_members_node
          )
        end

        it "initializes as empty array" do
          expect(no_members_union.member_types).to be_empty
        end
      end
    end

    describe "#add_member_type" do
      it "adds member type to list" do
        union.add_member_type("xs:boolean")
        expect(union.member_types).to include("xs:boolean")
      end
    end

    describe "#resolve_member_types" do
      let(:type_registry) do
        {
          "xs:string" => double("StringType", name: "string"),
          "xs:integer" => double("IntegerType", name: "integer")
        }
      end

      it "resolves all member types" do
        resolved = union.resolve_member_types(type_registry)
        expect(resolved.map(&:name)).to contain_exactly("string", "integer")
      end

      it "skips unresolved types" do
        union.add_member_type("unknown:Type")
        resolved = union.resolve_member_types(type_registry)
        expect(resolved.size).to eq(2)
      end
    end

    describe "#display_label" do
      it "indicates union" do
        expect(union.display_label).to match(/union/i)
      end

      it "shows member count" do
        expect(union.display_label).to match(/2/)
      end
    end
  end

  describe Xseed::Svg::Symbol::ListSymbol do
    let(:list_node) do
      double(
        "ListNode",
        name: "list",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: { "itemType" => "xs:integer" },
        annotation: nil
      )
    end

    let(:list) do
      described_class.new(
        name: "list",
        type: "list",
        xsd_node: list_node
      )
    end

    it "inherits from Base" do
      expect(list).to be_a(Xseed::Svg::Symbol::Base)
    end

    describe "#item_type" do
      it "returns item type reference" do
        expect(list.item_type).to eq("xs:integer")
      end

      context "without itemType attribute" do
        let(:no_item_node) do
          double(
            "NoItemNode",
            name: "list",
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: {},
            annotation: nil
          )
        end

        let(:no_item_list) do
          described_class.new(
            name: "list",
            type: "list",
            xsd_node: no_item_node
          )
        end

        it "returns nil" do
          expect(no_item_list.item_type).to be_nil
        end
      end
    end

    describe "#resolve_item_type" do
      let(:type_registry) do
        {
          "xs:integer" => double("IntegerType", name: "integer")
        }
      end

      it "resolves item type from registry" do
        resolved = list.resolve_item_type(type_registry)
        expect(resolved.name).to eq("integer")
      end

      it "returns nil when not found" do
        expect(list.resolve_item_type({})).to be_nil
      end
    end

    describe "#display_label" do
      it "indicates list" do
        expect(list.display_label).to match(/list/i)
      end

      it "shows item type" do
        expect(list.display_label).to include("xs:integer")
      end
    end
  end

  describe Xseed::Svg::Symbol::NotationSymbol do
    let(:notation_node) do
      double(
        "NotationNode",
        name: "svg-image",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {
          "public" => "-//W3C//NOTATION SVG 1.0//EN",
          "system" => "http://www.w3.org/Graphics/SVG/"
        },
        annotation: nil
      )
    end

    let(:notation) do
      described_class.new(
        name: "svg-image",
        type: "notation",
        xsd_node: notation_node
      )
    end

    it "inherits from Base" do
      expect(notation).to be_a(Xseed::Svg::Symbol::Base)
    end

    describe "#public_id" do
      it "returns public identifier" do
        expect(notation.public_id).to eq("-//W3C//NOTATION SVG 1.0//EN")
      end

      context "without public attribute" do
        let(:no_public_node) do
          double(
            "NoPublicNode",
            name: "notation",
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: {},
            annotation: nil
          )
        end

        let(:no_public_notation) do
          described_class.new(
            name: "notation",
            type: "notation",
            xsd_node: no_public_node
          )
        end

        it "returns nil" do
          expect(no_public_notation.public_id).to be_nil
        end
      end
    end

    describe "#system_id" do
      it "returns system identifier" do
        expect(notation.system_id).to eq("http://www.w3.org/Graphics/SVG/")
      end

      context "without system attribute" do
        let(:no_system_node) do
          double(
            "NoSystemNode",
            name: "notation",
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: {},
            annotation: nil
          )
        end

        let(:no_system_notation) do
          described_class.new(
            name: "notation",
            type: "notation",
            xsd_node: no_system_node
          )
        end

        it "returns nil" do
          expect(no_system_notation.system_id).to be_nil
        end
      end
    end

    describe "#display_label" do
      it "includes notation name" do
        expect(notation.display_label).to include("svg-image")
      end

      it "indicates notation" do
        expect(notation.display_label).to match(/notation/i)
      end
    end
  end

  describe Xseed::Svg::Symbol::AnySymbol do
    let(:any_node) do
      double(
        "AnyNode",
        name: "any",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {
          "namespace" => "##any",
          "processContents" => "lax"
        },
        annotation: nil
      )
    end

    let(:any) do
      described_class.new(
        name: "any",
        type: "any",
        xsd_node: any_node
      )
    end

    it "inherits from Base" do
      expect(any).to be_a(Xseed::Svg::Symbol::Base)
    end

    describe "#wildcard_namespace" do
      it "returns namespace constraint" do
        expect(any.wildcard_namespace).to eq("##any")
      end

      context "without namespace attribute" do
        let(:no_ns_node) do
          double(
            "NoNsNode",
            name: "any",
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: {},
            annotation: nil
          )
        end

        let(:no_ns_any) do
          described_class.new(
            name: "any",
            type: "any",
            xsd_node: no_ns_node
          )
        end

        it "defaults to ##any" do
          expect(no_ns_any.wildcard_namespace).to eq("##any")
        end
      end
    end

    describe "#process_contents" do
      it "returns processContents value" do
        expect(any.process_contents).to eq("lax")
      end

      context "without processContents attribute" do
        let(:no_process_node) do
          double(
            "NoProcessNode",
            name: "any",
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: {},
            annotation: nil
          )
        end

        let(:no_process_any) do
          described_class.new(
            name: "any",
            type: "any",
            xsd_node: no_process_node
          )
        end

        it "defaults to strict" do
          expect(no_process_any.process_contents).to eq("strict")
        end
      end

      it "accepts valid process contents values" do
        %w[strict lax skip].each do |value|
          node = double(
            "Node",
            name: "any",
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: { "processContents" => value },
            annotation: nil
          )
          any_symbol = described_class.new(name: "any", type: "any",
                                           xsd_node: node)
          expect(any_symbol.process_contents).to eq(value)
        end
      end
    end

    describe "#min_occurs and #max_occurs" do
      it "extracts min_occurs" do
        node = double(
          "Node",
          name: "any",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "minOccurs" => "0" },
          annotation: nil
        )
        any_symbol = described_class.new(name: "any", type: "any",
                                         xsd_node: node)
        expect(any_symbol.min_occurs).to eq(0)
      end

      it "extracts max_occurs" do
        node = double(
          "Node",
          name: "any",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "maxOccurs" => "unbounded" },
          annotation: nil
        )
        any_symbol = described_class.new(name: "any", type: "any",
                                         xsd_node: node)
        expect(any_symbol.max_occurs).to eq(Float::INFINITY)
      end
    end

    describe "#accepts_namespace?" do
      context "with ##any" do
        it "accepts any namespace" do
          expect(any.accepts_namespace?("http://any.com")).to be true
        end
      end

      context "with ##other" do
        let(:other_node) do
          double(
            "OtherNode",
            name: "any",
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: { "namespace" => "##other" },
            annotation: nil
          )
        end

        let(:other_any) do
          described_class.new(
            name: "any",
            type: "any",
            xsd_node: other_node
          )
        end

        it "rejects target namespace" do
          expect(other_any.accepts_namespace?("http://example.com")).to be false
        end

        it "accepts other namespaces" do
          expect(other_any.accepts_namespace?("http://other.com")).to be true
        end
      end

      context "with specific namespace" do
        let(:specific_node) do
          double(
            "SpecificNode",
            name: "any",
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: { "namespace" => "http://allowed.com" },
            annotation: nil
          )
        end

        let(:specific_any) do
          described_class.new(
            name: "any",
            type: "any",
            xsd_node: specific_node
          )
        end

        it "accepts matching namespace" do
          expect(specific_any.accepts_namespace?("http://allowed.com")).to be true
        end

        it "rejects non-matching namespace" do
          expect(specific_any.accepts_namespace?("http://other.com")).to be false
        end
      end
    end

    describe "#display_label" do
      it "indicates wildcard" do
        expect(any.display_label).to match(/any|wildcard/i)
      end

      it "shows namespace constraint" do
        expect(any.display_label).to include("##any")
      end

      it "shows process contents" do
        expect(any.display_label).to include("lax")
      end
    end
  end
end
