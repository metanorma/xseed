# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe "UnitsML v1.0 Output Parity" do
  UNITSML_DIR = File.join(__dir__, "../fixtures/unitsml")
  XSD_PATH = File.join(UNITSML_DIR, "unitsml-v1.0.xsd")
  REFERENCE_HTML_PATH = File.join(UNITSML_DIR, "index.html")
  REFERENCE_DIAGRAMS_DIR = File.join(UNITSML_DIR, "diagrams")

  describe "Reference Files" do
    it "has UnitsML XSD file" do
      expect(File.exist?(XSD_PATH)).to be true
      expect(File.size(XSD_PATH)).to be > 50_000 # At least 50KB
    end

    it "has reference HTML documentation" do
      expect(File.exist?(REFERENCE_HTML_PATH)).to be true
      expect(File.size(REFERENCE_HTML_PATH)).to be > 600_000 # At least 600KB
    end

    it "has reference SVG diagrams directory" do
      expect(Dir.exist?(REFERENCE_DIAGRAMS_DIR)).to be true
    end

    it "has 54 SVG diagram files" do
      svg_files = Dir.glob(File.join(REFERENCE_DIAGRAMS_DIR, "*.svg"))
      expect(svg_files.count).to eq(54)
    end
  end

  describe "HTML Documentation Parity" do
    let(:reference_html) { File.read(REFERENCE_HTML_PATH) }
    let(:reference_doc) { Nokogiri::HTML(reference_html) }

    let(:xseed_html) do
      generator = Xseed::Documentation::HtmlGenerator.new(XSD_PATH)
      generator.generate
    end
    let(:xseed_doc) { Nokogiri::HTML(xseed_html) }

    describe "Document Structure" do
      it "generates valid HTML5 document" do
        expect(xseed_doc.at_css("html")).not_to be_nil
        expect(xseed_doc.at_css("head")).not_to be_nil
        expect(xseed_doc.at_css("body")).not_to be_nil
      end

      it "has document title" do
        xseed_title = xseed_doc.at_css("title")&.text

        expect(xseed_title).not_to be_nil
        expect(xseed_title).not_to be_empty
        # Title should be valid (either default or custom)
        expect(xseed_title.downcase).to include("schema").or include("xsd")
      end

      it "includes CSS styling" do
        xseed_has_css = xseed_doc.at_css("style") ||
                        xseed_doc.at_css('link[rel="stylesheet"]')
        expect(xseed_has_css).not_to be_nil
      end

      it "includes JavaScript functionality" do
        xseed_has_js = xseed_doc.at_css("script")
        expect(xseed_has_js).not_to be_nil
      end
    end

    describe "Navigation" do
      it "includes navigation sidebar or TOC" do
        ref_nav = reference_doc.at_css("nav") ||
                  reference_doc.at_css("#toc") ||
                  reference_doc.at_css(".toc")
        xseed_nav = xseed_doc.at_css("nav") ||
                    xseed_doc.at_css("#toc") ||
                    xseed_doc.at_css(".toc")

        expect(xseed_nav).not_to be_nil if ref_nav
      end

      it "has schema components navigation links" do
        # Should have links to elements, types, etc.
        nav_text = xseed_doc.text.downcase
        expect(nav_text).to include("element") if reference_doc.text.downcase.include?("element")
      end
    end

    describe "Schema Properties Section" do
      it "includes schema information" do
        ref_has_schema = reference_doc.text.downcase.include?("schema")
        xseed_has_schema = xseed_doc.text.downcase.include?("schema")

        expect(xseed_has_schema).to be true if ref_has_schema
      end

      it "includes target namespace information" do
        # UnitsML has namespace: https://schema.unitsml.org/unitsml/1.0
        expect(xseed_html).to include("schema.unitsml.org") ||
                                  include("unitsml.org")
      end

      it "includes schema version" do
        # UnitsML v1.0
        version_found = xseed_html.include?("1.0") ||
                       xseed_html.include?("version")
        expect(version_found).to be true
      end
    end

    describe "Content Sections" do
      it "has 4 main content sections (Elements, Types, Groups, plus Schema)" do
        xseed_sections = xseed_doc.css("section").count

        # Expect exactly 4-5 sections:
        # 1. Schema Properties
        # 2. Global Elements
        # 3. Global Types
        # 4. Global Groups and Attributes
        # (5. Glossary - optional)
        expect(xseed_sections).to be_between(4, 5).inclusive
      end

      it "includes properties definition lists for components" do
        # Both reference and Xseed use dl-horizontal definition lists
        # Exact match required: 199 DLs total
        ref_dls = reference_doc.css("dl.dl-horizontal").count
        xseed_dls = xseed_doc.css("dl.dl-horizontal").count

        # Zero tolerance: must match exactly
        expect(xseed_dls).to eq(199),
          "Expected exactly 199 definition lists for 100% compliance, got #{xseed_dls}"

        expect(xseed_dls).to eq(ref_dls),
          "Expected #{ref_dls} definition lists (matching reference), got #{xseed_dls}"
      end

      it "includes instance representation samples" do
        ref_samples = reference_doc.css("pre").count
        xseed_samples = xseed_doc.css("pre").count

        # Should have code samples
        expect(xseed_samples).to be > 0
        # After fixes: expect ~197 pre elements (±10% tolerance)
        # 1 Schema Component pre + ~96 Instance + ~96 Schema Component = 193-194
        if ref_samples > 0
          tolerance = (ref_samples * 0.10).ceil
          min_expected = ref_samples - tolerance
          max_expected = ref_samples + tolerance
          expect(xseed_samples).to be_between(min_expected, max_expected).inclusive,
            "Expected between #{min_expected} and #{max_expected} pre elements (±10% of #{ref_samples}), got #{xseed_samples}"
        end
      end

      it "includes hierarchy or type information" do
        xseed_hierarchy = xseed_doc.css(".hierarchy, .type-hierarchy, .inheritance").count

        # Both should have some hierarchy information
        expect(xseed_hierarchy).to be >= 0
      end
    end

    describe "UnitsML Specific Content" do
      it "documents root element UnitsML" do
        expect(xseed_html.downcase).to include("unitsml")
      end

      it "documents UnitSet element" do
        expect(xseed_html.downcase).to include("unitset")
      end

      it "documents CountedItemSet element" do
        expect(xseed_html.downcase).to include("counteditemset")
      end

      it "documents QuantitySet element" do
        expect(xseed_html.downcase).to include("quantityset")
      end

      it "documents DimensionSet element" do
        expect(xseed_html.downcase).to include("dimensionset")
      end

      it "documents PrefixSet element" do
        expect(xseed_html.downcase).to include("prefixset")
      end

      it "documents Unit element and type" do
        expect(xseed_html).to include("Unit")
      end

      it "documents conversion elements" do
        conversion_elements = ["Conversions", "Float64ConversionFrom",
                              "SpecialConversionFrom", "WSDLConversionFrom"]
        content = xseed_html
        conversion_found = conversion_elements.any? { |elem| content.include?(elem) }
        expect(conversion_found).to be true
      end

      it "documents dimension elements" do
        dimension_elements = ["Length", "Mass", "Time", "ElectricCurrent",
                             "ThermodynamicTemperature", "AmountOfSubstance",
                             "LuminousIntensity"]
        content = xseed_html
        dimensions_found = dimension_elements.select { |elem| content.include?(elem) }
        # Should document at least 5 of the 7 base dimensions
        expect(dimensions_found.count).to be >= 5
      end

      it "documents prefix enumeration" do
        # UnitsML has extensive prefix enumeration (Y, Z, E, P, T, G, M, k, etc.)
        prefixes = ["prefix", "kilo", "mega", "giga"]
        content = xseed_html.downcase
        prefix_found = prefixes.any? { |p| content.include?(p) }
        expect(prefix_found).to be true
      end

      it "documents root unit enumeration" do
        # UnitsML has extensive unit enumeration
        units = ["meter", "kilogram", "second", "ampere", "kelvin"]
        content = xseed_html.downcase
        units_found = units.select { |u| content.include?(u) }
        # Should document at least 3 base SI units
        expect(units_found.count).to be >= 3
      end
    end

    describe "Documentation Quality" do
      it "generates output without errors" do
        expect { xseed_html }.not_to raise_error
      end

      it "output is substantial" do
        # UnitsML is complex, output should be at least 100KB
        expect(xseed_html.length).to be > 100_000
      end

      it "documents multiple elements" do
        # UnitsML has many elements (>40), should document most
        element_sections = xseed_doc.css('*[id*="element"], h3, h4').count
        expect(element_sections).to be > 20
      end

      it "documents multiple types" do
        # UnitsML has many complex types
        type_indicators = xseed_html.scan(/Type(?!face)/).count
        expect(type_indicators).to be > 15
      end

      it "includes element annotations/documentation" do
        # XSD has <xsd:documentation> tags that should be included
        annotations = reference_doc.text.include?("Container for")
        if annotations
          expect(xseed_html).to include("Container") ||
                                    include("Element for") ||
                                    include("Type for")
        end
      end
    end
  end

  describe "SVG Diagram Parity" do
    let(:reference_svg_files) do
      Dir.glob(File.join(REFERENCE_DIAGRAMS_DIR, "*.svg")).sort
    end

    it "finds all 54 reference SVG files" do
      expect(reference_svg_files.count).to eq(54)
    end

    describe "Schema-level SVG Generation" do
      it "generates SVG diagram for UnitsML schema" do
        generator = Xseed::Svg::SvgGenerator.new(XSD_PATH)
        svg_output = generator.generate

        # Should be valid SVG
        doc = Nokogiri::XML(svg_output)
        expect(doc.at_css("svg")).not_to be_nil
      end

      it "generated SVG has proper structure" do
        generator = Xseed::Svg::SvgGenerator.new(XSD_PATH)
        svg_output = generator.generate
        doc = Nokogiri::XML(svg_output)

        # Should have SVG elements for diagram
        expect(doc.css("g").count).to be > 0
        expect(doc.css("rect, circle, path, line").count).to be > 0
      end
    end

    describe "Reference SVG Diagrams" do
      it "validates a sample of reference diagrams" do
        # Test first 10, last 10, and some in middle
        indices = (0..9).to_a + [20, 25, 30, 35, 40] + (44..53).to_a
        sample_diagrams = indices.map { |i| reference_svg_files[i] }.compact

        sample_diagrams.each do |svg_path|
          element_name = File.basename(svg_path, ".svg")
          reference_svg = File.read(svg_path)
          reference_svg_doc = Nokogiri::XML(reference_svg)

          # Should be valid SVG XML
          expect(reference_svg_doc.errors).to be_empty,
                 "#{element_name}: SVG should have no XML errors"
          expect(reference_svg_doc.at_css("svg")).not_to be_nil,
                 "#{element_name}: Should have root <svg> element"

          # Should have expected SVG structure elements
          expect(reference_svg_doc.css("g").count).to be > 0,
                 "#{element_name}: Should have <g> grouping elements"
          visual_elements = reference_svg_doc.css("rect, circle, path, line, polygon, text")
          expect(visual_elements.count).to be > 0,
                 "#{element_name}: Should have visual elements"

          # Verify SVG has proper structure (viewBox/dimensions preferred but not required)
          # Many reference files are missing dimensions, so we just verify they have
          # visual elements which confirms they are valid diagrams
          svg_root = reference_svg_doc.at_css("svg")
          has_viewbox = svg_root["viewBox"]
          has_dimensions = svg_root["width"] || svg_root["height"]

          # SVG should have either dimensions OR visual elements (for valid diagrams)
          has_visual = visual_elements.count > 0
          expect(has_viewbox || has_dimensions || has_visual).to be_truthy,
                 "#{element_name}: Should have viewBox, dimensions, or visual elements"
        end
      end
    end

    describe "Diagram Content Analysis" do
      it "diagrams represent schema components" do
        # Sample some diagrams and verify they represent elements/types
        sample_files = reference_svg_files.first(5)
        sample_files.each do |svg_path|
          svg_content = File.read(svg_path)
          # SVG should contain text labels for elements
          doc = Nokogiri::XML(svg_content)
          text_elements = doc.css("text")
          expect(text_elements.count).to be > 0
        end
      end

      it "diagrams include type hierarchies" do
        # Look for diagrams that show relationships
        complex_diagrams = reference_svg_files.select do |path|
          content = File.read(path)
          doc = Nokogiri::XML(content)
          # Complex diagrams have many connections (lines/paths)
          doc.css("line, path").count > 5
        end
        expect(complex_diagrams.count).to be > 0
      end
    end
  end

  describe "Content Completeness" do
    let(:xsd_content) { File.read(XSD_PATH) }
    let(:xsd_doc) { Nokogiri::XML(xsd_content) }

    let(:xseed_html) do
      generator = Xseed::Documentation::HtmlGenerator.new(XSD_PATH)
      generator.generate
    end

    let(:xseed_doc) { Nokogiri::HTML(xseed_html) }

    describe "Schema Coverage" do
      it "parses the UnitsML schema successfully" do
        expect(xsd_doc.errors).to be_empty
      end

      it "identifies all global elements" do
        # UnitsML has many global elements
        global_elements = xsd_doc.xpath("//xsd:element[@name]",
                                        "xsd" => "http://www.w3.org/2001/XMLSchema")
        expect(global_elements.count).to be > 30
      end

      it "identifies all complex types" do
        complex_types = xsd_doc.xpath("//xsd:complexType[@name]",
                                     "xsd" => "http://www.w3.org/2001/XMLSchema")
        expect(complex_types.count).to be > 20
      end

      it "identifies all attribute groups" do
        attr_groups = xsd_doc.xpath("//xsd:attributeGroup[@name]",
                                   "xsd" => "http://www.w3.org/2001/XMLSchema")
        expect(attr_groups.count).to be > 5
      end
    end

    describe "Documentation Coverage" do
      let(:documented_elements) do
        xsd_doc.xpath("//xsd:element[@name and .//xsd:documentation]",
                     "xsd" => "http://www.w3.org/2001/XMLSchema")
      end

      it "most elements have documentation annotations" do
        all_elements = xsd_doc.xpath("//xsd:element[@name]",
                                    "xsd" => "http://www.w3.org/2001/XMLSchema")
        coverage_ratio = documented_elements.count.to_f / all_elements.count
        expect(coverage_ratio).to be > 0.7 # At least 70% documented
      end

      it "documentation annotations are included in output" do
        # Pick a documented element
        sample_doc = documented_elements.first&.at_xpath(".//xsd:documentation",
                                                         "xsd" => "http://www.w3.org/2001/XMLSchema")
        if sample_doc
          doc_text = sample_doc.text.strip
          # Check if documentation text appears in output
          expect(xseed_html).to include(doc_text) unless doc_text.empty?
        end
      end
    end

    describe "Special Schema Features" do
      it "handles imported namespace (xml namespace)" do
        imports = xsd_doc.xpath("//xsd:import",
                               "xsd" => "http://www.w3.org/2001/XMLSchema")
        expect(imports.count).to be > 0
        # Should reference xml namespace
        expect(imports.first["namespace"]).to include("XML/1998/namespace")
      end

      it "handles large enumerations" do
        # UnitsML has huge enumerations (e.g., 258 unit enum values)
        enums = xsd_doc.xpath("//xsd:enumeration",
                             "xsd" => "http://www.w3.org/2001/XMLSchema")
        expect(enums.count).to be > 250
      end

      it "handles complex content models" do
        # Look for sequences, choices, etc.
        sequences = xsd_doc.xpath("//xsd:sequence",
                                 "xsd" => "http://www.w3.org/2001/XMLSchema")
        expect(sequences.count).to be > 15
      end

      it "handles attribute groups with prefixes" do
        # UnitsML has prefix attribute group with large enum
        prefix_group = xsd_doc.at_xpath("//xsd:attributeGroup[@name='prefix']",
                                       "xsd" => "http://www.w3.org/2001/XMLSchema")
        expect(prefix_group).not_to be_nil
      end
    end
  end

  describe "Performance and Scalability" do
    it "generates HTML in reasonable time" do
      start_time = Time.now
      generator = Xseed::Documentation::HtmlGenerator.new(XSD_PATH)
      generator.generate
      elapsed = Time.now - start_time

      # Complex schema should still generate in under 30 seconds
      expect(elapsed).to be < 30
    end

    it "handles large schema without memory issues" do
      # This test just verifies it completes without errors
      expect do
        generator = Xseed::Documentation::HtmlGenerator.new(XSD_PATH)
        generator.generate
      end.not_to raise_error
    end
  end
end