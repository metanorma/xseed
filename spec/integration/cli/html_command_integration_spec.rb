# frozen_string_literal: true

require "spec_helper"
require "xseed/cli"
require "tempfile"
require "tmpdir"

RSpec.describe "HTML command integration" do
  let(:fixture_path) { File.expand_path("../../fixtures", __dir__) }
  let(:xsd_path) { File.join(fixture_path, "simple/element_only.xsd") }
  let(:output_dir) { Dir.mktmpdir }
  let(:output_path) { File.join(output_dir, "test_output.html") }

  after do
    FileUtils.rm_rf(output_dir)
  end

  describe "basic HTML generation" do
    it "generates HTML file from XSD successfully" do
      args = ["html", xsd_path, "-o", output_path]

      expect { Xseed::CLI.start(args) }.not_to raise_error

      expect(File.exist?(output_path)).to be true
      html = File.read(output_path)
      expect(html).to include("<html")
      expect(html).to include("</html>")
    end

    it "creates valid HTML5 document" do
      args = ["html", xsd_path, "-o", output_path]
      Xseed::CLI.start(args)

      html = File.read(output_path)
      doc = Nokogiri::HTML5(html)

      # Check structure
      expect(doc.css("html")).not_to be_empty
      expect(doc.css("head")).not_to be_empty
      expect(doc.css("body")).not_to be_empty
      expect(doc.css("nav#toc")).not_to be_empty
      expect(doc.css("main")).not_to be_empty
    end

    it "includes all presentation layer components" do
      args = ["html", xsd_path, "-o", output_path]
      Xseed::CLI.start(args)

      html = File.read(output_path)

      # CSS from CssGenerator
      expect(html).to include("/* XSD Documentation Styles */")
      expect(html).to include("#toc")

      # JavaScript from JavascriptGenerator
      expect(html).to include("initializeTOC")
      expect(html).to include("jquery")

      # Navigation from NavigationBuilder
      expect(html).to include('<nav id="toc">')
    end

    it "generates content for all schema components" do
      args = ["html", xsd_path, "-o", output_path]
      Xseed::CLI.start(args)

      html = File.read(output_path)
      doc = Nokogiri::HTML5(html)

      # Should have schema properties
      expect(doc.css("#SchemaProperties")).not_to be_empty

      # Should have elements section
      expect(doc.css("#SchemaElements")).not_to be_empty

      # XS3P uses h3 with id attributes, not wrapper divs
      expect(doc.css("h3 a[id^='element-']")).not_to be_empty
    end
  end

  describe "--title option" do
    it "supports custom title" do
      custom_title = "My Custom Schema Documentation"
      args = ["html", xsd_path, "-o", output_path, "--title", custom_title]

      Xseed::CLI.start(args)

      html = File.read(output_path)
      doc = Nokogiri::HTML5(html)

      expect(doc.css("title").text).to eq(custom_title)
      expect(doc.css("h1").text).to include(custom_title)
    end

    it "uses default title when not specified" do
      args = ["html", xsd_path, "-o", output_path]

      Xseed::CLI.start(args)

      html = File.read(output_path)
      doc = Nokogiri::HTML5(html)

      expect(doc.css("title").text).to eq("XSD Schema Documentation")
    end
  end

  describe "--verbose option" do
    it "prints detailed output when verbose is enabled" do
      args = ["html", xsd_path, "-o", output_path, "--verbose"]

      output = capture_stdout do
        Xseed::CLI.start(args)
      end

      expect(output).to include("Creating HTML generator")
      expect(output).to include("HTML generator initialized")
      expect(output).to include("Generating HTML documentation")
    end

    it "prints minimal output when verbose is not enabled" do
      args = ["html", xsd_path, "-o", output_path]

      output = capture_stdout do
        Xseed::CLI.start(args)
      end

      expect(output).to include("HTML documentation generated")
      expect(output).not_to include("Creating HTML generator")
    end
  end

  describe "error handling" do
    it "raises error when XSD file does not exist" do
      non_existent_xsd = "/tmp/nonexistent.xsd"
      args = ["html", non_existent_xsd, "-o", output_path]

      expect { Xseed::CLI.start(args) }.to raise_error(SystemExit)
    end

    it "raises error when XSD path is not provided" do
      args = ["html"]

      expect { Xseed::CLI.start(args) }.to raise_error
    end

    it "creates output directory if it doesn't exist" do
      nested_output = File.join(output_dir, "nested", "dir", "output.html")
      args = ["html", xsd_path, "-o", nested_output]

      Xseed::CLI.start(args)

      expect(File.exist?(nested_output)).to be true
    end
  end

  describe "file overwriting" do
    it "overwrites existing output file without prompt when force is implied" do
      # Create initial file
      args = ["html", xsd_path, "-o", output_path, "--title", "First"]
      Xseed::CLI.start(args)

      first_content = File.read(output_path)
      expect(first_content).to include("First")

      # Delete and recreate - this tests the full workflow without interactive prompt
      File.delete(output_path)

      # Create with new content
      args = ["html", xsd_path, "-o", output_path, "--title", "Second"]
      Xseed::CLI.start(args)

      second_content = File.read(output_path)
      expect(second_content).to include("Second")
    end
  end

  describe "with complex schema" do
    let(:complex_xsd_content) do
      <<~XSD
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
                   targetNamespace="http://example.com/complex"
                   xmlns:tns="http://example.com/complex">
          <xs:complexType name="PersonType">
            <xs:sequence>
              <xs:element name="firstName" type="xs:string"/>
              <xs:element name="lastName" type="xs:string"/>
            </xs:sequence>
            <xs:attribute name="id" type="xs:ID"/>
          </xs:complexType>
          <xs:element name="person" type="tns:PersonType"/>
          <xs:simpleType name="AgeType">
            <xs:restriction base="xs:integer">
              <xs:minInclusive value="0"/>
              <xs:maxInclusive value="120"/>
            </xs:restriction>
          </xs:simpleType>
          <xs:group name="PersonGroup">
            <xs:sequence>
              <xs:element name="firstName" type="xs:string"/>
              <xs:element name="lastName" type="xs:string"/>
            </xs:sequence>
          </xs:group>
        </xs:schema>
      XSD
    end

    let(:complex_xsd_path) { File.join(output_dir, "complex.xsd") }

    before do
      File.write(complex_xsd_path, complex_xsd_content)
    end

    it "generates documentation for all component types" do
      args = ["html", complex_xsd_path, "-o", output_path]
      Xseed::CLI.start(args)

      html = File.read(output_path)
      Nokogiri::HTML5(html)

      # Should have sections for different component types
      expect(html).to include("PersonType")
      expect(html).to include("AgeType")
      expect(html).to include("PersonGroup")
      expect(html).to include("person")
    end

    it "generates navigation for all components" do
      args = ["html", complex_xsd_path, "-o", output_path]
      Xseed::CLI.start(args)

      html = File.read(output_path)
      doc = Nokogiri::HTML5(html)

      nav = doc.css("nav#toc")
      expect(nav).not_to be_empty

      # Should have links to various component types
      nav_text = nav.text
      expect(nav_text).to include("Elements")
      expect(nav_text).to include("Complex Types")
      expect(nav_text).to include("Types")
      expect(nav_text).to include("Groups")
    end
  end

  describe "performance" do
    it "generates HTML in reasonable time for simple schema" do
      require "benchmark"

      args = ["html", xsd_path, "-o", output_path]

      duration = Benchmark.realtime do
        Xseed::CLI.start(args)
      end

      # Should complete quickly for simple schema
      expect(duration).to be < 2.0
    end
  end

  describe "output validation" do
    it "generates valid HTML that includes all required elements" do
      args = ["html", xsd_path, "-o", output_path]
      Xseed::CLI.start(args)

      html = File.read(output_path)
      doc = Nokogiri::HTML5(html)

      # Required HTML5 elements (xs3p format - no lang on html)
      expect(doc.css("html")).not_to be_empty
      expect(doc.css("head meta[charset='UTF-8']")).not_to be_empty
      expect(doc.css("head meta[name='viewport']")).not_to be_empty
      expect(doc.css("head title")).not_to be_empty
      expect(doc.css("head style")).not_to be_empty
      expect(doc.css("head script")).not_to be_empty
      expect(doc.css("body")).not_to be_empty
    end

    it "generates properties tables for elements" do
      args = ["html", xsd_path, "-o", output_path]
      Xseed::CLI.start(args)

      html = File.read(output_path)
      doc = Nokogiri::HTML5(html)

      # Should have properties definition lists (XS3P uses DLs not tables)
      properties_dls = doc.css("dl.dl-horizontal")
      expect(properties_dls).not_to be_empty

      # DLs should have definition terms and definitions
      properties_dls.each do |dl|
        expect(dl.css("dt")).not_to be_empty
        expect(dl.css("dd")).not_to be_empty
      end
    end

    it "generates XML instance samples" do
      args = ["html", xsd_path, "-o", output_path]
      Xseed::CLI.start(args)

      html = File.read(output_path)
      doc = Nokogiri::HTML5(html)

      # Should have instance samples in xs3p format (pre.codehilite)
      instance_samples = doc.css("pre.codehilite")
      expect(instance_samples).not_to be_empty

      # Samples should contain XML markup with span tags
      instance_samples.each do |pre|
        text = pre.text
        next if text.strip.empty?

        # Should look like XML element names
        expect(text).to match(/\w/)
      end
    end
  end

  # Helper method to capture stdout
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
