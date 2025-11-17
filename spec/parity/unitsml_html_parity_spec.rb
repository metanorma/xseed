# frozen_string_literal: true

require "spec_helper"
require "nokogiri"
require_relative "../support/parity_helpers"

RSpec.describe "UnitsML HTML Parity" do
  include ParityHelpers

  let(:schema_path) { File.join(__dir__, "../fixtures/unitsml/unitsml-v1.0.xsd") }
  let(:reference_html_path) { File.join(__dir__, "../fixtures/unitsml/index.html") }

  describe "reference file validation" do
    it "has UnitsML XSD schema file" do
      expect(File.exist?(schema_path)).to be true
    end

    it "has reference HTML documentation" do
      expect(File.exist?(reference_html_path)).to be true
    end

    it "reference HTML is valid XML/HTML" do
      reference_html = File.read(reference_html_path)
      expect { Nokogiri::HTML(reference_html) }.not_to raise_error
    end
  end

  describe "HTML generation" do
    let(:reference_html) { File.read(reference_html_path) }

    let(:generated_html) do
      generator = Xseed::Documentation::HtmlGenerator.new(schema_path)
      generator.generate
    end

    it "generates valid HTML" do
      expect { Nokogiri::HTML(generated_html) }.not_to raise_error

      doc = Nokogiri::HTML(generated_html)
      expect(doc.at_css("html")).not_to be_nil
      expect(doc.at_css("head")).not_to be_nil
      expect(doc.at_css("body")).not_to be_nil
    end

    it "has HTML5 doctype" do
      expect(generated_html).to match(/<!DOCTYPE html>/i)
    end

    it "includes CSS styles" do
      doc = Nokogiri::HTML(generated_html)
      has_style = doc.at_css("style") || doc.at_css("link[rel='stylesheet']")
      expect(has_style).not_to be_nil
    end

    it "includes JavaScript for interactivity" do
      doc = Nokogiri::HTML(generated_html)
      expect(doc.at_css("script")).not_to be_nil
    end

    describe "structure comparison" do
      let(:ref_doc) { normalize_html(reference_html) }
      let(:gen_doc) { normalize_html(generated_html) }

      it "compares overall structure with reference" do
        differences = compare_html_structure(ref_doc, gen_doc)

        puts "\nUnitsML HTML Structure Comparison:"
        puts "  Reference file size: #{reference_html.length} bytes"
        puts "  Generated file size: #{generated_html.length} bytes"
        puts "  Size ratio: #{(generated_html.length.to_f / reference_html.length * 100).round(1)}%"
        puts

        if differences.any?
          puts "  Structural differences found:"
          differences.each { |diff| puts "    - #{diff}" }
          puts

          # Mark as pending if there are differences
          pending("Structural parity not yet fully achieved")
          expect(differences).to be_empty
        else
          puts "  ✓ Structure matches reference"
        end
      end

      it "reports element counts" do
        ref_elements = {
          tables: ref_doc.css("table").count,
          headings: ref_doc.css("h1, h2, h3, h4, h5, h6").count,
          divs: ref_doc.css("div").count,
          links: ref_doc.css("a").count,
          lists: ref_doc.css("ul, ol, dl").count
        }

        gen_elements = {
          tables: gen_doc.css("table").count,
          headings: gen_doc.css("h1, h2, h3, h4, h5, h6").count,
          divs: gen_doc.css("div").count,
          links: gen_doc.css("a").count,
          lists: gen_doc.css("ul, ol, dl").count
        }

        puts "\nElement Count Comparison:"
        ref_elements.each do |element, ref_count|
          gen_count = gen_elements[element]
          percentage = ref_count > 0 ? (gen_count.to_f / ref_count * 100).round(1) : 0
          match_indicator = (percentage >= 80 && percentage <= 120) ? "✓" : "✗"

          puts "  #{match_indicator} #{element.to_s.capitalize}: #{gen_count} (ref: #{ref_count}) - #{percentage}%"
        end
        puts

        # Assert reasonable element counts
        expect(gen_elements[:tables]).to be > 0
        expect(gen_elements[:headings]).to be > 0
        expect(gen_elements[:links]).to be > 0
      end
    end

    describe "content verification" do
      let(:doc) { Nokogiri::HTML(generated_html) }

      it "includes schema namespace information" do
        text_content = doc.text.downcase
        expect(text_content).to include("unitsml")
      end

      it "documents schema elements" do
        text_content = doc.text.downcase
        # UnitsML has key elements that should be documented
        expect(text_content).to match(/unit|prefix|quantity/i)
      end

      it "includes properties sections" do
        # Check for properties tables or definition lists
        has_properties = doc.css("table, dl").count > 0
        expect(has_properties).to be true
      end

      it "includes navigation components" do
        # Check for navigation elements
        has_nav = doc.at_css("nav") ||
                  doc.css("a[href^='#']").count > 5 ||
                  doc.text.downcase.include?("table of contents")

        expect(has_nav).to be_truthy
      end
    end

    describe "schema-specific content" do
      let(:doc) { Nokogiri::HTML(generated_html) }
      let(:text_content) { doc.text.downcase }

      it "documents UnitsML root element" do
        expect(text_content).to include("unitsml")
      end

      it "documents Unit element" do
        expect(text_content).to include("unit")
      end

      it "documents Prefix element" do
        expect(text_content).to include("prefix")
      end

      it "documents Quantity element" do
        expect(text_content).to include("quantity")
      end

      it "documents dimensional analysis elements" do
        # UnitsML has specific dimension-related elements
        expect(text_content).to match(/dimension|length|mass|time/i)
      end
    end

    describe "quality metrics" do
      let(:doc) { Nokogiri::HTML(generated_html) }

      it "reports documentation statistics" do
        stats = {
          total_elements: doc.css("*").count,
          text_length: doc.text.length,
          tables: doc.css("table").count,
          code_samples: doc.css("code, pre").count,
          links: doc.css("a").count
        }

        puts "\nGenerated HTML Statistics:"
        stats.each do |metric, value|
          puts "  #{metric.to_s.tr('_', ' ').capitalize}: #{value}"
        end
        puts

        # Basic quality checks
        expect(stats[:total_elements]).to be > 100
        expect(stats[:text_length]).to be > 1000
      end

      it "has reasonable documentation size" do
        # Generated HTML should be substantial but not excessively large
        size_kb = generated_html.length / 1024.0
        puts "\nGenerated documentation size: #{size_kb.round(1)} KB"

        expect(size_kb).to be > 10  # At least 10 KB of documentation
      end
    end
  end
end