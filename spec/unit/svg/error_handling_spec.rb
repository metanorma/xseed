# frozen_string_literal: true

require "spec_helper"

RSpec.describe "SVG Generation Error Handling" do
  let(:fixtures_path) { File.expand_path("../../fixtures", __dir__) }
  let(:temp_dir) { File.expand_path("../../../tmp/error_tests", __dir__) }

  before(:all) do
    FileUtils.mkdir_p(File.expand_path("../../../tmp/error_tests", __dir__))
  end

  after(:all) do
    FileUtils.rm_rf(File.expand_path("../../../tmp/error_tests", __dir__))
  end

  describe Xseed::Svg::SvgGenerator do
    describe "initialization errors" do
      it "raises ArgumentError for non-existent file" do
        expect do
          described_class.new("/nonexistent/file.xsd")
        end.to raise_error(ArgumentError, /File not found/)
      end

      it "raises ArgumentError for non-XSD file" do
        temp_file = File.join(temp_dir, "test.xml")
        File.write(temp_file, "<root/>")

        expect do
          described_class.new(temp_file)
        end.to raise_error(ArgumentError, /must be an XSD file/)
      end

      it "raises ArgumentError for invalid XML" do
        temp_file = File.join(temp_dir, "invalid.xsd")
        File.write(temp_file, "<schema>unclosed tag")

        expect do
          described_class.new(temp_file)
        end.to raise_error(ArgumentError, /Invalid XSD file/)
      end

      it "raises ArgumentError for XML without schema root" do
        temp_file = File.join(temp_dir, "no_schema.xsd")
        File.write(temp_file, '<?xml version="1.0"?><root></root>')

        expect do
          described_class.new(temp_file)
        end.to raise_error(ArgumentError, /root element must be 'schema'/)
      end
    end

    describe "empty schema handling" do
      it "generates SVG for empty schema with placeholder" do
        temp_file = File.join(temp_dir, "empty.xsd")
        File.write(temp_file, <<~XSD)
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
          </xs:schema>
        XSD

        generator = described_class.new(temp_file)
        svg = generator.generate

        expect(svg).to include("Empty Schema")
        expect(svg).to include("<svg")
        expect(svg).to include("</svg>")
      end

      it "handles schema with only imports/includes" do
        temp_file = File.join(temp_dir, "imports_only.xsd")
        File.write(temp_file, <<~XSD)
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:import namespace="http://example.com" schemaLocation="other.xsd"/>
          </xs:schema>
        XSD

        generator = described_class.new(temp_file)
        svg = generator.generate

        expect(svg).to be_a(String)
        expect(svg).to include("<svg")
      end
    end

    describe "malformed XSD handling" do
      it "handles missing required attributes gracefully" do
        temp_file = File.join(temp_dir, "missing_attrs.xsd")
        File.write(temp_file, <<~XSD)
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:element/>
          </xs:schema>
        XSD

        generator = described_class.new(temp_file)
        svg = generator.generate

        expect(svg).to be_a(String)
        expect(svg).to include("<svg")
      end

      it "handles elements without types" do
        temp_file = File.join(temp_dir, "no_type.xsd")
        File.write(temp_file, <<~XSD)
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:element name="testElement"/>
          </xs:schema>
        XSD

        generator = described_class.new(temp_file)
        svg = generator.generate

        expect(svg).to include("testElement")
        expect(svg).to include("<svg")
      end
    end

    describe "file writing errors" do
      it "creates output directory if it doesn't exist" do
        output_path = File.join(temp_dir, "nested", "deep", "output.svg")
        xsd_file = File.join(fixtures_path, "simple", "element_only.xsd")

        generator = described_class.new(xsd_file)
        result = generator.generate_file(output_path)

        expect(result).to eq(output_path)
        expect(File.exist?(output_path)).to be true
      end

      it "overwrites existing file" do
        output_path = File.join(temp_dir, "existing.svg")
        File.write(output_path, "old content")

        xsd_file = File.join(fixtures_path, "simple", "element_only.xsd")
        generator = described_class.new(xsd_file)
        generator.generate_file(output_path)

        content = File.read(output_path)
        expect(content).not_to eq("old content")
        expect(content).to include("<svg")
      end
    end

    describe "complex schema edge cases" do
      it "handles deeply nested structures" do
        temp_file = File.join(temp_dir, "deep_nesting.xsd")
        File.write(temp_file, <<~XSD)
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:element name="rootElement">
              <xs:complexType>
                <xs:sequence>
                  <xs:element name="level1Element">
                    <xs:complexType>
                      <xs:sequence>
                        <xs:element name="level2Element">
                          <xs:complexType>
                            <xs:sequence>
                              <xs:element name="level3Element" type="xs:string"/>
                            </xs:sequence>
                          </xs:complexType>
                        </xs:element>
                      </xs:sequence>
                    </xs:complexType>
                  </xs:element>
                </xs:sequence>
              </xs:complexType>
            </xs:element>
          </xs:schema>
        XSD

        generator = described_class.new(temp_file)
        svg = generator.generate

        expect(svg).to include("rootElement")
        expect(svg).to include("sequence")
        expect(svg).to include("<svg")
      end

      it "handles schemas with many elements" do
        elements = (1..100).map do |i|
          %(<xs:element name="element#{i}" type="xs:string"/>)
        end.join("\n")

        temp_file = File.join(temp_dir, "many_elements.xsd")
        File.write(temp_file, <<~XSD)
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            #{elements}
          </xs:schema>
        XSD

        generator = described_class.new(temp_file)

        expect do
          svg = generator.generate
          expect(svg).to include("<svg")
        end.not_to raise_error
      end
    end
  end

  describe Xseed::Parser::XsdParser do
    describe "parser error handling" do
      it "raises error for non-existent file" do
        expect do
          described_class.new("/nonexistent/file.xsd")
        end.to raise_error(Errno::ENOENT)
      end

      it "handles corrupted XML" do
        temp_file = File.join(temp_dir, "corrupted.xsd")
        File.write(temp_file, "not xml at all")

        expect do
          described_class.new(temp_file)
        end.to raise_error(Xseed::ParserError, /Invalid XML syntax/)
      end

      it "handles schema without target namespace" do
        temp_file = File.join(temp_dir, "no_namespace.xsd")
        File.write(temp_file, <<~XSD)
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:element name="test" type="xs:string"/>
          </xs:schema>
        XSD

        parser = described_class.new(temp_file)
        expect(parser.target_namespace).to be_nil
        expect(parser.elements).not_to be_empty
      end
    end

    describe "documentation extraction" do
      it "handles missing documentation gracefully" do
        temp_file = File.join(temp_dir, "no_docs.xsd")
        File.write(temp_file, <<~XSD)
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:element name="test" type="xs:string"/>
          </xs:schema>
        XSD

        parser = described_class.new(temp_file)
        expect(parser.documentation).to be_nil
        expect(parser.element_documentation("test")).to be_nil
      end

      it "extracts documentation when present" do
        temp_file = File.join(temp_dir, "with_docs.xsd")
        File.write(temp_file, <<~XSD)
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:annotation>
              <xs:documentation>Schema documentation</xs:documentation>
            </xs:annotation>
            <xs:element name="test" type="xs:string">
              <xs:annotation>
                <xs:documentation>Element documentation</xs:documentation>
              </xs:annotation>
            </xs:element>
          </xs:schema>
        XSD

        parser = described_class.new(temp_file)
        expect(parser.documentation).to eq("Schema documentation")
        expect(parser.element_documentation("test")).to eq("Element documentation")
      end
    end
  end

  describe "graceful degradation" do
    it "continues processing when encountering invalid elements" do
      temp_file = File.join(temp_dir, "mixed_valid_invalid.xsd")
      File.write(temp_file, <<~XSD)
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
          <xs:element name="validElement1" type="xs:string"/>
          <xs:element/>
          <xs:element name="validElement2" type="xs:integer"/>
        </xs:schema>
      XSD

      generator = Xseed::Svg::SvgGenerator.new(temp_file)
      svg = generator.generate

      expect(svg).to include("validElement1")
      expect(svg).to include("validElement2")
    end

    it "generates output even when schema has warnings" do
      temp_file = File.join(temp_dir, "with_warnings.xsd")
      File.write(temp_file, <<~XSD)
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
          <xs:element name="testElement" type="NonExistentType"/>
        </xs:schema>
      XSD

      generator = Xseed::Svg::SvgGenerator.new(temp_file)
      svg = generator.generate

      expect(svg).to include("<svg")
      expect(svg).to include("testElement")
    end
  end
end
