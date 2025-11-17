# frozen_string_literal: true

require "spec_helper"
require "xseed/svg/svg_generator"
require "nokogiri"
require "tmpdir"
require "fileutils"

RSpec.describe "SVG Generation Integration", type: :integration do
  let(:fixtures_dir) { File.join(__dir__, "../../fixtures") }
  let(:simple_xsd) { File.join(fixtures_dir, "simple/element_only.xsd") }
  let(:complex_xsd) { File.join(fixtures_dir, "simple/complex_type.xsd") }
  let(:output_dir) do
    File.join(Dir.tmpdir, "xseed_integration_#{Time.now.to_i}")
  end

  before do
    FileUtils.mkdir_p(output_dir)
  end

  after do
    FileUtils.rm_rf(output_dir)
  end

  describe "Complete workflow: XSD → Parser → Symbols → Layout → SVG" do
    it "generates valid SVG from simple XSD" do
      generator = Xseed::Svg::SvgGenerator.new(simple_xsd)
      svg_content = generator.generate

      # Verify SVG is valid XML
      doc = Nokogiri::XML(svg_content, &:strict)
      expect(doc.errors).to be_empty

      # Verify SVG structure
      expect(doc.root.name).to eq("svg")
      expect(doc.root.namespace.href).to eq("http://www.w3.org/2000/svg")
    end

    it "generates SVG with positioned symbols" do
      generator = Xseed::Svg::SvgGenerator.new(simple_xsd)
      svg_content = generator.generate
      doc = Nokogiri::XML(svg_content)

      # All symbols should have transform attributes
      symbols = doc.css("g.xsd-symbol")
      expect(symbols).not_to be_empty

      symbols.each do |symbol|
        expect(symbol["transform"]).to match(/translate\(\d+,\d+\)/)
      end
    end

    it "generates SVG with proper hierarchy connectors" do
      generator = Xseed::Svg::SvgGenerator.new(complex_xsd)
      svg_content = generator.generate
      doc = Nokogiri::XML(svg_content)

      symbols = doc.css("g.xsd-symbol")

      # If multiple symbols exist, connectors should be present
      if symbols.length > 1
        connectors = doc.css("line.connector")
        expect(connectors).not_to be_empty
      end
    end

    it "includes embedded CSS styles" do
      generator = Xseed::Svg::SvgGenerator.new(simple_xsd)
      svg_content = generator.generate
      doc = Nokogiri::XML(svg_content)

      style_element = doc.at_css("style")
      expect(style_element).not_to be_nil
      expect(style_element.content).to include("xsd-element")
      expect(style_element.content).to include(".connector")
    end

    it "renders symbol shapes with proper dimensions" do
      generator = Xseed::Svg::SvgGenerator.new(simple_xsd)
      svg_content = generator.generate
      doc = Nokogiri::XML(svg_content)

      rectangles = doc.css("rect")
      expect(rectangles).not_to be_empty

      rectangles.each do |rect|
        width = rect["width"].to_i
        height = rect["height"].to_i

        expect(width).to be > 0
        expect(height).to be > 0
      end
    end

    it "renders text labels for symbols" do
      generator = Xseed::Svg::SvgGenerator.new(simple_xsd)
      svg_content = generator.generate
      doc = Nokogiri::XML(svg_content)

      text_elements = doc.css("text")
      expect(text_elements).not_to be_empty

      # At least one text element should have content
      has_content = text_elements.any? { |t| !t.content.strip.empty? }
      expect(has_content).to be(true)
    end

    it "calculates appropriate viewport size" do
      generator = Xseed::Svg::SvgGenerator.new(simple_xsd)
      svg_content = generator.generate
      doc = Nokogiri::XML(svg_content)

      width = doc.root["width"].to_i
      height = doc.root["height"].to_i

      # Viewport should be reasonable
      expect(width).to be_between(100, 5000)
      expect(height).to be_between(100, 5000)
    end
  end

  describe "File generation" do
    let(:output_file) { File.join(output_dir, "diagram.svg") }

    it "writes SVG to specified file" do
      generator = Xseed::Svg::SvgGenerator.new(simple_xsd)
      generator.generate_file(output_file)

      expect(File.exist?(output_file)).to be(true)
    end

    it "generates valid SVG file" do
      generator = Xseed::Svg::SvgGenerator.new(simple_xsd)
      generator.generate_file(output_file)

      content = File.read(output_file)
      doc = Nokogiri::XML(content, &:strict)

      expect(doc.errors).to be_empty
      expect(doc.root.name).to eq("svg")
    end

    it "creates nested directories if needed" do
      nested_file = File.join(output_dir, "subdir1/subdir2/diagram.svg")

      generator = Xseed::Svg::SvgGenerator.new(simple_xsd)
      generator.generate_file(nested_file)

      expect(File.exist?(nested_file)).to be(true)
    end
  end

  describe "Symbol hierarchy preservation" do
    it "maintains parent-child relationships" do
      generator = Xseed::Svg::SvgGenerator.new(complex_xsd)
      svg_content = generator.generate
      doc = Nokogiri::XML(svg_content)

      # Get all symbols
      symbols = doc.css("g.xsd-symbol")

      if symbols.length > 1
        # Extract positions
        positions = symbols.filter_map do |sym|
          if sym["transform"] =~ /translate\((\d+(?:\.\d+)?),(\d+(?:\.\d+)?)\)/
            { x: Regexp.last_match(1).to_f, y: Regexp.last_match(2).to_f,
              id: sym["id"] }
          end
        end

        # Verify vertical spacing exists (children below parents)
        y_positions = positions.map { |p| p[:y] }.sort
        expect(y_positions.uniq.length).to be > 1 if positions.length > 1
      end
    end

    it "renders connectors from parents to children" do
      generator = Xseed::Svg::SvgGenerator.new(complex_xsd)
      svg_content = generator.generate
      doc = Nokogiri::XML(svg_content)

      connectors = doc.css("line.connector")

      connectors.each do |connector|
        # Connectors should have valid coordinates
        expect(connector["x1"]).to be_truthy
        expect(connector["y1"]).to be_truthy
        expect(connector["x2"]).to be_truthy
        expect(connector["y2"]).to be_truthy

        # Coordinates should be numeric
        expect(connector["x1"].to_f).to be >= 0
        expect(connector["y1"].to_f).to be >= 0
        expect(connector["x2"].to_f).to be >= 0
        expect(connector["y2"].to_f).to be >= 0
      end
    end
  end

  describe "Symbol type differentiation" do
    it "applies different CSS classes to different symbol types" do
      generator = Xseed::Svg::SvgGenerator.new(complex_xsd)
      svg_content = generator.generate
      doc = Nokogiri::XML(svg_content)

      symbols = doc.css("g.xsd-symbol")
      css_classes = symbols.map { |s| s["class"] }.uniq

      # Should have at least the base xsd-symbol class
      expect(css_classes).not_to be_empty
      expect(css_classes.any? { |c| c.include?("xsd-") }).to be(true)
    end

    it "uses appropriate colors for different types" do
      generator = Xseed::Svg::SvgGenerator.new(complex_xsd)
      svg_content = generator.generate

      # CSS should define colors for different types
      expect(svg_content).to include("xsd-element")
      expect(svg_content).to include("fill:")
    end
  end

  describe "Performance" do
    it "generates SVG in reasonable time for simple schemas" do
      generator = Xseed::Svg::SvgGenerator.new(simple_xsd)

      start_time = Time.now
      generator.generate
      end_time = Time.now

      execution_time = end_time - start_time
      expect(execution_time).to be < 1.0
    end

    it "generates SVG in reasonable time for complex schemas" do
      generator = Xseed::Svg::SvgGenerator.new(complex_xsd)

      start_time = Time.now
      generator.generate
      end_time = Time.now

      execution_time = end_time - start_time
      expect(execution_time).to be < 2.0
    end
  end

  describe "Edge cases" do
    it "handles XSD with no elements gracefully" do
      empty_xsd = File.join(output_dir, "empty.xsd")
      File.write(empty_xsd, <<~XSD)
        <?xml version="1.0"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
        </xs:schema>
      XSD

      generator = Xseed::Svg::SvgGenerator.new(empty_xsd)
      svg_content = generator.generate

      doc = Nokogiri::XML(svg_content)
      expect(doc.root.name).to eq("svg")

      # Should still have at least a placeholder or root symbol
      symbols = doc.css("g.xsd-symbol")
      expect(symbols.length).to be >= 1
    end

    it "handles XSD with single element" do
      single_xsd = File.join(output_dir, "single.xsd")
      File.write(single_xsd, <<~XSD)
        <?xml version="1.0"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
          <xs:element name="root" type="xs:string"/>
        </xs:schema>
      XSD

      generator = Xseed::Svg::SvgGenerator.new(single_xsd)
      svg_content = generator.generate

      doc = Nokogiri::XML(svg_content)
      symbols = doc.css("g.xsd-symbol")
      expect(symbols.length).to be >= 1
    end
  end

  describe "Output validation" do
    it "generates well-formed XML" do
      generator = Xseed::Svg::SvgGenerator.new(simple_xsd)
      svg_content = generator.generate

      # Should be parseable without errors
      expect do
        Nokogiri::XML(svg_content, &:strict)
      end.not_to raise_error
    end

    it "includes required SVG elements" do
      generator = Xseed::Svg::SvgGenerator.new(simple_xsd)
      svg_content = generator.generate
      doc = Nokogiri::XML(svg_content)

      # Must have root SVG element
      expect(doc.root.name).to eq("svg")

      # Should have style element
      expect(doc.at_css("style")).not_to be_nil

      # Should have defs element
      expect(doc.at_css("defs")).not_to be_nil
    end

    it "includes proper namespaces" do
      generator = Xseed::Svg::SvgGenerator.new(simple_xsd)
      svg_content = generator.generate
      doc = Nokogiri::XML(svg_content)

      expect(doc.root.namespace.href).to eq("http://www.w3.org/2000/svg")
    end
  end
end
