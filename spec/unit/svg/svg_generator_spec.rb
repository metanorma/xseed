# frozen_string_literal: true

require "spec_helper"
require "xseed/svg/svg_generator"
require "xseed/parser/xsd_parser"
require "nokogiri"
require "tmpdir"
require "fileutils"

RSpec.describe Xseed::Svg::SvgGenerator do
  let(:simple_xsd_path) do
    File.join(__dir__, "../../fixtures/simple/element_only.xsd")
  end
  let(:complex_xsd_path) do
    File.join(__dir__, "../../fixtures/simple/complex_type.xsd")
  end
  let(:generator) { described_class.new(simple_xsd_path) }

  describe "#initialize" do
    it "initializes with XSD file path" do
      expect(generator.instance_variable_get(:@xsd_file_path)).to eq(simple_xsd_path)
    end

    it "raises error if file does not exist" do
      expect do
        described_class.new("/nonexistent/file.xsd")
      end.to raise_error(/File not found|does not exist/i)
    end

    it "raises error if file is not XSD" do
      non_xsd_file = File.join(__dir__, "../../spec_helper.rb")
      expect do
        described_class.new(non_xsd_file)
      end.to raise_error(/must be an XSD file|Invalid XSD file/i)
    end
  end

  describe "#generate" do
    it "returns a string" do
      result = generator.generate
      expect(result).to be_a(String)
    end

    it "generates valid XML" do
      result = generator.generate
      expect do
        Nokogiri::XML(result, &:strict)
      end.not_to raise_error
    end

    it "generates SVG with correct namespace" do
      result = generator.generate
      doc = Nokogiri::XML(result)
      expect(doc.root.name).to eq("svg")
      expect(doc.root.namespace.href).to eq("http://www.w3.org/2000/svg")
    end

    it "includes viewport dimensions" do
      result = generator.generate
      doc = Nokogiri::XML(result)

      expect(doc.root["width"]).to be_truthy
      expect(doc.root["height"]).to be_truthy
      expect(doc.root["width"].to_i).to be > 0
      expect(doc.root["height"].to_i).to be > 0
    end

    it "includes CSS styles" do
      result = generator.generate
      doc = Nokogiri::XML(result)
      style_element = doc.at_css("style")

      expect(style_element).not_to be_nil
      expect(style_element.content).not_to be_empty
    end

    it "renders at least one symbol" do
      result = generator.generate
      doc = Nokogiri::XML(result)

      # Should have at least one g element representing a symbol
      symbols = doc.css("g.xsd-symbol")
      expect(symbols.length).to be >= 1
    end

    context "with simple element XSD" do
      it "generates diagram for simple elements" do
        result = generator.generate
        doc = Nokogiri::XML(result)

        # Should contain element symbols
        expect(doc.css("g.xsd-element")).not_to be_empty
      end
    end

    context "with complex type XSD" do
      let(:generator) { described_class.new(complex_xsd_path) }

      it "generates diagram for complex types" do
        result = generator.generate
        doc = Nokogiri::XML(result)

        # Should contain both element and type symbols
        expect(doc.css("g.xsd-symbol").length).to be >= 1
      end

      it "includes connector lines for hierarchies" do
        result = generator.generate
        doc = Nokogiri::XML(result)

        # If there are hierarchies, should have connectors
        if doc.css("g.xsd-symbol").length > 1
          expect(doc.css("line.connector")).not_to be_empty
        end
      end
    end
  end

  describe "#generate_file" do
    let(:output_path) do
      File.join(Dir.tmpdir, "test_output_#{Time.now.to_i}.svg")
    end

    after do
      FileUtils.rm_f(output_path)
    end

    it "writes SVG to file" do
      generator.generate_file(output_path)
      expect(File.exist?(output_path)).to be(true)
    end

    it "writes valid SVG content to file" do
      generator.generate_file(output_path)
      content = File.read(output_path)

      doc = Nokogiri::XML(content)
      expect(doc.root.name).to eq("svg")
    end

    it "creates directory if it does not exist" do
      nested_path = File.join(Dir.tmpdir, "test_nested_#{Time.now.to_i}",
                              "output.svg")

      generator.generate_file(nested_path)
      expect(File.exist?(nested_path)).to be(true)

      # Cleanup
      FileUtils.rm_rf(File.dirname(nested_path))
    end

    it "overwrites existing file" do
      # Write initial content
      File.write(output_path, "initial content")

      # Generate SVG
      generator.generate_file(output_path)

      # Content should be overwritten with valid SVG
      content = File.read(output_path)
      expect(content).not_to eq("initial content")
      expect(content).to include("<svg")
    end
  end

  describe "integration with parser" do
    it "uses XsdParser to parse XSD file" do
      expect(Xseed::Parser::XsdParser).to receive(:new).with(simple_xsd_path).and_call_original
      generator.generate
    end

    it "builds symbol tree from parser" do
      result = generator.generate
      doc = Nokogiri::XML(result)

      # Should have created symbols from parsed XSD
      expect(doc.css("g.xsd-symbol")).not_to be_empty
    end
  end

  describe "integration with layout engine" do
    it "positions symbols without overlaps" do
      result = generator.generate
      doc = Nokogiri::XML(result)

      symbols = doc.css("g.xsd-symbol")

      # Extract positions from transforms
      positions = symbols.filter_map do |sym|
        if sym["transform"] =~ /translate\((\d+(?:\.\d+)?),(\d+(?:\.\d+)?)\)/
          { x: Regexp.last_match(1).to_f, y: Regexp.last_match(2).to_f,
            element: sym }
        end
      end

      # Check no two symbols have exact same position
      expect(positions.uniq do |p|
        [p[:x], p[:y]]
      end.length).to eq(positions.length)
    end

    it "calculates appropriate viewport for content" do
      result = generator.generate
      doc = Nokogiri::XML(result)

      viewport_width = doc.root["width"].to_i
      viewport_height = doc.root["height"].to_i

      # Viewport should be reasonable size
      expect(viewport_width).to be > 100
      expect(viewport_height).to be > 100
      expect(viewport_width).to be < 5000
      expect(viewport_height).to be < 5000
    end
  end

  describe "integration with renderer" do
    it "renders symbols with shapes" do
      result = generator.generate
      doc = Nokogiri::XML(result)

      # Should have rectangles for symbols
      expect(doc.css("rect")).not_to be_empty
    end

    it "renders text labels for symbols" do
      result = generator.generate
      doc = Nokogiri::XML(result)

      # Should have text elements
      text_elements = doc.css("text")
      expect(text_elements).not_to be_empty

      # Text should not be empty
      expect(text_elements.any? { |t| !t.content.strip.empty? }).to be(true)
    end

    it "applies CSS classes to symbols" do
      result = generator.generate
      doc = Nokogiri::XML(result)

      symbols = doc.css("g.xsd-symbol")
      expect(symbols).not_to be_empty

      # Each symbol should have a specific type class
      symbols.each do |sym|
        expect(sym["class"]).to match(/xsd-(element|complex-type|simple-type|sequence|choice|attribute)/)
      end
    end
  end

  describe "performance" do
    context "with real-world XSD file" do
      let(:unitsml_path) do
        File.join(__dir__, "../../fixtures/real_world/unitsml-v1.0.xsd")
      end

      it "generates SVG in reasonable time" do
        skip "unitsml-v1.0.xsd not found" unless File.exist?(unitsml_path)

        generator = described_class.new(unitsml_path)

        start_time = Time.now
        result = generator.generate
        end_time = Time.now

        execution_time = end_time - start_time

        # Should complete in less than 3 seconds
        expect(execution_time).to be < 3.0

        # Should produce valid output
        expect(result).to include("<svg")
      end
    end
  end

  describe "error handling" do
    it "handles invalid XSD gracefully" do
      invalid_xsd = File.join(Dir.tmpdir, "invalid_#{Time.now.to_i}.xsd")
      File.write(invalid_xsd, "<invalid>not valid XSD</invalid>")

      # Should raise error during initialization when validating file
      expect do
        described_class.new(invalid_xsd)
      end.to raise_error(ArgumentError, /Invalid XSD file/)

      File.delete(invalid_xsd)
    end

    it "handles empty XSD file" do
      empty_xsd = File.join(Dir.tmpdir, "empty_#{Time.now.to_i}.xsd")
      File.write(empty_xsd, '<?xml version="1.0"?><xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"></xs:schema>')

      generator = described_class.new(empty_xsd)
      result = generator.generate

      # Should generate valid but minimal SVG
      doc = Nokogiri::XML(result)
      expect(doc.root.name).to eq("svg")

      File.delete(empty_xsd)
    end
  end

  describe "output quality" do
    it "generates well-formed SVG" do
      result = generator.generate

      # Check for key SVG elements
      expect(result).to include("<svg")
      expect(result).to include("</svg>")
      expect(result).to include("xmlns=\"http://www.w3.org/2000/svg\"")
    end

    it "includes all necessary SVG components" do
      result = generator.generate
      doc = Nokogiri::XML(result)

      # Should have style element
      expect(doc.at_css("style")).not_to be_nil

      # Should have defs element
      expect(doc.at_css("defs")).not_to be_nil

      # Should have at least one symbol group
      expect(doc.css("g.xsd-symbol")).not_to be_empty
    end
  end
end
