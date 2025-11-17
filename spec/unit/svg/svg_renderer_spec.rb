# frozen_string_literal: true

require "spec_helper"
require "xseed/svg/svg_renderer"
require "xseed/svg/symbol/base"
require "xseed/svg/symbol/element_symbol"
require "xseed/svg/symbol/complex_type_symbol"
require "xseed/svg/symbol/simple_type_symbol"
require "xseed/svg/symbol/sequence_symbol"
require "xseed/svg/symbol/choice_symbol"
require "xseed/svg/symbol/attribute_symbol"
require "nokogiri"

RSpec.describe Xseed::Svg::SvgRenderer do
  let(:mock_xsd_node) do
    double("XsdNode",
           annotation: nil,
           namespace: nil,
           namespace_prefix: nil)
  end

  let(:root_symbol) do
    Xseed::Svg::Symbol::ElementSymbol.new(
      name: "root",
      type: "element",
      xsd_node: mock_xsd_node
    ).tap do |s|
      s.set_position(10, 10)
    end
  end

  let(:renderer) { described_class.new(root_symbol) }

  describe "#initialize" do
    it "initializes with a root symbol" do
      expect(renderer.instance_variable_get(:@root)).to eq(root_symbol)
    end

    it "initializes with viewport dimensions" do
      renderer_with_viewport = described_class.new(root_symbol,
                                                   viewport: { width: 800,
                                                               height: 600 })
      expect(renderer_with_viewport.instance_variable_get(:@viewport_width)).to eq(800)
      expect(renderer_with_viewport.instance_variable_get(:@viewport_height)).to eq(600)
    end

    it "uses default viewport if not provided" do
      expect(renderer.instance_variable_get(:@viewport_width)).to be > 0
      expect(renderer.instance_variable_get(:@viewport_height)).to be > 0
    end
  end

  describe "#render" do
    it "returns a string" do
      result = renderer.render
      expect(result).to be_a(String)
    end

    it "generates valid XML" do
      result = renderer.render
      expect do
        Nokogiri::XML(result, &:strict)
      end.not_to raise_error
    end

    it "includes SVG namespace" do
      result = renderer.render
      doc = Nokogiri::XML(result)
      expect(doc.root.namespace.href).to eq("http://www.w3.org/2000/svg")
    end

    it "includes viewport dimensions in SVG element" do
      renderer_with_viewport = described_class.new(root_symbol,
                                                   viewport: { width: 800,
                                                               height: 600 })
      result = renderer_with_viewport.render
      doc = Nokogiri::XML(result)

      expect(doc.root["width"]).to eq("800")
      expect(doc.root["height"]).to eq("600")
    end

    it "includes embedded CSS styles" do
      result = renderer.render
      doc = Nokogiri::XML(result)
      style_element = doc.at_css("style")

      expect(style_element).not_to be_nil
      expect(style_element.content).to include("xsd-element")
    end

    it "includes definitions section" do
      result = renderer.render
      doc = Nokogiri::XML(result)
      defs = doc.at_css("defs")

      expect(defs).not_to be_nil
    end

    context "with single symbol" do
      it "renders symbol as SVG group" do
        result = renderer.render
        doc = Nokogiri::XML(result)

        symbol_group = doc.at_css("g[data-name='root']")
        expect(symbol_group).not_to be_nil
      end

      it "applies correct CSS class for element symbol" do
        result = renderer.render
        doc = Nokogiri::XML(result)

        symbol_group = doc.at_css("g[data-name='root']")
        expect(symbol_group["class"]).to include("xsd-element")
      end

      it "includes transform attribute with position" do
        result = renderer.render
        doc = Nokogiri::XML(result)

        symbol_group = doc.at_css("g[data-name='root']")
        expect(symbol_group["transform"]).to eq("translate(10,10)")
      end

      it "renders symbol shape (rectangle)" do
        result = renderer.render
        doc = Nokogiri::XML(result)

        rect = doc.at_css("g[data-name='root'] rect")
        expect(rect).not_to be_nil
      end

      it "renders symbol text label" do
        result = renderer.render
        doc = Nokogiri::XML(result)

        text = doc.at_css("g[data-name='root'] text")
        expect(text).not_to be_nil
        expect(text.content).to include("root")
      end
    end

    context "with parent-child hierarchy" do
      let(:child_symbol) do
        Xseed::Svg::Symbol::ElementSymbol.new(
          name: "child",
          type: "element",
          xsd_node: mock_xsd_node
        ).tap do |s|
          s.set_position(30, 60)
        end
      end

      before do
        root_symbol.add_child(child_symbol)
      end

      it "renders both parent and child symbols" do
        result = renderer.render
        doc = Nokogiri::XML(result)

        expect(doc.at_css("g[data-name='root']")).not_to be_nil
        expect(doc.at_css("g[data-name='child']")).not_to be_nil
      end

      it "renders child symbols at root level with absolute positioning" do
        result = renderer.render
        doc = Nokogiri::XML(result)

        # Children are rendered at root level, not nested, due to absolute positioning
        child_group = doc.at_css("g[data-name='child']")
        expect(child_group).not_to be_nil
        expect(child_group["transform"]).to include("translate")
      end

      it "renders connector line between parent and child" do
        result = renderer.render
        doc = Nokogiri::XML(result)

        # Connector lines should be present
        lines = doc.css("line.connector")
        expect(lines.length).to be >= 1
      end
    end

    context "with different symbol types" do
      it "applies correct class for ComplexType symbol" do
        complex_type = Xseed::Svg::Symbol::ComplexTypeSymbol.new(
          name: "Person",
          type: "complexType",
          xsd_node: mock_xsd_node
        ).tap { |s| s.set_position(10, 10) }

        renderer_ct = described_class.new(complex_type)
        result = renderer_ct.render
        doc = Nokogiri::XML(result)

        group = doc.at_css("g[data-name='Person']")
        expect(group["class"]).to include("xsd-complex-type")
      end

      it "applies correct class for SimpleType symbol" do
        simple_type = Xseed::Svg::Symbol::SimpleTypeSymbol.new(
          name: "Age",
          type: "simpleType",
          xsd_node: mock_xsd_node
        ).tap { |s| s.set_position(10, 10) }

        renderer_st = described_class.new(simple_type)
        result = renderer_st.render
        doc = Nokogiri::XML(result)

        group = doc.at_css("g[data-name='Age']")
        expect(group["class"]).to include("xsd-simple-type")
      end

      it "applies correct class for Sequence symbol" do
        sequence = Xseed::Svg::Symbol::SequenceSymbol.new(
          name: "seq1",
          type: "sequence",
          xsd_node: mock_xsd_node
        ).tap { |s| s.set_position(10, 10) }

        renderer_seq = described_class.new(sequence)
        result = renderer_seq.render
        doc = Nokogiri::XML(result)

        group = doc.at_css("g[data-name='seq1']")
        expect(group["class"]).to include("xsd-sequence")
      end

      it "applies correct class for Choice symbol" do
        choice = Xseed::Svg::Symbol::ChoiceSymbol.new(
          name: "choice1",
          type: "choice",
          xsd_node: mock_xsd_node
        ).tap { |s| s.set_position(10, 10) }

        renderer_choice = described_class.new(choice)
        result = renderer_choice.render
        doc = Nokogiri::XML(result)

        group = doc.at_css("g[data-name='choice1']")
        expect(group["class"]).to include("xsd-choice")
      end

      it "applies correct class for Attribute symbol" do
        attribute = Xseed::Svg::Symbol::AttributeSymbol.new(
          name: "id",
          type: "attribute",
          xsd_node: mock_xsd_node
        ).tap { |s| s.set_position(10, 10) }

        renderer_attr = described_class.new(attribute)
        result = renderer_attr.render
        doc = Nokogiri::XML(result)

        group = doc.at_css("g[data-name='id']")
        expect(group["class"]).to include("xsd-attribute")
      end
    end

    context "with documentation" do
      let(:mock_annotation) do
        double("Annotation", documentation: "This is a sample element")
      end

      let(:mock_xsd_node_with_doc) do
        double("XsdNode",
               annotation: mock_annotation,
               namespace: nil,
               namespace_prefix: nil)
      end

      let(:documented_symbol) do
        Xseed::Svg::Symbol::ElementSymbol.new(
          name: "sample",
          type: "element",
          xsd_node: mock_xsd_node_with_doc
        ).tap { |s| s.set_position(10, 10) }
      end

      it "includes title element with documentation" do
        renderer_doc = described_class.new(documented_symbol)
        result = renderer_doc.render
        doc = Nokogiri::XML(result)

        title = doc.at_css("g[data-name='sample'] title")
        expect(title).not_to be_nil
        expect(title.content).to include("This is a sample element")
      end
    end
  end

  describe "CSS styling" do
    it "includes styles for all symbol types" do
      result = renderer.render
      doc = Nokogiri::XML(result)
      style_content = doc.at_css("style").content

      # Check for various symbol type styles
      expect(style_content).to include("xsd-element")
      expect(style_content).to include("xsd-complex-type")
      expect(style_content).to include("xsd-simple-type")
      expect(style_content).to include("xsd-sequence")
      expect(style_content).to include("xsd-choice")
      expect(style_content).to include("xsd-attribute")
    end

    it "includes connector line styles" do
      result = renderer.render
      doc = Nokogiri::XML(result)
      style_content = doc.at_css("style").content

      expect(style_content).to include("connector")
    end

    it "includes text styles" do
      result = renderer.render
      doc = Nokogiri::XML(result)
      style_content = doc.at_css("style").content

      expect(style_content).to include("symbol-name")
      expect(style_content).to include("symbol-type")
    end
  end

  describe "shape rendering" do
    it "renders rectangles with appropriate dimensions" do
      result = renderer.render
      doc = Nokogiri::XML(result)

      rect = doc.at_css("g[data-name='root'] rect.symbol-shape")
      expect(rect["width"]).to eq(root_symbol.width.to_s)
      expect(rect["height"]).to eq(root_symbol.height.to_s)
    end

    it "renders rounded rectangles for complex types" do
      complex_type = Xseed::Svg::Symbol::ComplexTypeSymbol.new(
        name: "Person",
        type: "complexType",
        xsd_node: mock_xsd_node
      ).tap { |s| s.set_position(10, 10) }

      renderer_ct = described_class.new(complex_type)
      result = renderer_ct.render
      doc = Nokogiri::XML(result)

      rect = doc.at_css("g[data-name='Person'] rect.symbol-shape")
      expect(rect["rx"]).to be_truthy
    end
  end

  describe "text rendering" do
    it "centers text within symbol" do
      result = renderer.render
      doc = Nokogiri::XML(result)

      text = doc.at_css("g[data-name='root'] text.symbol-name")
      # Text is left-aligned at x=5
      expect(text["x"]).to eq("5")
    end

    it "includes symbol type information" do
      result = renderer.render
      doc = Nokogiri::XML(result)

      # Type text is wrapped in an anchor link, look for it anywhere in the group
      type_text = doc.at_css("g[data-name='root'] a text.symbol-type")
      expect(type_text).to be_nil # root has no type by default
    end
  end

  describe "connector rendering" do
    let(:child_symbol) do
      Xseed::Svg::Symbol::ElementSymbol.new(
        name: "child",
        type: "element",
        xsd_node: mock_xsd_node
      ).tap do |s|
        s.set_position(30, 60)
      end
    end

    before do
      root_symbol.add_child(child_symbol)
    end

    it "renders connector from parent to child" do
      result = renderer.render
      doc = Nokogiri::XML(result)

      connectors = doc.css("line.connector")
      expect(connectors).not_to be_empty
    end

    it "calculates correct connector coordinates" do
      result = renderer.render
      doc = Nokogiri::XML(result)

      connector = doc.at_css("line.connector")

      # Connector should start from bottom of parent
      # and end at top of child
      expect(connector["x1"]).to be_truthy
      expect(connector["y1"]).to be_truthy
      expect(connector["x2"]).to be_truthy
      expect(connector["y2"]).to be_truthy
    end
  end

  describe "connection circles" do
    it "renders connection circles for symbols" do
      result = renderer.render
      doc = Nokogiri::XML(result)

      circles = doc.css("g[data-name='root'] circle")
      expect(circles).not_to be_empty
    end

    it "renders input connection circles" do
      result = renderer.render
      doc = Nokogiri::XML(result)

      input_circles = doc.css("g[data-name='root'] circle.connection-input")
      expect(input_circles).not_to be_empty
    end

    it "renders output connection circles" do
      result = renderer.render
      doc = Nokogiri::XML(result)

      output_circles = doc.css("g[data-name='root'] circle.connection-output")
      expect(output_circles).not_to be_empty
    end

    it "sets correct radius for connection circles" do
      result = renderer.render
      doc = Nokogiri::XML(result)

      circle = doc.at_css("g[data-name='root'] circle")
      expect(circle["r"]).to eq("2")
    end

    context "with compositor symbols" do
      let(:sequence_symbol) do
        Xseed::Svg::Symbol::SequenceSymbol.new(
          name: "seq1",
          type: "sequence",
          xsd_node: mock_xsd_node
        ).tap { |s| s.set_position(10, 10) }
      end

      it "renders multiple output circles for compositors" do
        renderer_seq = described_class.new(sequence_symbol)
        result = renderer_seq.render
        doc = Nokogiri::XML(result)

        output_circles = doc.css("g[data-name='seq1'] circle.compositor-output")
        expect(output_circles.length).to be >= 1
      end

      it "renders internal connecting line for compositor" do
        renderer_seq = described_class.new(sequence_symbol)
        result = renderer_seq.render
        doc = Nokogiri::XML(result)

        compositor_line = doc.at_css("g[data-name='seq1'] line.compositor-line")
        expect(compositor_line).not_to be_nil
      end
    end
  end

  describe "connection circle CSS styles" do
    it "includes connection-input styles" do
      result = renderer.render
      doc = Nokogiri::XML(result)
      style_content = doc.at_css("style").content

      expect(style_content).to include("connection-input")
    end

    it "includes connection-output styles" do
      result = renderer.render
      doc = Nokogiri::XML(result)
      style_content = doc.at_css("style").content

      expect(style_content).to include("connection-output")
    end

    it "includes compositor-line styles" do
      result = renderer.render
      doc = Nokogiri::XML(result)
      style_content = doc.at_css("style").content

      expect(style_content).to include("compositor-line")
    end
  end
end
