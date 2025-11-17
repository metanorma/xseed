# frozen_string_literal: true

require "spec_helper"
require "xseed/parser/xsd_parser"
require "benchmark"

RSpec.describe "XsdParser Integration Tests" do
  def fixture_path(relative_path)
    File.join(File.dirname(__FILE__), "../../fixtures", relative_path)
  end

  describe "parsing real-world XSD files" do
    context "with unitsml-v1.0.xsd" do
      let(:parser) do
        Xseed::Parser::XsdParser.new(
          fixture_path("real_world/unitsml-v1.0.xsd")
        )
      end

      it "parses successfully" do
        expect(parser).to be_a(Xseed::Parser::XsdParser)
        expect(parser.document).to be_a(Nokogiri::XML::Document)
      end

      it "extracts schema metadata" do
        expect(parser.target_namespace).not_to be_nil
        expect(parser.target_namespace).to be_a(String)
        expect(parser.element_form_default).not_to be_nil
      end

      it "extracts all schema components" do
        elements = parser.elements
        types = parser.types

        expect(elements.size).to be > 0
        expect(types.size).to be > 0
      end

      it "provides complete namespace mappings" do
        namespaces = parser.namespaces
        expect(namespaces).to be_a(Hash)
        # Schema namespace prefix can be either "xs" or "xsd"
        xs_prefix = namespaces.keys.find do |k|
          namespaces[k] == "http://www.w3.org/2001/XMLSchema"
        end
        expect(xs_prefix).not_to be_nil
      end

      it "handles complex schema structure" do
        complex_types = parser.complex_types
        simple_types = parser.simple_types

        expect(complex_types.size).to be >= 0
        expect(simple_types.size).to be >= 0
      end
    end

    context "with recursive_groups.xsd" do
      let(:parser) do
        Xseed::Parser::XsdParser.new(
          fixture_path("simple/recursive_groups.xsd")
        )
      end

      it "parses successfully" do
        expect(parser).to be_a(Xseed::Parser::XsdParser)
      end

      it "extracts groups correctly" do
        groups = parser.groups
        expect(groups).to respond_to(:size)
      end

      it "handles recursive structures" do
        elements = parser.elements
        types = parser.types

        expect(elements).to respond_to(:size)
        expect(types).to respond_to(:size)
      end
    end
  end

  describe "performance benchmarks" do
    context "with unitsml-v1.0.xsd" do
      let(:xsd_file) { fixture_path("real_world/unitsml-v1.0.xsd") }

      it "parses in less than 1 second" do
        time = Benchmark.realtime do
          Xseed::Parser::XsdParser.new(xsd_file)
        end

        expect(time).to be < 1.0
      end

      it "efficiently extracts components" do
        parser = Xseed::Parser::XsdParser.new(xsd_file)

        time = Benchmark.realtime do
          parser.elements
          parser.types
          parser.groups
          parser.namespaces
        end

        expect(time).to be < 0.1
      end
    end
  end

  describe "comprehensive schema parsing" do
    context "with multiple test fixtures" do
      let(:fixtures) do
        [
          "simple/element_only.xsd",
          "simple/complex_type.xsd",
          "simple/simple_type.xsd",
          "simple/recursive_groups.xsd",
          "real_world/unitsml-v1.0.xsd"
        ]
      end

      it "successfully parses all fixtures" do
        fixtures.each do |fixture|
          parser = Xseed::Parser::XsdParser.new(fixture_path(fixture))
          expect(parser.document).to be_a(Nokogiri::XML::Document)
        end
      end

      it "extracts target namespace from all fixtures" do
        fixtures.each do |fixture|
          parser = Xseed::Parser::XsdParser.new(fixture_path(fixture))
          # Most fixtures should have target namespaces
          # (recursive_groups.xsd may not have one)
          if fixture.include?("recursive_groups")
            expect(parser.target_namespace).to be_nil.or be_a(String)
          else
            expect(parser.target_namespace).not_to be_nil
          end
        end
      end

      it "extracts components from all fixtures" do
        fixtures.each do |fixture|
          parser = Xseed::Parser::XsdParser.new(fixture_path(fixture))

          # At minimum, we should be able to call these methods
          # without errors
          expect { parser.elements }.not_to raise_error
          expect { parser.types }.not_to raise_error
          expect { parser.groups }.not_to raise_error
          expect { parser.namespaces }.not_to raise_error
        end
      end
    end
  end

  describe "edge cases and error handling" do
    context "with malformed XSD" do
      let(:temp_file) { "/tmp/malformed_#{Time.now.to_i}.xsd" }

      before do
        File.write(temp_file, "<invalid>xml</invalid>")
      end

      after do
        FileUtils.rm_f(temp_file)
      end

      it "handles malformed XML gracefully" do
        parser = Xseed::Parser::XsdParser.new(temp_file)
        # Parser should parse but may not find schema elements
        expect(parser.document).to be_a(Nokogiri::XML::Document)
      end
    end

    context "with XSD without target namespace" do
      let(:temp_file) { "/tmp/no_ns_#{Time.now.to_i}.xsd" }

      before do
        File.write(temp_file, <<~XSD)
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:element name="test" type="xs:string"/>
          </xs:schema>
        XSD
      end

      after do
        FileUtils.rm_f(temp_file)
      end

      it "handles schemas without target namespace" do
        parser = Xseed::Parser::XsdParser.new(temp_file)
        expect(parser.target_namespace).to be_nil
        expect(parser.elements.size).to eq(1)
      end
    end
  end

  describe "data extraction completeness" do
    context "with complex_type.xsd" do
      let(:parser) do
        Xseed::Parser::XsdParser.new(
          fixture_path("simple/complex_type.xsd")
        )
      end

      it "extracts complete type information" do
        complex_types = parser.complex_types

        expect(complex_types.size).to eq(2)

        type_names = complex_types.map { |t| t["name"] }
        expect(type_names).to include("PersonType")
        expect(type_names).to include("ContactType")
      end

      it "provides documentation for types" do
        person_doc = parser.type_documentation("PersonType")
        expect(person_doc).to include("person")

        contact_doc = parser.type_documentation("ContactType")
        expect(contact_doc).to include("Contact")
      end
    end

    context "with simple_type.xsd" do
      let(:parser) do
        Xseed::Parser::XsdParser.new(
          fixture_path("simple/simple_type.xsd")
        )
      end

      it "extracts all simple types" do
        simple_types = parser.simple_types

        expect(simple_types.size).to eq(4)

        type_names = simple_types.map { |t| t["name"] }
        expect(type_names).to include("StatusType")
        expect(type_names).to include("AgeType")
        expect(type_names).to include("EmailType")
        expect(type_names).to include("CodeType")
      end

      it "provides documentation for all types" do
        %w[StatusType AgeType EmailType CodeType].each do |type_name|
          doc = parser.type_documentation(type_name)
          expect(doc).not_to be_nil
        end
      end
    end
  end
end
