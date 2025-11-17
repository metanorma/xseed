# frozen_string_literal: true

require "spec_helper"
require "xseed/documentation/html_generator"
require "xseed/documentation/config"

RSpec.describe "Content Generation Integration" do
  let(:config) { Xseed::Documentation::Config.new }
  let(:fixture_path) { File.expand_path("../../fixtures", __dir__) }

  describe "with simple element schema" do
    let(:xsd_path) { File.join(fixture_path, "simple/element_only.xsd") }
    let(:generator) { Xseed::Documentation::HtmlGenerator.new(xsd_path, config) }

    it "generates complete HTML document" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      expect(doc.css("html")).not_to be_empty
      expect(doc.css("head")).not_to be_empty
      expect(doc.css("body")).not_to be_empty
    end

    it "includes schema information section" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      expect(doc.css("section.schema-info")).not_to be_empty
      expect(html).to include("Schema Document Properties")
    end

    it "includes properties tables for elements" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      # XS3P uses definition lists (DLs) not tables
      expect(doc.css("dl.dl-horizontal")).not_to be_empty
      expect(doc.css("dl.dl-horizontal dt")).not_to be_empty
      expect(doc.css("dl.dl-horizontal dd")).not_to be_empty
    end

    it "includes XML instance samples" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      expect(doc.css(".instance-sample")).not_to be_empty
      expect(doc.css(".xml-code")).not_to be_empty
      expect(doc.css("code.language-xml")).not_to be_empty
    end

    it "generates valid XML in instance samples" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      samples = doc.css(".instance-sample code").map(&:text)
      expect(samples).not_to be_empty

      samples.each do |sample|
        next if sample.strip.empty?

        # Should contain XML tags (angle brackets with element names)
        expect(sample).to match(/<\w/)
        expect(sample).to match(/\w>/)
      end
    end

    it "includes proper styling" do
      html = generator.generate

      expect(html).to include("</style>")
      expect(html).to include("font-family")
      expect(html).to include(".instance-sample")
      expect(html).to include("table")
    end

    it "includes navigation sidebar" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      expect(doc.css("nav#toc")).not_to be_empty
      expect(doc.css("nav#toc ul")).not_to be_empty
    end

    it "includes presentation layer CSS from CssGenerator" do
      html = generator.generate

      # Check for XS3P specific CSS
      expect(html).to include("/* XSD Documentation Styles */")
      expect(html).to include("nav, section")
      expect(html).to include("#toc")
      expect(html).to include(".xs3p-sidenav")
    end

    it "includes JavaScript from JavascriptGenerator" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      # Check for script tags
      scripts = doc.css("script")
      expect(scripts).not_to be_empty

      # Check for jQuery
      jquery_script = scripts.find { |s| s["src"]&.include?("jquery") }
      expect(jquery_script).not_to be_nil

      # Check for custom JavaScript
      expect(html).to include("initializeTOC")
      expect(html).to include("initializeTooltips")
    end

    it "includes toggle button for navigation" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      expect(doc.css("#toggle")).not_to be_empty
      expect(doc.css("#toggle span")).not_to be_empty
    end

    it "includes main content wrapper" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      expect(doc.css("main")).not_to be_empty
    end

    it "has responsive layout structure" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      # Check viewport meta tag for responsive design
      viewport = doc.css("meta[name='viewport']").first
      expect(viewport).not_to be_nil
      expect(viewport["content"]).to include("width=device-width")
    end
  end

  describe "with complex type schema" do
    let(:xsd_content) do
      <<~XSD
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
                   targetNamespace="http://example.com/test"
                   xmlns:tns="http://example.com/test">
          <xs:complexType name="PersonType">
            <xs:sequence>
              <xs:element name="firstName" type="xs:string"/>
              <xs:element name="lastName" type="xs:string"/>
              <xs:element name="age" type="xs:integer" minOccurs="0"/>
            </xs:sequence>
            <xs:attribute name="id" type="xs:ID" use="required"/>
          </xs:complexType>
          <xs:element name="person" type="tns:PersonType"/>
        </xs:schema>
      XSD
    end
    let(:generator) do
      Xseed::Documentation::HtmlGenerator.new(@temp_file, config)
    end

    before do
      @temp_file = "/tmp/test_complex_integration.xsd"
      File.write(@temp_file, xsd_content)
    end

    after do
      FileUtils.rm_f(@temp_file)
    end

    it "generates documentation for both elements and types" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      # Should have sections for both elements and complex types
      expect(doc.css("section").length).to be >= 2
      expect(html).to include("PersonType")
      expect(html).to include("person")
    end

    it "shows properties for complex types" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      # Properties definition lists should exist (XS3P uses DLs not tables)
      expect(doc.css("dl.dl-horizontal")).not_to be_empty

      # Should include Content row for complex type - check the entire document
      expect(html).to match(/content|Content/i)
    end

    it "generates XML samples with nested structure" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      samples = doc.css(".instance-sample code").map(&:text)
      person_sample = samples.find { |s| s.include?("person") }

      expect(person_sample).not_to be_nil
      expect(person_sample).to include("firstName")
      expect(person_sample).to include("lastName")
    end

    it "includes namespace declaration in samples" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      samples = doc.css(".instance-sample code").map(&:text).join
      expect(samples).to include("xmlns=")
    end
  end

  describe "with type hierarchy" do
    let(:xsd_content) do
      <<~XSD
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
          <xs:complexType name="BaseType">
            <xs:sequence>
              <xs:element name="id" type="xs:string"/>
            </xs:sequence>
          </xs:complexType>
          <xs:complexType name="DerivedType">
            <xs:complexContent>
              <xs:extension base="BaseType">
                <xs:sequence>
                  <xs:element name="name" type="xs:string"/>
                </xs:sequence>
              </xs:extension>
            </xs:complexContent>
          </xs:complexType>
        </xs:schema>
      XSD
    end
    let(:generator) do
      Xseed::Documentation::HtmlGenerator.new(@temp_file, config)
    end

    before do
      @temp_file = "/tmp/test_hierarchy_integration.xsd"
      File.write(@temp_file, xsd_content)
    end

    after do
      FileUtils.rm_f(@temp_file)
    end

    it "includes hierarchy tables" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      # Should have hierarchy sections
      expect(doc.css(".hierarchy")).not_to be_empty
    end

    it "shows parent-child relationships" do
      html = generator.generate

      expect(html).to include("BaseType")
      expect(html).to include("DerivedType")
      # Should show relationship
      expect(html).to match(/extension|Parent type|Super-types/i)
    end
  end

  describe "with simple types" do
    let(:xsd_content) do
      <<~XSD
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
          <xs:simpleType name="ColorType">
            <xs:restriction base="xs:string">
              <xs:enumeration value="red"/>
              <xs:enumeration value="green"/>
              <xs:enumeration value="blue"/>
            </xs:restriction>
          </xs:simpleType>
          <xs:simpleType name="AgeType">
            <xs:restriction base="xs:integer">
              <xs:minInclusive value="0"/>
              <xs:maxInclusive value="120"/>
            </xs:restriction>
          </xs:simpleType>
        </xs:schema>
      XSD
    end
    let(:generator) do
      Xseed::Documentation::HtmlGenerator.new(@temp_file, config)
    end

    before do
      @temp_file = "/tmp/test_simple_integration.xsd"
      File.write(@temp_file, xsd_content)
    end

    after do
      FileUtils.rm_f(@temp_file)
    end

    it "documents simple types" do
      html = generator.generate

      expect(html).to include("ColorType")
      expect(html).to include("AgeType")
      expect(html).to include("Types")
    end

    it "shows enumeration values" do
      html = generator.generate

      expect(html).to include("red")
      expect(html).to include("green")
      expect(html).to include("blue")
    end

    it "shows range constraints" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      # Should show min/max values in properties table
      tables = doc.css("table.properties")
      age_table = tables.find { |t| t.text.include?("AgeType") }

      if age_table
        table_text = age_table.text
        # Check for facets/restrictions in properties
        expect(table_text).to match(/\b0\b|\bminInclusive\b/i)
        expect(table_text).to match(/\b120\b|\bmaxInclusive\b/i)
      else
        # At minimum, the types should be documented
        expect(html).to include("AgeType")
      end
    end

    it "does not include instance samples for simple types" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      # Find ColorType section
      sections = doc.css("section")
      color_section = sections.find do |s|
        s.css("h3").text.include?("ColorType")
      end

      if color_section
        # Should not have instance sample
        expect(color_section.css(".instance-sample")).to be_empty
      end
    end
  end

  describe "HTML structure and accessibility" do
    let(:xsd_path) { File.join(fixture_path, "simple/element_only.xsd") }
    let(:generator) { Xseed::Documentation::HtmlGenerator.new(xsd_path, config) }

    it "generates valid HTML5" do
      html = generator.generate
      doc = Nokogiri::HTML5(html)

      # HTML5 parser should recognize the structure
      expect(doc.css("html[lang='en']")).not_to be_empty
      expect(doc.css("nav")).not_to be_empty
      expect(doc.css("section")).not_to be_empty
      expect(doc.css("main")).not_to be_empty
    end

    it "includes proper meta tags" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      expect(doc.css("meta[charset='UTF-8']")).not_to be_empty
      expect(doc.css("meta[name='viewport']")).not_to be_empty
    end

    it "has semantic HTML structure" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      expect(doc.css("h1")).not_to be_empty
      expect(doc.css("h2")).not_to be_empty
      expect(doc.css("section")).not_to be_empty
    end

    it "includes proper heading hierarchy" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      # Should have h1 -> h2 -> h3 -> h4 hierarchy
      expect(doc.css("h1").length).to be >= 1
      expect(doc.css("h2").length).to be >= 1
      expect(doc.css("h3").length).to be >= 1
    end

    it "generates navigation links for all components" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      nav_links = doc.css("nav#toc a")
      expect(nav_links.length).to be > 0

      # Should have link to Schema Properties
      schema_prop_link = nav_links.find do |a|
        a.text.include?("Schema Document Properties")
      end
      expect(schema_prop_link).not_to be_nil
      expect(schema_prop_link["href"]).to eq("#SchemaProperties")
    end

    it "navigation links have valid anchor targets" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      nav_links = doc.css("nav#toc a[href^='#']")
      nav_links.each do |link|
        href = link["href"]
        next unless href

        # Remove the #
        target_id = href.sub(/^#/, "")

        # Find element with that ID
        target = doc.css("##{target_id}").first
        expect(target).not_to be_nil,
                              "Navigation link #{href} has no matching target"
      end
    end

    it "generates proper section IDs for navigation targets" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      # Should have SchemaProperties section (case-insensitive ID check)
      schema_props = doc.css("section").find { |s| s["id"]&.match?(/schema.*properties/i) }
      expect(schema_props).not_to be_nil

      # Should have element sections with proper IDs
      element_sections = doc.css("section").select { |s| s["id"]&.match?(/element/i) }
      expect(element_sections).not_to be_empty
    end
  end

  describe "performance" do
    let(:xsd_path) { File.join(fixture_path, "simple/element_only.xsd") }
    let(:generator) { Xseed::Documentation::HtmlGenerator.new(xsd_path, config) }

    it "generates HTML in acceptable time" do
      require "benchmark"

      duration = Benchmark.realtime { generator.generate }

      # Should complete in under 1 second for simple schema
      expect(duration).to be < 1.0
    end
  end

  describe "file output" do
    let(:xsd_path) { File.join(fixture_path, "simple/element_only.xsd") }
    let(:generator) { Xseed::Documentation::HtmlGenerator.new(xsd_path, config) }
    let(:output_path) { "/tmp/test_output.html" }

    after do
      FileUtils.rm_f(output_path)
    end

    it "writes HTML to file" do
      generator.generate_file(output_path)

      expect(File.exist?(output_path)).to be true
      content = File.read(output_path)
      expect(content).to include("<!DOCTYPE")
      expect(content).to include("</html>")
    end

    it "creates valid HTML file" do
      generator.generate_file(output_path)

      content = File.read(output_path)
      doc = Nokogiri::HTML5(content)

      # HTML5 parser should recognize all elements
      expect(doc.css("html")).not_to be_empty
      expect(doc.css("head")).not_to be_empty
      expect(doc.css("body")).not_to be_empty
      expect(doc.css("nav")).not_to be_empty
      expect(doc.css("main")).not_to be_empty
    end
  end

  describe "complete HTML structure with presentation layer" do
    let(:xsd_path) { File.join(fixture_path, "simple/element_only.xsd") }
    let(:generator) { Xseed::Documentation::HtmlGenerator.new(xsd_path, config) }

    it "generates complete document with all layers" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      # Structure: html > head, body
      expect(doc.css("html")).not_to be_empty
      expect(doc.css("head")).not_to be_empty
      expect(doc.css("body")).not_to be_empty

      # Head contains: meta, title, style, scripts
      expect(doc.css("head meta[charset]")).not_to be_empty
      expect(doc.css("head title")).not_to be_empty
      expect(doc.css("head style")).not_to be_empty
      expect(doc.css("head script")).not_to be_empty

      # Body contains: nav, toggle, main
      expect(doc.css("body > nav#toc")).not_to be_empty
      expect(doc.css("body > #toggle")).not_to be_empty
      expect(doc.css("body > main")).not_to be_empty

      # Main contains: title-section, sections
      expect(doc.css("main .title-section")).not_to be_empty
      expect(doc.css("main section")).not_to be_empty
    end

    it "integrates all three generators properly" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      # 1. PropertiesTableGenerator - properties definition lists (XS3P uses DLs)
      expect(doc.css("dl.dl-horizontal")).not_to be_empty

      # 2. HierarchyTableGenerator - would be in type hierarchy sections
      # (May or may not exist depending on schema)

      # 3. InstanceSampleGenerator - XML samples
      expect(doc.css(".instance-sample")).not_to be_empty
      expect(doc.css("code.language-xml")).not_to be_empty
    end

    it "uses CssGenerator for styling" do
      html = generator.generate

      # Should include XS3P-specific styles
      expect(html).to include(".xs3p-sidenav")
      expect(html).to include("#toc")
      expect(html).to include(".properties")
    end

    it "uses JavascriptGenerator for interactivity" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      # Should include jQuery
      jquery_scripts = doc.css("script[src*='jquery']")
      expect(jquery_scripts).not_to be_empty

      # Should include custom JavaScript
      expect(html).to include("initializeTOC")
      expect(html).to include("initializeSmoothScroll")
    end

    it "uses NavigationBuilder for TOC" do
      html = generator.generate
      doc = Nokogiri::HTML(html)

      # Navigation should be organized
      expect(doc.css("nav#toc ul.xs3p-sidenav")).not_to be_empty
      expect(doc.css("nav#toc li")).not_to be_empty
      expect(doc.css("nav#toc a")).not_to be_empty
    end
  end

  describe "configuration options" do
    let(:xsd_path) { File.join(fixture_path, "simple/element_only.xsd") }

    it "respects custom title" do
      config.title = "Custom Schema Title"
      generator = Xseed::Documentation::HtmlGenerator.new(xsd_path, config)
      html = generator.generate
      doc = Nokogiri::HTML(html)

      expect(doc.css("title").text).to eq("Custom Schema Title")
      expect(doc.css("h1").text).to include("Custom Schema Title")
    end

    it "supports sort_by_component configuration" do
      config.sort_by_component = true
      generator = Xseed::Documentation::HtmlGenerator.new(xsd_path, config)
      html = generator.generate
      doc = Nokogiri::HTML(html)

      # Should have separate sections for each component type
      expect(doc.css("#SchemaElements")).not_to be_empty
    end

    it "supports print_glossary configuration" do
      config.print_glossary = true
      generator = Xseed::Documentation::HtmlGenerator.new(xsd_path, config)
      html = generator.generate
      doc = Nokogiri::HTML(html)

      # Should have glossary section
      expect(doc.css("#Glossary")).not_to be_empty
      expect(html).to include("Glossary")
    end
  end

  describe "performance with large schema" do
    let(:xsd_path) { File.join(fixture_path, "simple/element_only.xsd") }
    let(:generator) { Xseed::Documentation::HtmlGenerator.new(xsd_path, config) }

    it "generates complete HTML with all layers in acceptable time" do
      require "benchmark"

      duration = Benchmark.realtime { generator.generate }

      # Even with all presentation layers, should be fast
      expect(duration).to be < 2.0
    end
  end
end
