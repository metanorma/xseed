#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Simple SVG Generation
#
# This example demonstrates the basic usage of Xseed for generating
# SVG diagrams from XSD schema files.

require "bundler/setup"
require "xseed"

# Example 1: Generate SVG and print to stdout
def example_generate_to_stdout
  puts "Example 1: Generate SVG to stdout"
  puts "=" * 60

  # Path to example XSD file
  xsd_file = File.join(__dir__, "schemas", "person.xsd")

  # Create generator
  generator = Xseed::Svg::SvgGenerator.new(xsd_file)

  # Generate SVG content
  svg_content = generator.generate

  # Print first 200 characters
  puts svg_content[0..200]
  puts "..."
  puts "\n✓ SVG generated successfully (#{svg_content.length} bytes)\n\n"
end

# Example 2: Generate SVG and save to file
def example_generate_to_file
  puts "Example 2: Generate SVG to file"
  puts "=" * 60

  xsd_file = File.join(__dir__, "schemas", "person.xsd")
  output_file = File.join(__dir__, "output", "person-diagram.svg")

  # Ensure output directory exists
  FileUtils.mkdir_p(File.dirname(output_file))

  # Create generator and generate file
  generator = Xseed::Svg::SvgGenerator.new(xsd_file)
  result = generator.generate_file(output_file)

  puts "✓ SVG diagram saved to: #{result}"
  puts "  File size: #{File.size(result)} bytes\n\n"
end

# Example 3: Error handling
def example_with_error_handling
  puts "Example 3: Generate with error handling"
  puts "=" * 60

  xsd_file = File.join(__dir__, "schemas", "person.xsd")
  output_file = File.join(__dir__, "output", "person-safe.svg")

  FileUtils.mkdir_p(File.dirname(output_file))

  begin
    generator = Xseed::Svg::SvgGenerator.new(xsd_file)
    generator.generate_file(output_file)
    puts "✓ Generation successful: #{output_file}\n\n"
  rescue ArgumentError => e
    puts "✗ Validation error: #{e.message}\n\n"
  rescue Xseed::ParserError => e
    puts "✗ Parser error: #{e.message}\n\n"
  rescue Xseed::Svg::GenerationError => e
    puts "✗ Generation error: #{e.message}\n\n"
  rescue StandardError => e
    puts "✗ Unexpected error: #{e.message}\n\n"
  end
end

# Example 4: Inspect schema before generation
def example_inspect_before_generate
  puts "Example 4: Inspect schema metadata"
  puts "=" * 60

  xsd_file = File.join(__dir__, "schemas", "person.xsd")

  # Parse to inspect metadata
  parser = Xseed::Parser::XsdParser.new(xsd_file)

  puts "Schema Information:"
  puts "  Target Namespace: #{parser.target_namespace}"
  puts "  Version: #{parser.schema_version || 'Not specified'}"
  puts "  Elements: #{parser.elements.size}"
  puts "  Complex Types: #{parser.complex_types.size}"
  puts "  Simple Types: #{parser.simple_types.size}"
  puts ""

  # Now generate
  generator = Xseed::Svg::SvgGenerator.new(xsd_file)
  output_file = File.join(__dir__, "output", "person-inspected.svg")
  FileUtils.mkdir_p(File.dirname(output_file))
  generator.generate_file(output_file)

  puts "✓ SVG generated after inspection: #{output_file}\n\n"
end

# Example 5: Batch processing multiple schemas
def example_batch_processing
  puts "Example 5: Batch process multiple schemas"
  puts "=" * 60

  schemas_dir = File.join(__dir__, "schemas")
  output_dir = File.join(__dir__, "output", "batch")
  FileUtils.mkdir_p(output_dir)

  # Find all XSD files
  xsd_files = Dir.glob(File.join(schemas_dir, "*.xsd"))

  puts "Found #{xsd_files.size} schema files\n"

  xsd_files.each do |xsd_file|
    basename = File.basename(xsd_file, ".xsd")
    output_file = File.join(output_dir, "#{basename}-diagram.svg")

    begin
      generator = Xseed::Svg::SvgGenerator.new(xsd_file)
      generator.generate_file(output_file)
      puts "  ✓ #{basename}.xsd → #{basename}-diagram.svg"
    rescue StandardError => e
      puts "  ✗ #{basename}.xsd: #{e.message}"
    end
  end

  puts "\n✓ Batch processing complete\n\n"
end

# Run all examples
if __FILE__ == $PROGRAM_NAME
  puts "\n"
  puts "╔#{'═' * 58}╗"
  puts "║#{' ' * 12}Xseed Simple Generation Examples#{' ' * 13}║"
  puts "╚#{'═' * 58}╝"
  puts "\n"

  example_generate_to_stdout
  example_generate_to_file
  example_with_error_handling
  example_inspect_before_generate
  example_batch_processing

  puts "All examples completed!"
  puts "\nGenerated files are in: #{File.join(__dir__, 'output')}"
end
