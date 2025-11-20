#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Advanced SVG Generation Usage
#
# This example demonstrates advanced features of Xseed including
# parser introspection, complex error handling, and custom workflows.

require "bundler/setup"
require "xseed"
require "fileutils"

# Advanced Example 1: Parser introspection and metadata extraction
def example_parser_introspection
  puts "Advanced Example 1: Parser Introspection"
  puts "=" * 60

  xsd_file = File.join(__dir__, "schemas", "person.xsd")
  parser = Xseed::Parser::XsdParser.new(xsd_file)

  puts "Schema Metadata:"
  puts "  Target Namespace: #{parser.target_namespace || 'None'}"
  puts "  Version: #{parser.schema_version || 'Not specified'}"
  puts "  Element Form Default: #{parser.element_form_default || 'Not specified'}"
  puts ""

  puts "Global Elements:"
  parser.elements.each do |element|
    name = element["name"] || element.name
    type = element["type"] || "inline"
    puts "  - #{name} (#{type})"

    # Extract documentation
    doc = parser.element_documentation(name)
    puts "    Doc: #{doc.strip}" if doc
  end
  puts ""

  puts "Complex Types:"
  parser.complex_types.each do |type|
    name = type["name"] || type.name
    puts "  - #{name}"

    # Extract documentation
    doc = parser.type_documentation(name)
    puts "    Doc: #{doc.strip}" if doc
  end
  puts ""

  puts "Simple Types:"
  parser.simple_types.each do |type|
    name = type["name"] || type.name
    puts "  - #{name}"
  end
  puts ""

  puts "Namespaces:"
  parser.namespaces.each do |prefix, uri|
    puts "  #{prefix}: #{uri}"
  end
  puts "\n"
end

# Advanced Example 2: Conditional generation based on schema analysis
def example_conditional_generation
  puts "Advanced Example 2: Conditional Generation"
  puts "=" * 60

  xsd_file = File.join(__dir__, "schemas", "person.xsd")
  parser = Xseed::Parser::XsdParser.new(xsd_file)

  # Analyze schema complexity
  total_components = parser.elements.size + parser.types.size
  puts "Schema complexity: #{total_components} components"

  if total_components > 50
    puts "⚠ Large schema detected - generation may take time"
  else
    puts "✓ Schema size is optimal"
  end

  # Check for documentation
  has_docs = !parser.documentation.nil?
  puts has_docs ? "✓ Schema has documentation" : "⚠ No schema-level documentation"

  # Generate with awareness of complexity
  output_file = File.join(__dir__, "output", "conditional-person.svg")
  FileUtils.mkdir_p(File.dirname(output_file))

  start_time = Time.now
  generator = Xseed::Svg::SvgGenerator.new(xsd_file)
  generator.generate_file(output_file)
  elapsed = Time.now - start_time

  puts "\nGeneration completed in #{(elapsed * 1000).round(2)}ms"
  puts "Output: #{output_file}\n\n"
end

# Advanced Example 3: Custom error handling and logging
def example_custom_error_handling
  puts "Advanced Example 3: Custom Error Handling"
  puts "=" * 60

  test_files = [
    File.join(__dir__, "schemas", "person.xsd"),
    File.join(__dir__, "schemas", "nonexistent.xsd"),
    File.join(__dir__, "invalid.txt"),
  ]

  results = { success: [], failed: [] }

  test_files.each do |xsd_file|
    puts "Processing: #{File.basename(xsd_file)}..."

    generator = Xseed::Svg::SvgGenerator.new(xsd_file)
    output_file = File.join(__dir__, "output",
                            "#{File.basename(xsd_file, '.xsd')}.svg")
    FileUtils.mkdir_p(File.dirname(output_file))

    generator.generate_file(output_file)
    results[:success] << xsd_file
    puts "  ✓ Success\n"
  rescue ArgumentError => e
    results[:failed] << { file: xsd_file, error: "Validation: #{e.message}" }
    puts "  ✗ Validation error: #{e.message}\n"
  rescue Xseed::ParserError => e
    results[:failed] << { file: xsd_file, error: "Parser: #{e.message}" }
    puts "  ✗ Parser error: #{e.message}\n"
  rescue Xseed::Svg::GenerationError => e
    results[:failed] << { file: xsd_file, error: "Generation: #{e.message}" }
    puts "  ✗ Generation error: #{e.message}\n"
  rescue StandardError => e
    results[:failed] << { file: xsd_file, error: "Unexpected: #{e.message}" }
    puts "  ✗ Unexpected error: #{e.message}\n"
  end

  puts "\nSummary:"
  puts "  Successful: #{results[:success].size}"
  puts "  Failed: #{results[:failed].size}"

  if results[:failed].any?
    puts "\nFailed files:"
    results[:failed].each do |failure|
      puts "  - #{File.basename(failure[:file])}: #{failure[:error]}"
    end
  end

  puts "\n"
