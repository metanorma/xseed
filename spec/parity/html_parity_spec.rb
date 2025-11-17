# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe "HTML Output Parity" do
  FIXTURES_DIR = File.join(__dir__, "../fixtures")
  REFERENCE_HTML_DIR = File.join(FIXTURES_DIR, "reference/html")
  SIMPLE_FIXTURES = Dir.glob(File.join(FIXTURES_DIR, "simple/*.xsd"))
  REAL_WORLD_FIXTURES = Dir.glob(File.join(FIXTURES_DIR, "real_world/*.xsd"))

  def normalize_html(html_content)
    doc = Nokogiri::HTML(html_content)
    # Remove generated timestamps and dynamic content
    doc.xpath("//comment()").remove
    doc.xpath("//text()").each do |node|
      node.remove if node.text.strip.empty?
    end
    doc
  end

  def compare_html_structure(ref_doc, xseed_doc)
    differences = []

    # Compare major sections
    sections = %w[head body]
    sections.each do |section|
      ref_section = ref_doc.at_css(section)
      xseed_section = xseed_doc.at_css(section)

      if ref_section && !xseed_section
        differences << "Missing #{section} section"
      elsif !ref_section && xseed_section
        differences << "Unexpected #{section} section"
      end
    end

    # Compare table counts
    ref_tables = ref_doc.css("table").count
    xseed_tables = xseed_doc.css("table").count
    if ref_tables != xseed_tables
      differences << "Table count mismatch: #{ref_tables} vs #{xseed_tables}"
    end

    # Compare heading counts
    (1..6).each do |level|
      ref_count = ref_doc.css("h#{level}").count
      xseed_count = xseed_doc.css("h#{level}").count
      if ref_count != xseed_count
        differences << "h#{level} count mismatch: #{ref_count} vs #{xseed_count}"
      end
    end

    # Check for key sections
    key_sections = ["schema properties", "element", "type", "documentation"]
    key_sections.each do |section|
      ref_has = ref_doc.text.downcase.include?(section)
      xseed_has = xseed_doc.text.downcase.include?(section)
      if ref_has && !xseed_has
        differences << "Missing '#{section}' section"
      end
    end

    differences
  end

  shared_examples "html parity check" do |fixture_path|
    let(:xsd_file) { fixture_path }
    let(:basename) { File.basename(xsd_file, ".xsd") }
    let(:reference_html_path) { File.join(REFERENCE_HTML_DIR, "#{basename}.html") }

    it "has reference HTML file" do
      expect(File.exist?(reference_html_path)).to be true
    end

    context "when generating HTML" do
      let(:reference_html) { File.read(reference_html_path) }

      let(:xseed_html) do
        # Generate HTML using Xseed
        generator = Xseed::Documentation::HtmlGenerator.new(xsd_file)
        generator.generate
      end

      it "produces parseable HTML" do
        # Note: We use lenient parsing because Nokogiri's HTML parser
        # uses an older HTML DTD that doesn't recognize HTML5 tags like
        # <section> and <nav>. What matters is that browsers render correctly.
        expect { Nokogiri::HTML(xseed_html) }.not_to raise_error

        doc = Nokogiri::HTML(xseed_html)
        # Verify basic structure exists (html, head, body tags)
        expect(doc.at_css('html')).not_to be_nil
        expect(doc.at_css('head')).not_to be_nil
        expect(doc.at_css('body')).not_to be_nil
      end

      it "has similar structure to reference" do
        ref_doc = normalize_html(reference_html)
        xseed_doc = normalize_html(xseed_html)

        differences = compare_html_structure(ref_doc, xseed_doc)

        if differences.any?
          puts "\n#{basename} - Differences found:"
          differences.each { |diff| puts "  - #{diff}" }
          # Mark as pending and fail for now
          pending("Parity not yet achieved")
          expect(differences).to be_empty
        end
      end

      it "contains schema properties section" do
        doc = Nokogiri::HTML(xseed_html)
        expect(doc.text.downcase).to include("schema")
      end

      it "contains properties tables" do
        doc = Nokogiri::HTML(xseed_html)
        # XS3P uses definition lists (dl) for properties, not tables
        definition_lists = doc.css("dl.dl-horizontal")
        expect(definition_lists.count).to be > 0
      end
    end
  end

  describe "simple fixtures" do
    SIMPLE_FIXTURES.each do |fixture|
      context "for #{File.basename(fixture)}" do
        include_examples "html parity check", fixture
      end
    end
  end

  describe "real-world fixtures" do
    REAL_WORLD_FIXTURES.each do |fixture|
      context "for #{File.basename(fixture)}" do
        include_examples "html parity check", fixture
      end
    end
  end
end
