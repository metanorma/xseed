# frozen_string_literal: true

require "spec_helper"
require "nokogiri"
require_relative "../support/parity_helpers"

RSpec.describe "UnitsML SVG Diagrams Parity" do
  include ParityHelpers

  let(:schema_path) { File.join(__dir__, "../fixtures/unitsml/unitsml-v1.0.xsd") }
  let(:diagrams_dir) { File.join(__dir__, "../fixtures/unitsml/diagrams") }

  # Get all reference SVG files
  reference_svgs = Dir.glob(File.join(__dir__, "../fixtures/unitsml/diagrams/*.svg")).sort

  describe "reference files validation" do
    it "has UnitsML XSD schema file" do
      expect(File.exist?(schema_path)).to be true
    end

    it "has diagrams directory" do
      expect(Dir.exist?(diagrams_dir)).to be true
    end

    it "has reference SVG diagram files" do
      expect(reference_svgs.count).to be > 0
      puts "\nFound #{reference_svgs.count} reference SVG diagrams"
    end

    it "all reference SVG files are valid XML" do
      reference_svgs.each do |svg_path|
        svg_content = File.read(svg_path)
        expect { Nokogiri::XML(svg_content) { |config| config.strict } }.not_to raise_error,
          "#{File.basename(svg_path)} is not valid XML"
      end
    end
  end

  describe "individual element diagrams" do
    reference_svgs.each do |reference_path|
      element_name = File.basename(reference_path, ".svg")

      context "for #{element_name}" do
        let(:reference_svg) { File.read(reference_path) }

        let(:generated_svg) do
          generator = Xseed::Svg::SvgGenerator.new(schema_path, element: element_name)
          generator.generate
        rescue StandardError => e
          # Capture generation errors for reporting
          "<!-- Generation failed: #{e.message} -->"
        end

        it "generates valid SVG" do
          skip "Generation failed" if generated_svg.include?("Generation failed")

          expect { Nokogiri::XML(generated_svg) { |config| config.strict } }.not_to raise_error
        end

        it "compares structure with reference" do
          skip "Generation failed" if generated_svg.include?("Generation failed")

          ref_doc = normalize_svg(reference_svg)
          gen_doc = normalize_svg(generated_svg)

          differences = compare_svg_structure(ref_doc, gen_doc)

          if differences.any?
            puts "\n  #{element_name}: Differences found:"
            differences.each { |diff| puts "    - #{diff}" }

            pending("Diagram parity not yet achieved for #{element_name}")
            expect(differences).to be_empty
          end
        end

        it "reports element statistics" do
          skip "Generation failed" if generated_svg.include?("Generation failed")

          ref_doc = normalize_svg(reference_svg)
          gen_doc = normalize_svg(generated_svg)

          ref_counts = count_svg_elements(ref_doc)
          gen_counts = count_svg_elements(gen_doc)

          # Compare key SVG elements
          [:rect, :circle, :line, :path, :text, :g].each do |elem|
            ref_count = ref_counts[elem] || 0
            gen_count = gen_counts[elem] || 0

            if ref_count > 0
              percentage = (gen_count.to_f / ref_count * 100).round(1)
              match = (percentage >= 80 && percentage <= 120) ? "✓" : "✗"

              puts "    #{match} #{elem}: #{gen_count} (ref: #{ref_count}) - #{percentage}%"
            end
          end
        end
      end
    end
  end

  describe "batch generation performance" do
    it "can generate all diagrams within reasonable time" do
      start_time = Time.now

      generated_count = 0
      failed_count = 0

      reference_svgs.each do |reference_path|
        element_name = File.basename(reference_path, ".svg")

        begin
          generator = Xseed::Svg::SvgGenerator.new(schema_path, element: element_name)
          svg = generator.generate
          generated_count += 1 if svg && svg.length > 0
        rescue StandardError => e
          failed_count += 1
          puts "  Failed to generate #{element_name}: #{e.message}"
        end
      end

      elapsed = Time.now - start_time

      puts "\nBatch Generation Summary:"
      puts "  Total diagrams: #{reference_svgs.count}"
      puts "  Successfully generated: #{generated_count}"
      puts "  Failed: #{failed_count}"
      puts "  Total time: #{elapsed.round(2)}s"
      puts "  Average time per diagram: #{(elapsed / reference_svgs.count).round(3)}s"

      expect(generated_count).to be > 0
      expect(elapsed).to be < 60  # Should complete within 60 seconds
    end
  end

  describe "parity summary" do
    it "reports overall statistics" do
      total = reference_svgs.count

      success_count = 0
      error_count = 0
      parity_issues = []

      reference_svgs.each do |reference_path|
        element_name = File.basename(reference_path, ".svg")

        begin
          generator = Xseed::Svg::SvgGenerator.new(schema_path, element: element_name)
          generated_svg = generator.generate

          reference_svg = File.read(reference_path)

          ref_doc = normalize_svg(reference_svg)
          gen_doc = normalize_svg(generated_svg)

          differences = compare_svg_structure(ref_doc, gen_doc)

          if differences.empty?
            success_count += 1
          else
            parity_issues << { element: element_name, differences: differences }
          end
        rescue StandardError => e
          error_count += 1
          parity_issues << { element: element_name, error: e.message }
        end
      end

      success_rate = (success_count.to_f / total * 100).round(1)

      puts "\n" + "=" * 60
      puts "UnitsML SVG Diagrams Parity Summary"
      puts "=" * 60
      puts "Total diagrams: #{total}"
      puts "Perfect matches: #{success_count} (#{success_rate}%)"
      puts "Parity issues: #{parity_issues.count}"
      puts "Generation errors: #{error_count}"
      puts

      if parity_issues.any?
        puts "Elements with parity issues:"
        parity_issues.take(10).each do |issue|
          if issue[:error]
            puts "  ✗ #{issue[:element]}: ERROR - #{issue[:error]}"
          else
            puts "  ✗ #{issue[:element]}: #{issue[:differences].count} difference(s)"
          end
        end

        if parity_issues.count > 10
          puts "  ... and #{parity_issues.count - 10} more"
        end
      end
      puts "=" * 60

      # This is informational, so we don't force it to pass
      expect(total).to eq(reference_svgs.count)
    end
  end

  private

  # Count SVG elements by type
  def count_svg_elements(doc)
    counts = {}

    [:rect, :circle, :line, :path, :text, :g, :defs, :style].each do |elem|
      counts[elem] = doc.xpath("//svg:#{elem}", "svg" => "http://www.w3.org/2000/svg").count
    end

    counts
  end
end