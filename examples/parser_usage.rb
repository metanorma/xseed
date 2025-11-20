#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "xseed/parser/xsd_parser"

# Example 1: Parse a simple XSD file
puts "=" * 60
puts "Example 1: Parsing a Simple XSD File"
puts "=" * 60

xsd_file = File.join(__dir__, "../spec/fixtures/simple/element_only.xsd")
parser = Xseed::Parser::XsdParser.new(xsd_file)

puts "\nTarget Namespace: #{parser.target_namespace}"
puts "Element Form Default: #{parser.element_form_default}"
puts "\nSchema Documentation:"
puts parser.documentation

puts "\nGlobal Elements:"
parser.elements.each do |element|
  name = element["name"]
  type = element["type"]
  puts "  - #{name} (#{type})"
  doc = parser.element_documentation(name)
  puts "    Documentation: #{doc}" if doc
end

# Example 2: Parse XSD with complex types
puts "\n#{'=' * 60}"
puts "Example 2: Parsing XSD with Complex Types"
puts "=" * 60

xsd_file = File.join(__dir__, "../spec/fixtures/simple/complex_type.xsd")
parser = Xseed::Parser::XsdParser.new(xsd_file)

puts "\nTarget Namespace: #{parser.target_namespace}"

puts "\nComplex Types:"
parser.complex_types.each do |complex_type|
  name = complex_type["name"]
  puts "  - #{name}"
  doc = parser.type_documentation(name)
  puts "    Documentation: #{doc}" if doc
end

puts "\nGlobal Elements:"
parser.elements.each do |element|
  puts "  - #{element['name']} (type: #{element['type']})"
end

# Example 3: Parse XSD with simple types
puts "\n#{'=' * 60}"
puts "Example 3: Parsing XSD with Simple Types"
puts "=" * 60

xsd_file = File.join(__dir__, "../spec/fixtures/simple/simple_type.xsd")
parser = Xseed::Parser::XsdParser.new(xsd_file)

puts "\nTarget Namespace: #{parser.target_namespace}"

puts "\nSimple Types:"
parser.simple_types.each do |simple_type|
  name = simple_type["name"]
  puts "  - #{name}"
  doc = parser.type_documentation(name)
  puts "    Documentation: #{doc}" if doc
end

# Example 4: Explore namespace mappings
puts "\n#{'=' * 60}"
puts "Example 4: Namespace Mappings"
puts "=" * 60

puts "\nNamespace Prefixes:"
parser.namespaces.each do |prefix, uri|
  puts "  #{prefix} => #{uri}"
end

# Example 5: Parse real-world XSD
puts "\n#{'=' * 60}"
puts "Example 5: Parsing Real-World XSD (unitsml-v1.0.xsd)"
puts "=" * 60

xsd_file = File.join(
  __dir__,
  "../spec/fixtures/real_world/unitsml-v1.0.xsd",
)
parser = Xseed::Parser::XsdParser.new(xsd_file)

puts "\nTarget Namespace: #{parser.target_namespace}"
puts "Schema Version: #{parser.schema_version || 'N/A'}"
puts "\nStatistics:"
puts "  Elements: #{parser.elements.size}"
puts "  Complex Types: #{parser.complex_types.size}"
puts "  Simple Types: #{parser.simple_types.size}"
puts "  Total Types: #{parser.types.size}"
puts "  Groups: #{parser.groups.size}"

puts "\n#{'=' * 60}"
puts "All examples completed successfully!"
puts "=" * 60
