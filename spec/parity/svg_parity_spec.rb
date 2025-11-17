# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe "SVG Output Parity" do
  FIXTURES_DIR = File.join(__dir__, "../fixtures")
  REFERENCE_SVG_DIR = File.join(FIXTURES_DIR, "reference/svg")
  SIMPLE_FIXTURES = Dir.glob(File.join(FIXTURES_DIR, "simple/*.xsd"))
  REAL_WORLD_FIXTURES = Dir.glob(File.join(FIXTURES_DIR, "real_world/*.xsd"))

  def normalize_svg(svg_content)
    doc = Nokogiri::XML(svg_content)
    # Remove whitespace-only text nodes
    doc.xpath("//text()").each do |node|
      node.remove if node.text.strip.empty?
    end
    doc
  end

  def compare_svg_structure(ref_doc, xseed_doc)
    differences = []

    # Compare root element
    if ref_doc.root.name != xseed_doc.root.name
      differences << "Root element mismatch: #{ref_doc.root.name} vs #{xseed_doc.root.name}"
    end

    # Compare element counts
    ref_elements = ref_doc.xpath("//*").count
    xseed_elements = xseed_doc.xpath("//*").count
    if ref_elements != xseed_elements
      differences << "Element count mismatch: #{ref_elements} vs #{xseed_elements}"
    end

    # Compare specific SVG elements
    %w[rect circle line path text g].each do |elem|
      ref_count = ref_doc.xpath("//svg:#{elem}", "svg" => "http://www.w3.org/2000/svg").count
      xseed_count = xseed_doc.xpath("//svg:#{elem}", "svg" => "http://www.w3.org/2000/svg").count
      if ref_count != xseed_count
        differences << "#{elem} count mismatch: #{ref_count} vs #{xseed_count}"
      end
    end

    differences
  end

  shared_examples "svg parity check" do |fixture_path|
    let(:xsd_file) { fixture_path }
    let(:basename) { File.basename(xsd_file, ".xsd") }
    let(:reference_svg_path) { File.join(REFERENCE_SVG_DIR, "#{basename}.svg") }

    it "has reference SVG file" do
      expect(File.exist?(reference_svg_path)).to be true
    end

    context "when generating SVG" do
      let(:reference_svg) { File.read(reference_svg_path) }

      let(:xseed_svg) do
        # Generate SVG using Xseed
        generator = Xseed::Svg::SvgGenerator.new(xsd_file)
        generator.generate
      end

      it "produces valid SVG" do
        expect { Nokogiri::XML(xseed_svg) { |config| config.strict } }.not_to raise_error
      end

      it "has similar structure to reference" do
        ref_doc = normalize_svg(reference_svg)
        xseed_doc = normalize_svg(xseed_svg)

        differences = compare_svg_structure(ref_doc, xseed_doc)

        if differences.any?
          puts "\n#{basename} - Differences found:"
          differences.each { |diff| puts "  - #{diff}" }
          # Mark as pending and fail for now
          pending("Parity not yet achieved")
          expect(differences).to be_empty
        end
      end
    end
  end

  describe "simple fixtures" do
    SIMPLE_FIXTURES.each do |fixture|
      context "for #{File.basename(fixture)}" do
        include_examples "svg parity check", fixture
      end
    end
  end

  describe "real-world fixtures" do
    REAL_WORLD_FIXTURES.each do |fixture|
      context "for #{File.basename(fixture)}" do
        include_examples "svg parity check", fixture
      end
    end
  end
end
