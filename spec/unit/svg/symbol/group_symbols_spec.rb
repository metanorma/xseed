# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Group Symbols" do
  let(:base_xsd_node) do
    double(
      "XsdNode",
      name: "testGroup",
      namespace: "http://example.com",
      namespace_prefix: nil,
      attributes: {},
      annotation: nil
    )
  end

  describe Xseed::Svg::Symbol::SequenceSymbol do
    let(:sequence) do
      described_class.new(
        name: "sequence",
        type: "sequence",
        xsd_node: base_xsd_node
      )
    end

    it "inherits from Base" do
      expect(sequence).to be_a(Xseed::Svg::Symbol::Base)
    end

    describe "#compositor_type" do
      it "returns :sequence" do
        expect(sequence.compositor_type).to eq(:sequence)
      end
    end

    describe "#ordered?" do
      it "returns true for sequence" do
        expect(sequence.ordered?).to be true
      end
    end

    describe "#display_label" do
      it "indicates sequence" do
        expect(sequence.display_label).to match(/sequence/i)
      end
    end
  end

  describe Xseed::Svg::Symbol::ChoiceSymbol do
    let(:choice) do
      described_class.new(
        name: "choice",
        type: "choice",
        xsd_node: base_xsd_node
      )
    end

    it "inherits from Base" do
      expect(choice).to be_a(Xseed::Svg::Symbol::Base)
    end

    describe "#compositor_type" do
      it "returns :choice" do
        expect(choice.compositor_type).to eq(:choice)
      end
    end

    describe "#ordered?" do
      it "returns false for choice" do
        expect(choice.ordered?).to be false
      end
    end

    describe "#exclusive?" do
      it "returns true for choice" do
        expect(choice.exclusive?).to be true
      end
    end

    describe "#display_label" do
      it "indicates choice" do
        expect(choice.display_label).to match(/choice/i)
      end
    end
  end

  describe Xseed::Svg::Symbol::AllSymbol do
    let(:all_group) do
      described_class.new(
        name: "all",
        type: "all",
        xsd_node: base_xsd_node
      )
    end

    it "inherits from Base" do
      expect(all_group).to be_a(Xseed::Svg::Symbol::Base)
    end

    describe "#compositor_type" do
      it "returns :all" do
        expect(all_group.compositor_type).to eq(:all)
      end
    end

    describe "#ordered?" do
      it "returns false for all" do
        expect(all_group.ordered?).to be false
      end
    end

    describe "#all_required?" do
      it "returns true for all group" do
        expect(all_group.all_required?).to be true
      end
    end

    describe "#display_label" do
      it "indicates all group" do
        expect(all_group.display_label).to match(/all/i)
      end
    end
  end

  describe Xseed::Svg::Symbol::GroupSymbol do
    let(:group_node) do
      double(
        "GroupNode",
        name: "PersonGroup",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: { "ref" => "common:PersonGroup" },
        annotation: nil
      )
    end

    let(:group) do
      described_class.new(
        name: "PersonGroup",
        type: "group",
        xsd_node: group_node
      )
    end

    it "inherits from Base" do
      expect(group).to be_a(Xseed::Svg::Symbol::Base)
    end

    describe "#ref" do
      it "returns ref attribute" do
        expect(group.ref).to eq("common:PersonGroup")
      end

      context "when no ref" do
        let(:no_ref_node) do
          double(
            "NoRefNode",
            name: "LocalGroup",
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: {},
            annotation: nil
          )
        end

        let(:local_group) do
          described_class.new(
            name: "LocalGroup",
            type: "group",
            xsd_node: no_ref_node
          )
        end

        it "returns nil" do
          expect(local_group.ref).to be_nil
        end
      end
    end

    describe "#is_reference?" do
      it "returns true when has ref" do
        expect(group.is_reference?).to be true
      end

      it "returns false when no ref" do
        no_ref_node = double(
          "NoRefNode",
          name: "LocalGroup",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: {},
          annotation: nil
        )
        local_group = described_class.new(
          name: "LocalGroup",
          type: "group",
          xsd_node: no_ref_node
        )
        expect(local_group.is_reference?).to be false
      end
    end

    describe "#resolve_reference" do
      let(:group_registry) do
        {
          "common:PersonGroup" => double("ResolvedGroup", name: "PersonGroup")
        }
      end

      it "resolves group reference" do
        resolved = group.resolve_reference(group_registry)
        expect(resolved.name).to eq("PersonGroup")
      end

      it "returns nil when reference not found" do
        empty_registry = {}
        expect(group.resolve_reference(empty_registry)).to be_nil
      end
    end

    describe "#display_label" do
      it "includes group name" do
        expect(group.display_label).to include("PersonGroup")
      end

      it "indicates reference" do
        expect(group.display_label).to match(/ref|→/)
      end
    end
  end

  describe Xseed::Svg::Symbol::AttributeGroupSymbol do
    let(:attr_group_node) do
      double(
        "AttributeGroupNode",
        name: "CommonAttributes",
        namespace: "http://example.com",
        namespace_prefix: nil,
        attributes: {},
        annotation: nil
      )
    end

    let(:attr_group) do
      described_class.new(
        name: "CommonAttributes",
        type: "attributeGroup",
        xsd_node: attr_group_node
      )
    end

    it "inherits from Base" do
      expect(attr_group).to be_a(Xseed::Svg::Symbol::Base)
    end

    describe "#attributes" do
      it "returns array of attributes" do
        expect(attr_group.attributes).to be_an(Array)
      end

      it "initializes as empty" do
        expect(attr_group.attributes).to be_empty
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

      it "adds attribute to group" do
        attr_group.add_attribute(attr_symbol)
        expect(attr_group.attributes).to include(attr_symbol)
      end

      it "returns the attribute" do
        result = attr_group.add_attribute(attr_symbol)
        expect(result).to eq(attr_symbol)
      end
    end

    describe "#has_attributes?" do
      it "returns false when no attributes" do
        expect(attr_group.has_attributes?).to be false
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
        attr_group.add_attribute(attr_symbol)
        expect(attr_group.has_attributes?).to be true
      end
    end

    describe "#ref" do
      context "with ref attribute" do
        let(:ref_node) do
          double(
            "RefNode",
            name: nil,
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: { "ref" => "common:Attributes" },
            annotation: nil
          )
        end

        let(:ref_attr_group) do
          described_class.new(
            name: "refGroup",
            type: "attributeGroup",
            xsd_node: ref_node
          )
        end

        it "returns ref value" do
          expect(ref_attr_group.ref).to eq("common:Attributes")
        end
      end

      context "without ref" do
        it "returns nil" do
          expect(attr_group.ref).to be_nil
        end
      end
    end

    describe "#is_reference?" do
      it "returns false when no ref" do
        expect(attr_group.is_reference?).to be false
      end

      it "returns true when has ref" do
        ref_node = double(
          "RefNode",
          name: nil,
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "ref" => "common:Attributes" },
          annotation: nil
        )
        ref_attr_group = described_class.new(
          name: "refGroup",
          type: "attributeGroup",
          xsd_node: ref_node
        )
        expect(ref_attr_group.is_reference?).to be true
      end
    end

    describe "#display_label" do
      it "includes group name" do
        expect(attr_group.display_label).to include("CommonAttributes")
      end

      it "indicates attribute group" do
        expect(attr_group.display_label).to match(/attribute.*group/i)
      end
    end
  end

  describe "Common Group Behavior" do
    shared_examples "a group compositor" do |symbol_class, type|
      let(:group) do
        symbol_class.new(
          name: type,
          type: type,
          xsd_node: base_xsd_node
        )
      end

      describe "#min_occurs" do
        it "extracts from xsd_node" do
          node = double(
            "Node",
            name: type,
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: { "minOccurs" => "0" },
            annotation: nil
          )
          grp = symbol_class.new(name: type, type: type, xsd_node: node)
          expect(grp.min_occurs).to eq(0)
        end

        it "defaults to 1" do
          expect(group.min_occurs).to eq(1)
        end
      end

      describe "#max_occurs" do
        it "extracts from xsd_node" do
          node = double(
            "Node",
            name: type,
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: { "maxOccurs" => "unbounded" },
            annotation: nil
          )
          grp = symbol_class.new(name: type, type: type, xsd_node: node)
          expect(grp.max_occurs).to eq(Float::INFINITY)
        end

        it "defaults to 1" do
          expect(group.max_occurs).to eq(1)
        end
      end

      describe "#optional?" do
        it "returns true when minOccurs is 0" do
          node = double(
            "Node",
            name: type,
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: { "minOccurs" => "0" },
            annotation: nil
          )
          grp = symbol_class.new(name: type, type: type, xsd_node: node)
          expect(grp.optional?).to be true
        end

        it "returns false when minOccurs is 1" do
          expect(group.optional?).to be false
        end
      end

      describe "#repeatable?" do
        it "returns true when maxOccurs > 1" do
          node = double(
            "Node",
            name: type,
            namespace: "http://example.com",
            namespace_prefix: nil,
            attributes: { "maxOccurs" => "5" },
            annotation: nil
          )
          grp = symbol_class.new(name: type, type: type, xsd_node: node)
          expect(grp.repeatable?).to be true
        end

        it "returns false when maxOccurs is 1" do
          expect(group.repeatable?).to be false
        end
      end
    end

    describe Xseed::Svg::Symbol::SequenceSymbol do
      it_behaves_like "a group compositor",
                      described_class,
                      "sequence"
    end

    describe Xseed::Svg::Symbol::ChoiceSymbol do
      it_behaves_like "a group compositor",
                      described_class,
                      "choice"
    end

    describe Xseed::Svg::Symbol::AllSymbol do
      it_behaves_like "a group compositor",
                      described_class,
                      "all"
    end
  end
end
