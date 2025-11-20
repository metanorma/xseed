#!/usr/bin/env ruby
# frozen_string_literal: true

# Usage Examples for Xseed HTML Documentation Generation
# Phase 2: Weeks 5-6 - Final Integration and Testing

require_relative "../lib/xseed"

puts "=== Xseed HTML Documentation Generation Examples ===\n\n"

# Example 1: Basic HTML generation
puts "Example 1: Basic HTML Generation"
puts "-" * 50

begin
  # Create generator with default configuration
  xsd_path = File.expand_path("../spec/fixtures/simple/element_only.xsd",
                              __dir__)
  generator = Xseed::Documentation::HtmlGenerator.new(xsd_path)

  # Generate HTML to string
  html = generator.generate

  # Write to file
  output_path = File.expand_path("../tmp/example1_basic.html", __dir__)
  FileUtils.mkdir_p(File.dirname(output_path))
  File.write(output_path, html)

  puts "✓ Generated basic HTML documentation"
  puts "  Output: tmp/example1_basic.html"
  puts "  Features: Default styling, navigation, properties tables, instance samples"
  puts
rescue StandardError => e
  puts "✗ Error: #{e.message}"
  puts
end

# Example 2: Custom configuration
puts "Example 2: Custom Configuration"
puts "-" * 50

begin
  # Create custom configuration
  config = Xseed::Documentation::Config.new
  config.title = "My Custom Schema Documentation"
  config.sort_by_component = true
  config.print_glossary = true

  # Create generator with custom config
  xsd_path = File.expand_path("../spec/fixtures/simple/element_only.xsd",
                              __dir__)
  generator = Xseed::Documentation::HtmlGenerator.new(xsd_path, config)

  # Generate directly to file
  output_path = File.expand_path("../tmp/example2_custom.html", __dir__)
  FileUtils.mkdir_p(File.dirname(output_path))
  generator.generate_file(output_path)

  puts "✓ Generated HTML with custom configuration"
  puts "  Output: tmp/example2_custom.html"
  puts "  Custom title: #{config.title}"
  puts "  Sorted by component: #{config.sort_by_component}"
  puts "  Includes glossary: #{config.print_glossary}"
  puts
rescue StandardError => e
  puts "✗ Error: #{e.message}"
  puts
end

# Example 3: External CSS/JS (demonstration)
puts "Example 3: External CSS/JS Configuration"
puts "-" * 50

begin
  # Create configuration with external resources
  config = Xseed::Documentation::Config.new
  config.title = "Schema with External Resources"
  # NOTE: These would typically point to actual hosted files
  # config.external_css_url = "https://example.com/custom.css"
  # config.jquery_url = "https://example.com/jquery.js"

  xsd_path = File.expand_path("../spec/fixtures/simple/element_only.xsd",
                              __dir__)
  generator = Xseed::Documentation::HtmlGenerator.new(xsd_path, config)

  html = generator.generate
  output_path = File.expand_path("../tmp/example3_external.html", __dir__)
  FileUtils.mkdir_p(File.dirname(output_path))
  File.write(output_path, html)

  puts "✓ Generated HTML with external resource configuration"
  puts "  Output: tmp/example3_external.html"
  puts "  Note: External CSS/JS URLs can be configured via Config object"
  puts "  Default: Uses embedded styles and CDN-hosted jQuery/Bootstrap"
  puts
rescue StandardError => e
  puts "✗ Error: #{e.message}"
  puts
end

# Example 4: Batch generation
puts "Example 4: Batch Generation"
puts "-" * 50

begin
  # Define schemas to process
  base_dir = File.expand_path("..", __dir__)
  schemas = [
    File.join(base_dir, "spec/fixtures/simple/element_only.xsd"),
  ]

  # Process each schema
  tmp_dir = File.expand_path("../tmp", __dir__)
  FileUtils.mkdir_p(tmp_dir)

  schemas.each do |xsd_file|
    next unless File.exist?(xsd_file)

    name = File.basename(xsd_file, ".xsd")
    output_file = File.join(tmp_dir, "batch_#{name}.html")

    # Create generator
    config = Xseed::Documentation::Config.new
    config.title = "#{name.tr('_', ' ').capitalize} Schema"

    generator = Xseed::Documentation::HtmlGenerator.new(xsd_file, config)
    generator.generate_file(output_file)

    puts "✓ Generated: #{output_file}"
  end

  puts "\n✓ Batch generation complete"
  puts "  All schemas processed successfully"
  puts
rescue StandardError => e
  puts "✗ Error: #{e.message}"
  puts
end

# Example 5: CLI Usage Examples
puts "Example 5: CLI Usage"
puts "-" * 50

puts <<~CLI_EXAMPLES
  Basic usage:
    $ xseed html schema.xsd -o output.html

  With custom title:
    $ xseed html schema.xsd -o output.html --title "My Schema"

  With verbose output:
    $ xseed html schema.xsd -o output.html --verbose

  Combine options:
    $ xseed html schema.xsd -o output.html \\
        --title "Custom Title" \\
        --verbose

  Using from Ruby code:
    require 'xseed'
    generator = Xseed::Documentation::HtmlGenerator.new('schema.xsd')
    generator.generate_file('output.html')
CLI_EXAMPLES

puts "=== Examples Complete ===\n"
puts "Output files generated in tmp/ directory"
puts "Open any HTML file in a web browser to view the documentation"
