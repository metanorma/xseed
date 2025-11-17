# frozen_string_literal: true

require "spec_helper"
require "xseed/svg/svg_renderer"
require "xseed/svg/symbol"

RSpec.describe Xseed::Svg::SvgRenderer, "P1 Features" do
  let(:mock_xsd_node) do
    double("xsd_node",
           name: "element",
           namespace: "http://example.com",
           namespace_prefix: "ex",
           attributes: {},
           annotation: nil)
  end

  describe "Feature 3: Attribute Property Styling" do
    context "with required attribute" do
      let(:required_attr_node) do
        double("xsd_node",
               name: "attribute",
               attributes: { "use" => "required", "name" => "id" },
               annotation: nil)
      end

      let(:attribute) do
        Xseed::Svg::Symbol::AttributeSymbol.new(
          name: "id",
          type: "attribute",
          xsd_node: required_attr_node
        )
      end

      let(:renderer) { described_class.new(attribute) }

      it "renders attribute with required styling" do
        svg_output = renderer.render
        expect(svg_output).to include("attribute-required")
        # Required attributes should not have inline stroke-dasharray style
        expect(svg_output).not_to include("style=\"stroke-dasharray: 4,2;\"")
      end
    end

    context "with optional attribute" do
      let(:optional_attr_node) do
        double("xsd_node",
               name: "attribute",
               attributes: { "use" => "optional", "name" => "title" },
               annotation: nil)
      end

      let(:attribute) do
        Xseed::Svg::Symbol::AttributeSymbol.new(
          name: "title",
          type: "attribute",
          xsd_node: optional_attr_node
        )
      end

      let(:renderer) { described_class.new(attribute) }

      it "renders attribute with optional styling (dashed)" do
        svg_output = renderer.render
        expect(svg_output).to include("attribute-optional")
      end
    end
  end

  describe "Feature 4: Element Properties Display" do
    context "with nillable element" do
      let(:nillable_node) do
        double("xsd_node",
               name: "element",
               attributes: {
                 "name" => "data",
                 "nillable" => "true"
               },
               annotation: nil)
      end

      let(:element) do
        Xseed::Svg::Symbol::ElementSymbol.new(
          name: "data",
          type: "element",
          xsd_node: nillable_node
        )
      end

      let(:renderer) { described_class.new(element) }

      it "renders nillable property indicator" do
        svg_output = renderer.render
        expect(svg_output).to include("nillable")
        expect(svg_output).to include("element-properties")
      end
    end

    context "with abstract element" do
      let(:abstract_node) do
        double("xsd_node",
               name: "element",
               attributes: {
                 "name" => "baseElement",
                 "abstract" => "true"
               },
               annotation: nil)
      end

      let(:element) do
        Xseed::Svg::Symbol::ElementSymbol.new(
          name: "baseElement",
          type: "element",
          xsd_node: abstract_node
        )
      end

      let(:renderer) { described_class.new(element) }

      it "renders abstract property indicator" do
        svg_output = renderer.render
        expect(svg_output).to include("abstract")
        expect(svg_output).to include("element-properties")
      end
    end

    context "with substitution group" do
      let(:subst_node) do
        double("xsd_node",
               name: "element",
               attributes: {
                 "name" => "derivedElement",
                 "substitutionGroup" => "baseElement"
               },
               annotation: nil)
      end

      let(:element) do
        Xseed::Svg::Symbol::ElementSymbol.new(
          name: "derivedElement",
          type: "element",
          xsd_node: subst_node
        )
      end

      let(:renderer) { described_class.new(element) }

      it "renders substitution group reference" do
        svg_output = renderer.render
        expect(svg_output).to include("→baseElement")
        expect(svg_output).to include("element-properties")
      end
    end
  end

  describe "Feature 5: Compositor Connection Circles" do
    let(:sequence_node) do
      double("xsd_node",
             name: "sequence",
             attributes: {},
             annotation: nil)
    end

    let(:sequence) do
      Xseed::Svg::Symbol::SequenceSymbol.new(
        name: "sequence",
        type: "sequence",
        xsd_node: sequence_node
      )
    end

    let(:child_node) do
      double("xsd_node",
             name: "element",
             attributes: { "name" => "child" },
             annotation: nil)
    end

    before do
      # Add some children to the sequence
      3.times do |i|
        child = Xseed::Svg::Symbol::ElementSymbol.new(
          name: "child#{i}",
          type: "element",
          xsd_node: child_node
        )
        sequence.add_child(child)
      end
    end

    let(:renderer) { described_class.new(sequence) }

    it "renders compositor connection circles" do
      svg_output = renderer.render
      expect(svg_output).to include("compositor-output")
      # Should have circles for connections
      expect(svg_output.scan(/compositor-output/).count).to be >= 3
    end

    it "renders vertical line connecting circles" do
      svg_output = renderer.render
      expect(svg_output).to include("compositor-line")
    end
  end

  describe "Feature 7: ProcessContents Indicators" do
    %w[strict lax skip].each do |process_contents|
      context "with processContents='#{process_contents}'" do
        let(:any_attr_node) do
          double("xsd_node",
                 name: "anyAttribute",
                 attributes: {
                   "namespace" => "##other",
                   "processContents" => process_contents
                 })
        end

        let(:any_attribute) do
          Xseed::Svg::Symbol::AnyAttributeSymbol.new(xsd_node: any_attr_node)
        end

        let(:renderer) { described_class.new(any_attribute) }

        it "renders processContents indicator square" do
          svg_output = renderer.render
          # Check for rect element with specific colors
          color = case process_contents
                  when "strict" then "#FF0000"
                  when "lax" then "#FFFF00"
                  when "skip" then "#00FF00"
                  end
          expect(svg_output).to include(color)
        end
      end
    end
  end

  describe "Feature 8: Optional Element Styling" do
    context "with optional element (minOccurs=0)" do
      let(:optional_node) do
        double("xsd_node",
               name: "element",
               attributes: {
                 "name" => "optionalField",
                 "minOccurs" => "0"
               },
               annotation: nil)
      end

      let(:element) do
        Xseed::Svg::Symbol::ElementSymbol.new(
          name: "optionalField",
          type: "element",
          xsd_node: optional_node
        )
      end

      let(:renderer) { described_class.new(element) }

      it "renders element with dashed border" do
        svg_output = renderer.render
        expect(svg_output).to include("stroke-dasharray: 4,2")
      end
    end

    context "with required element (minOccurs=1)" do
      let(:required_node) do
        double("xsd_node",
               name: "element",
               attributes: {
                 "name" => "requiredField",
                 "minOccurs" => "1"
               },
               annotation: nil)
      end

      let(:element) do
        Xseed::Svg::Symbol::ElementSymbol.new(
          name: "requiredField",
          type: "element",
          xsd_node: required_node
        )
      end

      let(:renderer) { described_class.new(element) }

      it "renders element with solid border" do
        svg_output = renderer.render
        # Required elements (minOccurs=1) should not have inline dashed style
        expect(svg_output).not_to include("style=\"stroke-dasharray: 4,2;\"")
      end
    end
  end

  describe "CSS Styles for P1 Features" do
    let(:renderer) { described_class.new(Xseed::Svg::Symbol::SchemaSymbol.new(name: "test", type: "schema", xsd_node: mock_xsd_node)) }

    it "includes attribute styling classes" do
      svg_output = renderer.render
      expect(svg_output).to include(".attribute-required")
      expect(svg_output).to include(".attribute-optional")
    end

    it "includes identity constraint styles" do
      svg_output = renderer.render
      expect(svg_output).to include(".xsd-key")
      expect(svg_output).to include(".xsd-unique")
      expect(svg_output).to include(".xsd-keyref")
    end

    it "includes anyAttribute styles" do
      svg_output = renderer.render
      expect(svg_output).to include(".xsd-any-attribute")
    end
  end

  describe "Symbol Class Mapping" do
    let(:renderer) { described_class.new(mock_xsd_node) }

    it "maps key symbols correctly" do
      key_node = double("xsd_node", name: "key", attributes: {}, selector: nil, field: [])
      key_symbol = Xseed::Svg::Symbol::KeySymbol.new(name: "testKey", xsd_node: key_node)
      renderer_instance = described_class.new(key_symbol)

      svg = renderer_instance.render
      expect(svg).to include("xsd-key")
    end

    it "maps unique symbols correctly" do
      unique_node = double("xsd_node", name: "unique", attributes: {}, selector: nil, field: [])
      unique_symbol = Xseed::Svg::Symbol::UniqueSymbol.new(name: "testUnique", xsd_node: unique_node)
      renderer_instance = described_class.new(unique_symbol)

      svg = renderer_instance.render
      expect(svg).to include("xsd-unique")
    end

    it "maps keyref symbols correctly" do
      keyref_node = double("xsd_node", name: "keyref", attributes: {}, selector: nil, field: [])
      keyref_symbol = Xseed::Svg::Symbol::KeyrefSymbol.new(name: "testKeyref", xsd_node: keyref_node)
      renderer_instance = described_class.new(keyref_symbol)

      svg = renderer_instance.render
      expect(svg).to include("xsd-keyref")
    end

    it "maps anyAttribute symbols correctly" do
      any_attr_node = double("xsd_node", name: "anyAttribute", attributes: {})
      any_attr_symbol = Xseed::Svg::Symbol::AnyAttributeSymbol.new(xsd_node: any_attr_node)
      renderer_instance = described_class.new(any_attr_symbol)

      svg = renderer_instance.render
      expect(svg).to include("xsd-any-attribute")
    end
  end
end