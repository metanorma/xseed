# frozen_string_literal: true

module ParityHelpers
  # Normalizes SVG content for comparison
  def normalize_svg(svg_content)
    doc = Nokogiri::XML(svg_content)
    
    # Remove whitespace-only text nodes
    doc.xpath("//text()").each do |node|
      node.remove if node.text.strip.empty?
    end
    
    # Sort attributes for consistent comparison
    doc.xpath("//*").each do |element|
      attrs = element.attribute_nodes.sort_by(&:name)
      attrs.each { |attr| element.delete(attr.name) }
      attrs.each { |attr| element[attr.name] = attr.value }
    end
    
    doc
  end
  
  # Normalizes HTML content for comparison
  def normalize_html(html_content)
    doc = Nokogiri::HTML(html_content)
    
    # Remove generated timestamps
    doc.xpath("//comment()").each do |node|
      node.remove if node.text =~ /generated|timestamp|date/i
    end
    
    # Remove whitespace-only text nodes
    doc.xpath("//text()").each do |node|
      node.remove if node.text.strip.empty?
    end
    
    doc
  end
  
  # Compares SVG structure and returns list of differences
  def compare_svg_structure(ref_doc, xseed_doc)
    differences = []
    
    # Compare root element
    if ref_doc.root&.name != xseed_doc.root&.name
      differences << "Root element mismatch: #{ref_doc.root&.name} vs #{xseed_doc.root&.name}"
    end
    
    # Compare element counts
    ref_elements = ref_doc.xpath("//*").count
    xseed_elements = xseed_doc.xpath("//*").count
    if ref_elements != xseed_elements
      differences << "Element count mismatch: #{ref_elements} vs #{xseed_elements}"
    end
    
    # Compare specific SVG elements
    %w[rect circle line path text g defs style].each do |elem|
      ref_count = ref_doc.xpath("//svg:#{elem}", "svg" => "http://www.w3.org/2000/svg").count
      xseed_count = xseed_doc.xpath("//svg:#{elem}", "svg" => "http://www.w3.org/2000/svg").count
      if ref_count != xseed_count
        differences << "#{elem} element count: #{ref_count} (ref) vs #{xseed_count} (xseed)"
      end
    end
    
    differences
  end
  
  # Compares HTML structure and returns list of differences
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
      differences << "Table count: #{ref_tables} (ref) vs #{xseed_tables} (xseed)"
    end
    
    # Compare heading hierarchy
    (1..6).each do |level|
      ref_count = ref_doc.css("h#{level}").count
      xseed_count = xseed_doc.css("h#{level}").count
      if ref_count != xseed_count
        differences << "h#{level} count: #{ref_count} (ref) vs #{xseed_count} (xseed)"
      end
    end
    
    # Check for CSS
    ref_has_css = ref_doc.at_css("style") || ref_doc.at_css("link[rel='stylesheet']")
    xseed_has_css = xseed_doc.at_css("style") || xseed_doc.at_css("link[rel='stylesheet']")
    if ref_has_css && !xseed_has_css
      differences << "Missing CSS styles"
    end
    
    # Check for JavaScript
    ref_has_js = ref_doc.at_css("script")
    xseed_has_js = xseed_doc.at_css("script")
    if ref_has_js && !xseed_has_js
      differences << "Missing JavaScript"
    end
    
    differences
  end
  
  # Generates a detailed diff report
  def generate_diff_report(differences, output_file)
    File.open(output_file, "w") do |f|
      f.puts "# Parity Verification Diff Report"
      f.puts "Generated: #{Time.now}"
      f.puts
      f.puts "## Differences Found"
      f.puts
      
      if differences.empty?
        f.puts "No differences found - outputs match!"
      else
        differences.each_with_index do |diff, idx|
          f.puts "#{idx + 1}. #{diff}"
        end
      end
    end
  end
end

# Include helpers in RSpec
RSpec.configure do |config|
  config.include ParityHelpers
end