end

# Advanced Example 4: Performance monitoring
def example_performance_monitoring
  puts "Advanced Example 4: Performance Monitoring"
  puts "=" * 60

  xsd_file = File.join(__dir__, "schemas", "person.xsd")
  output_file = File.join(__dir__, "output", "perf-person.svg")
  FileUtils.mkdir_p(File.dirname(output_file))

  # Measure each phase
  timings = {}

  # Phase 1: File validation
  timings[:validation] = measure_time do
    File.exist?(xsd_file) && File.readable?(xsd_file)
  end

  # Phase 2: Parsing
  parser = nil
  timings[:parsing] = measure_time do
    parser = Xseed::Parser::XsdParser.new(xsd_file)
  end

  # Phase 3: Generation
  generator = Xseed::Svg::SvgGenerator.new(xsd_file)
  timings[:generation] = measure_time do
    generator.generate
  end

  # Phase 4: File writing
  timings[:writing] = measure_time do
    generator.generate_file(output_file)
  end

  # Total time
  total = timings.values.sum

  puts "Performance Breakdown:"
  puts "  Validation:  #{format_time(timings[:validation])}"
  puts "  Parsing:     #{format_time(timings[:parsing])}"
  puts "  Generation:  #{format_time(timings[:generation])}"
  puts "  File Write:  #{format_time(timings[:writing])}"
  puts "  ─────────────────────────"
  puts "  Total:       #{format_time(total)}"

  # File size info
  file_size = File.size(output_file)
  puts "\nOutput File:"
  puts "  Path: #{output_file}"
  puts "  Size: #{format_bytes(file_size)}"
  puts "  Rate: #{format_bytes(file_size / total)}/s" if total.positive?

  puts "\n"
end

# Advanced Example 5: Integration with other tools
def example_tool_integration
  puts "Advanced Example 5: Tool Integration"
  puts "=" * 60

  xsd_file = File.join(__dir__, "schemas", "person.xsd")
  svg_file = File.join(__dir__, "output", "person-optimized.svg")
  FileUtils.mkdir_p(File.dirname(svg_file))

  # Generate SVG
  puts "Step 1: Generate SVG..."
  generator = Xseed::Svg::SvgGenerator.new(xsd_file)
  generator.generate_file(svg_file)
  puts "  ✓ Generated: #{svg_file}"

  # Example: Validate SVG with xmllint (if available)
  if system("which xmllint > /dev/null 2>&1")
    puts "\nStep 2: Validate SVG with xmllint..."
    if system("xmllint --noout #{svg_file} 2>&1")
      puts "  ✓ SVG is valid XML"
    else
      puts "  ✗ SVG validation failed"
    end
  else
    puts "\nStep 2: xmllint not available (skipping validation)"
  end

  # Example: Display stats
  puts "\nStep 3: File statistics..."
  lines = File.readlines(svg_file).size
  bytes = File.size(svg_file)
  puts "  Lines: #{lines}"
  puts "  Size: #{format_bytes(bytes)}"

  puts "\n"
end

# Helper methods
def measure_time
  start = Time.now
  yield
  Time.now - start
end

def format_time(seconds)
  if seconds < 0.001
    "#{(seconds * 1_000_000).round(2)}μs"
  elsif seconds < 1
    "#{(seconds * 1000).round(2)}ms"
  else
    "#{seconds.round(3)}s"
  end
end

def format_bytes(bytes)
  if bytes < 1024
    "#{bytes}B"
  elsif bytes < 1024 * 1024
    "#{(bytes / 1024.0).round(2)}KB"
  else
    "#{(bytes / 1024.0 / 1024.0).round(2)}MB"
  end
end

# Run all advanced examples
if __FILE__ == $PROGRAM_NAME
  puts "\n"
  puts "╔#{'═' * 58}╗"
  puts "║#{' ' * 11}Xseed Advanced Usage Examples#{' ' * 16}║"
  puts "╚#{'═' * 58}╝"
  puts "\n"

  example_parser_introspection
  example_conditional_generation
  example_custom_error_handling
  example_performance_monitoring
  example_tool_integration

  puts "All advanced examples completed!"
  puts "\nGenerated files are in: #{File.join(__dir__, 'output')}"
end
