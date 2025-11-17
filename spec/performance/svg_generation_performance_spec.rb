# frozen_string_literal: true

require "spec_helper"
require "benchmark"
require "objspace"

RSpec.describe "SVG Generation Performance Benchmarks", :performance do
  let(:fixtures_path) { File.expand_path("../fixtures", __dir__) }
  let(:output_dir) { File.expand_path("../../tmp/performance", __dir__) }

  before(:all) do
    FileUtils.mkdir_p(File.expand_path("../../tmp/performance", __dir__))
  end

  after(:all) do
    FileUtils.rm_rf(File.expand_path("../../tmp/performance", __dir__))
  end

  describe "Schema size benchmarks" do
    context "with small schema (element_only.xsd)" do
      let(:xsd_file) do
        File.join(fixtures_path, "simple", "element_only.xsd")
      end

      it "generates SVG in under 100ms" do
        elapsed_time = Benchmark.realtime do
          generator = Xseed::Svg::SvgGenerator.new(xsd_file)
          generator.generate
        end

        expect(elapsed_time).to be < 0.1
        puts "\n  Small schema generation time: #{(elapsed_time * 1000).round(2)}ms"
      end

      it "uses minimal memory (< 5MB)" do
        GC.start
        before_memory = ObjectSpace.memsize_of_all

        generator = Xseed::Svg::SvgGenerator.new(xsd_file)
        generator.generate

        GC.start
        after_memory = ObjectSpace.memsize_of_all
        memory_used_mb = (after_memory - before_memory) / 1024.0 / 1024.0

        expect(memory_used_mb).to be < 5
        puts "\n  Small schema memory usage: #{memory_used_mb.round(2)}MB"
      end
    end

    context "with medium schema (complex_type.xsd)" do
      let(:xsd_file) do
        File.join(fixtures_path, "simple", "complex_type.xsd")
      end

      it "generates SVG in under 200ms" do
        elapsed_time = Benchmark.realtime do
          generator = Xseed::Svg::SvgGenerator.new(xsd_file)
          generator.generate
        end

        expect(elapsed_time).to be < 0.2
        puts "\n  Medium schema generation time: #{(elapsed_time * 1000).round(2)}ms"
      end

      it "uses reasonable memory (< 10MB)" do
        GC.start
        before_memory = ObjectSpace.memsize_of_all

        generator = Xseed::Svg::SvgGenerator.new(xsd_file)
        generator.generate

        GC.start
        after_memory = ObjectSpace.memsize_of_all
        memory_used_mb = (after_memory - before_memory) / 1024.0 / 1024.0

        expect(memory_used_mb).to be < 10
        puts "\n  Medium schema memory usage: #{memory_used_mb.round(2)}MB"
      end
    end

    context "with large real-world schema (unitsml-v1.0.xsd)" do
      let(:xsd_file) do
        File.join(fixtures_path, "real_world", "unitsml-v1.0.xsd")
      end

      it "generates SVG in under 2 seconds" do
        elapsed_time = Benchmark.realtime do
          generator = Xseed::Svg::SvgGenerator.new(xsd_file)
          generator.generate
        end

        expect(elapsed_time).to be < 2.0
        puts "\n  Large schema generation time: #{(elapsed_time * 1000).round(2)}ms"
      end

      it "uses acceptable memory (< 50MB)" do
        GC.start
        before_memory = ObjectSpace.memsize_of_all

        generator = Xseed::Svg::SvgGenerator.new(xsd_file)
        generator.generate

        GC.start
        after_memory = ObjectSpace.memsize_of_all
        memory_used_mb = (after_memory - before_memory) / 1024.0 / 1024.0

        expect(memory_used_mb).to be < 50
        puts "\n  Large schema memory usage: #{memory_used_mb.round(2)}MB"
      end
    end
  end

  describe "Component benchmarks" do
    let(:xsd_file) do
      File.join(fixtures_path, "real_world", "unitsml-v1.0.xsd")
    end

    it "parses XSD efficiently (< 500ms)" do
      elapsed_time = Benchmark.realtime do
        Xseed::Parser::XsdParser.new(xsd_file)
      end

      expect(elapsed_time).to be < 0.5
      puts "\n  XSD parsing time: #{(elapsed_time * 1000).round(2)}ms"
    end

    it "builds symbol tree efficiently (< 800ms)" do
      elapsed_time = Benchmark.realtime do
        Xseed::Svg::SvgGenerator.new(xsd_file)
      end

      expect(elapsed_time).to be < 0.8
      puts "\n  Symbol tree building time: #{(elapsed_time * 1000).round(2)}ms"
    end

    it "performs layout and rendering efficiently (< 1000ms)" do
      generator = Xseed::Svg::SvgGenerator.new(xsd_file)

      elapsed_time = Benchmark.realtime do
        generator.generate
      end

      expect(elapsed_time).to be < 1.0
      puts "\n  Full generation time: #{(elapsed_time * 1000).round(2)}ms"
    end
  end

  describe "Symbol tree complexity" do
    it "handles deep nesting efficiently" do
      # Create a deeply nested structure
      root = Xseed::Svg::Symbol::ElementSymbol.new(
        name: "root",
        type: "complexType",
        xsd_node: double(
          "node",
          name: "root",
          namespace: nil,
          xpath: "/root"
        )
      )

      current = root
      50.times do |i|
        child = Xseed::Svg::Symbol::ElementSymbol.new(
          name: "child_#{i}",
          type: "complexType",
          xsd_node: double(
            "node",
            name: "child_#{i}",
            namespace: nil,
            xpath: "/child_#{i}"
          )
        )
        current.add_child(child)
        current = child
      end

      elapsed_time = Benchmark.realtime do
        layout_engine = Xseed::Svg::LayoutEngine.new(root)
        layout_engine.layout
      end

      expect(elapsed_time).to be < 0.1
      puts "\n  Deep nesting (50 levels) layout time: #{(elapsed_time * 1000).round(2)}ms"
    end

    it "handles wide trees efficiently" do
      # Create a wide tree structure
      root = Xseed::Svg::Symbol::ElementSymbol.new(
        name: "root",
        type: "complexType",
        xsd_node: double(
          "node",
          name: "root",
          namespace: nil,
          xpath: "/root"
        )
      )

      100.times do |i|
        child = Xseed::Svg::Symbol::ElementSymbol.new(
          name: "child_#{i}",
          type: "complexType",
          xsd_node: double(
            "node",
            name: "child_#{i}",
            namespace: nil,
            xpath: "/child_#{i}"
          )
        )
        root.add_child(child)
      end

      elapsed_time = Benchmark.realtime do
        layout_engine = Xseed::Svg::LayoutEngine.new(root)
        layout_engine.layout
      end

      expect(elapsed_time).to be < 0.2
      puts "\n  Wide tree (100 children) layout time: #{(elapsed_time * 1000).round(2)}ms"
    end
  end

  describe "File I/O performance" do
    let(:xsd_file) do
      File.join(fixtures_path, "real_world", "unitsml-v1.0.xsd")
    end
    let(:output_file) { File.join(output_dir, "performance_test.svg") }

    it "writes SVG to file efficiently (< 100ms)" do
      generator = Xseed::Svg::SvgGenerator.new(xsd_file)

      elapsed_time = Benchmark.realtime do
        generator.generate_file(output_file)
      end

      expect(elapsed_time).to be < 0.1
      expect(File.exist?(output_file)).to be true
      puts "\n  SVG file write time: #{(elapsed_time * 1000).round(2)}ms"
    end
  end

  describe "Memory leak detection" do
    let(:xsd_file) do
      File.join(fixtures_path, "simple", "element_only.xsd")
    end

    it "does not leak memory on repeated generation" do
      GC.start
      before_memory = ObjectSpace.memsize_of_all

      10.times do
        generator = Xseed::Svg::SvgGenerator.new(xsd_file)
        generator.generate
      end

      GC.start
      after_memory = ObjectSpace.memsize_of_all
      memory_increase_mb = (after_memory - before_memory) / 1024.0 / 1024.0

      # Allow some memory increase, but not proportional to iterations
      expect(memory_increase_mb).to be < 10
      puts "\n  Memory increase after 10 iterations: #{memory_increase_mb.round(2)}MB"
    end
  end

  describe "Performance characteristics summary" do
    it "documents overall performance profile" do
      results = {}

      # Small schema
      small_file = File.join(fixtures_path, "simple", "element_only.xsd")
      results[:small] = Benchmark.realtime do
        Xseed::Svg::SvgGenerator.new(small_file).generate
      end

      # Medium schema
      medium_file = File.join(fixtures_path, "simple", "complex_type.xsd")
      results[:medium] = Benchmark.realtime do
        Xseed::Svg::SvgGenerator.new(medium_file).generate
      end

      # Large schema
      large_file = File.join(fixtures_path, "real_world", "unitsml-v1.0.xsd")
      results[:large] = Benchmark.realtime do
        Xseed::Svg::SvgGenerator.new(large_file).generate
      end

      puts "\n"
      puts "  ═══════════════════════════════════════════════════"
      puts "  Performance Characteristics Summary"
      puts "  ═══════════════════════════════════════════════════"
      puts "  Small schema:  #{(results[:small] * 1000).round(2)}ms"
      puts "  Medium schema: #{(results[:medium] * 1000).round(2)}ms"
      puts "  Large schema:  #{(results[:large] * 1000).round(2)}ms"
      puts "  ═══════════════════════════════════════════════════"
      puts ""

      expect(results[:small]).to be < 0.1
      expect(results[:medium]).to be < 0.2
      expect(results[:large]).to be < 2.0
    end
  end
end
