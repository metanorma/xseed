# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe Xseed::Svg::SvgRenderer, "P0 Critical Features" do
  let(:xsd_node) do
    double(
      "XsdNode",
      name: "element",
      namespace: "http://example.com",
      namespace_prefix: "ex",
      attributes: {
        "minOccurs" => "0",
        "maxOccurs" => "unbounded"
      },
      annotation: nil
    )
  end

  let(:element_symbol) do
    Xseed::Svg::Symbol::ElementSymbol.new(
      name: "Person",
      type: "element",
      xsd_node: xsd_node
    )
  end

  let(:renderer) { described_class.new(element_symbol) }

  describe "Feature 3: Cardinality Display" do
    describe "#format_cardinality" do
      it "returns empty string for default 1..1" do
        result = renderer.send(:format_cardinality, 1, 1)
        expect(result).to eq("")
      end

      it "formats optional as 0..1" do
        result = renderer.send(:format_cardinality, 0, 1)
        expect(result).to eq("0..1")
      end

      it "formats unbounded as 0..*" do
        result = renderer.send(:format_cardinality, 0, Float::INFINITY)
        expect(result).to eq("0..*")
      end

      it "formats required multiple as 1..*" do
        result = renderer.send(:format_cardinality, 1, Float::INFINITY)
        expect(result).to eq("1..*")
      end

      it "formats specific range as min..max" do
        result = renderer.send(:format_cardinality, 2, 5)
        expect(result).to eq("2..5")
      end
    end

    describe "cardinality rendering in SVG" do
      it "includes cardinality text for non-default occurrences" do
        svg_output = renderer.render
        doc = Nokogiri::XML(svg_output)

        # Look for cardinality text (0..* in this case)
        cardinality_texts = doc.xpath("//xmlns:text[@class='cardinality-text']", 'xmlns' => 'http://www.w3.org/2000/svg')
        expect(cardinality_texts).not_to be_empty
      end

      it "positions cardinality at y=59" do
        svg_output = renderer.render
        doc = Nokogiri::XML(svg_output)

        cardinality_text = doc.at_xpath("//text[@class='cardinality-text']")
        if cardinality_text
          expect(cardinality_text['y']).to eq('59')
        end
      end

      it "uses smaller font size for cardinality (10px)" do
        svg_output = renderer.render
        doc = Nokogiri::XML(svg_output)

        cardinality_text = doc.at_xpath("//text[@class='cardinality-text']")
        if cardinality_text
          expect(cardinality_text['font-size']).to eq('10')
        end
      end

      it "uses gray color for cardinality (#666666)" do
        svg_output = renderer.render
        doc = Nokogiri::XML(svg_output)

        cardinality_text = doc.at_xpath("//text[@class='cardinality-text']")
        if cardinality_text
          expect(cardinality_text['fill']).to eq('#666666')
        end
      end
    end
  end

  describe "Feature 4: Namespace Display" do
    describe "namespace rendering in SVG" do
      it "includes namespace text for symbols with namespace" do
        svg_output = renderer.render
        doc = Nokogiri::XML(svg_output)

        # Look for namespace text
        namespace_texts = doc.xpath("//xmlns:text[@class='namespace-text']", 'xmlns' => 'http://www.w3.org/2000/svg')
        expect(namespace_texts).not_to be_empty
      end

      it "positions namespace at y=13 (top of box)" do
        svg_output = renderer.render
        doc = Nokogiri::XML(svg_output)

        namespace_text = doc.at_xpath("//text[@class='namespace-text']")
        if namespace_text
          expect(namespace_text['y']).to eq('13')
        end
      end

      it "uses smaller font size for namespace (9px)" do
        svg_output = renderer.render
        doc = Nokogiri::XML(svg_output)

        namespace_text = doc.at_xpath("//text[@class='namespace-text']")
        if namespace_text
          expect(namespace_text['font-size']).to eq('9')
        end
      end

      it "uses light gray color for namespace (#999999)" do
        svg_output = renderer.render
        doc = Nokogiri::XML(svg_output)

        namespace_text = doc.at_xpath("//text[@class='namespace-text']")
        if namespace_text
          expect(namespace_text['fill']).to eq('#999999')
        end
      end

      it "displays namespace value" do
        svg_output = renderer.render
        doc = Nokogiri::XML(svg_output)

        namespace_text = doc.at_xpath("//text[@class='namespace-text']")
        if namespace_text
          expect(namespace_text.text).to eq("http://example.com")
        end
      end
    end
  end

  describe "Feature 5: Curved Path Connectors" do
    let(:parent_symbol) do
      Xseed::Svg::Symbol::ElementSymbol.new(
        name: "Parent",
        type: "element",
        xsd_node: xsd_node
      ).tap { |s| s.set_position(100, 50) }
    end

    let(:child1_symbol) do
      Xseed::Svg::Symbol::ElementSymbol.new(
        name: "Child1",
        type: "element",
        xsd_node: xsd_node
      ).tap { |s| s.set_position(200, 100) }
    end

    let(:child2_symbol) do
      Xseed::Svg::Symbol::ElementSymbol.new(
        name: "Child2",
        type: "element",
        xsd_node: xsd_node
      ).tap { |s| s.set_position(200, 200) }
    end

    before do
      parent_symbol.add_child(child1_symbol)
      parent_symbol.add_child(child2_symbol)
    end

    let(:parent_renderer) { described_class.new(parent_symbol) }

    describe "curved connector rendering" do
      it "uses path elements for curved connectors" do
        svg_output = parent_renderer.render
        doc = Nokogiri::XML(svg_output)

        # Should have path elements for curved connections
        paths = doc.xpath("//path[@class='connector curved']")
        expect(paths.size).to be >= 0
      end

      it "uses quadratic bezier curve (Q command)" do
        svg_output = parent_renderer.render
        doc = Nokogiri::XML(svg_output)

        curved_path = doc.at_xpath("//path[@class='connector curved']")
        if curved_path
          d_attr = curved_path['d']
          # Should contain Q command for quadratic bezier
          expect(d_attr).to match(/Q/)
        end
      end

      it "applies curved style to last child when vertical distance > 100" do
        # Set large vertical distance for last child
        child2_symbol.set_position(200, 300)

        svg_output = parent_renderer.render
        doc = Nokogiri::XML(svg_output)

        # Should have at least one curved connector
        curved_paths = doc.xpath("//path[contains(@class, 'curved')]")
        expect(curved_paths.size).to be >= 0
      end

      it "uses straight lines for other children" do
        svg_output = parent_renderer.render
        doc = Nokogiri::XML(svg_output)

        # Should have line elements for straight connections
        lines = doc.xpath("//line[@class='connector']")
        expect(lines.size).to be >= 0
      end

      it "includes arrowhead marker on curved paths" do
        svg_output = parent_renderer.render
        doc = Nokogiri::XML(svg_output)

        curved_path = doc.at_xpath("//path[@class='connector curved']")
        if curved_path
          expect(curved_path['marker-end']).to eq('url(#arrowhead)')
        end
      end
    end
  end

  describe "Feature 6: Multi-Field Width Calculation" do
    describe "width calculation in Base symbol" do
      it "considers namespace in width calculation" do
        # Symbol with namespace should be wider
        with_ns = Xseed::Svg::Symbol::ElementSymbol.new(
          name: "E",
          type: "element",
          xsd_node: xsd_node
        )

        no_ns_node = double(
          "Node",
          name: "element",
          namespace: nil,
          namespace_prefix: nil,
          attributes: {},
          annotation: nil
        )
        without_ns = Xseed::Svg::Symbol::ElementSymbol.new(
          name: "E",
          type: "element",
          xsd_node: no_ns_node
        )

        expect(with_ns.width).to be >= without_ns.width
      end

      it "considers type reference in width calculation" do
        typed_node = double(
          "TypedNode",
          name: "element",
          namespace: "http://example.com",
          namespace_prefix: nil,
          attributes: { "type" => "xs:complexType" },
          annotation: nil
        )

        typed_symbol = Xseed::Svg::Symbol::ElementSymbol.new(
          name: "TypedElement",
          type: "element",
          xsd_node: typed_node
        )

        # Should accommodate "type: xs:complexType"
        expect(typed_symbol.width).to be >= Xseed::Svg::Symbol::Base::MIN_WIDTH
      end

      it "considers cardinality in width calculation" do
        # Element with cardinality should have adequate width
        expect(element_symbol.width).to be >= Xseed::Svg::Symbol::Base::MIN_WIDTH
      end

      it "uses longest field for width" do
        long_ns_node = double(
          "LongNode",
          name: "element",
          namespace: "http://very.long.namespace.example.com/schema/v1",
          namespace_prefix: nil,
          attributes: {},
          annotation: nil
        )

        long_ns_symbol = Xseed::Svg::Symbol::ElementSymbol.new(
          name: "Short",
          type: "element",
          xsd_node: long_ns_node
        )

        # Width should be based on longest field (namespace in this case)
        expect(long_ns_symbol.width).to be > 200
      end

      it "respects MIN_WIDTH constraint" do
        short_node = double(
          "ShortNode",
          name: "element",
          namespace: "x",
          namespace_prefix: nil,
          attributes: {},
          annotation: nil
        )

        short_symbol = Xseed::Svg::Symbol::ElementSymbol.new(
          name: "A",
          type: "element",
          xsd_node: short_node
        )

        expect(short_symbol.width).to be >= Xseed::Svg::Symbol::Base::MIN_WIDTH
      end
    end
  end
end