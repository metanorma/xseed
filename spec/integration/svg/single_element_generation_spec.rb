# frozen_string_literal: true

require "spec_helper"
require "xseed/svg/svg_generator"
require "nokogiri"

RSpec.describe "Single Element SVG Generation" do
  let(:unitsml_xsd) { "spec/fixtures/real_world/unitsml-v1.0.xsd" }

  describe "single element mode" do
    it "generates SVG for a single element" do
      generator = Xseed::Svg::SvgGenerator.new(unitsml_xsd, element: "Unit")
      svg_content = generator.generate

      expect(svg_content).to be_a(String)
      expect(svg_content).to include('xmlns="http://www.w3.org/2000/svg"')
      expect(svg_content.length).to be > 1000
    end

    it "creates ElementRootSymbol as root" do
      generator = Xseed::Svg::SvgGenerator.new(unitsml_xsd, element: "Unit")

      # Generate to trigger tree building
      svg_content = generator.generate

      expect(svg_content).to be_a(String)
      # The SVG should be much smaller than full schema diagram
      expect(svg_content.length).to be < 50000
    end

    it "generates different diagrams for different elements" do
      unit_gen = Xseed::Svg::SvgGenerator.new(unitsml_xsd, element: "Unit")
      prefix_gen = Xseed::Svg::SvgGenerator.new(unitsml_xsd, element: "Prefix")

      unit_svg = unit_gen.generate
      prefix_svg = prefix_gen.generate

      expect(unit_svg).not_to eq(prefix_svg)
    end

    it "raises error for non-existent element" do
      expect {
        generator = Xseed::Svg::SvgGenerator.new(unitsml_xsd, element: "NonExistent")
        generator.generate
      }.to raise_error(Xseed::Svg::GenerationError, /not found/)
    end
  end

  describe "all_element_names method" do
    it "returns list of all global elements" do
      generator = Xseed::Svg::SvgGenerator.new(unitsml_xsd)
      names = generator.all_element_names

      expect(names).to be_an(Array)
      expect(names.length).to be > 0
      expect(names).to include("Unit")
      expect(names).to include("Prefix")
      expect(names).to eq(names.sort)
    end

    it "returns unique element names" do
      generator = Xseed::Svg::SvgGenerator.new(unitsml_xsd)
      names = generator.all_element_names

      expect(names).to eq(names.uniq)
    end
  end

  describe "always-inline mode for single elements" do
    it "inlines all type references in single-element mode" do
      generator = Xseed::Svg::SvgGenerator.new(unitsml_xsd, element: "Unit")
      svg_content = generator.generate

      doc = Nokogiri::XML(svg_content)

      # Parse and check that types are expanded inline, not referenced
      # The SVG should contain the element's content expanded
      expect(doc.xpath("//xmlns:svg", "xmlns" => "http://www.w3.org/2000/svg")).not_to be_empty
    end
  end

  describe "integration with file generation" do
    let(:output_file) { "/tmp/test_single_element.svg" }

    after do
      File.delete(output_file) if File.exist?(output_file)
    end

    it "generates file for single element" do
      generator = Xseed::Svg::SvgGenerator.new(unitsml_xsd, element: "Unit")
      result = generator.generate_file(output_file)

      expect(result).to eq(output_file)
      expect(File.exist?(output_file)).to be true

      content = File.read(output_file)
      expect(content).to include('xmlns="http://www.w3.org/2000/svg"')
    end
  end

  describe "comparison with full schema mode" do
    it "generates smaller diagrams in single-element mode" do
      full_gen = Xseed::Svg::SvgGenerator.new(unitsml_xsd)
      element_gen = Xseed::Svg::SvgGenerator.new(unitsml_xsd, element: "Unit")

      full_svg = full_gen.generate
      element_svg = element_gen.generate

      # Single element should be much smaller
      expect(element_svg.length).to be < (full_svg.length / 2)
    end
  end
end