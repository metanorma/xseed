# frozen_string_literal: true

require "spec_helper"
require "xseed/svg/text_wrapper"

RSpec.describe Xseed::Svg::TextWrapper do
  describe ".wrap" do
    context "with nil text" do
      it "returns empty array" do
        expect(described_class.wrap(nil)).to eq([])
      end
    end

    context "with empty text" do
      it "returns empty array" do
        expect(described_class.wrap("")).to eq([])
      end
    end

    context "with text shorter than width" do
      it "returns single line" do
        text = "This is short"
        result = described_class.wrap(text, 80)
        expect(result).to eq([text])
      end
    end

    context "with text longer than width" do
      it "wraps text into multiple lines" do
        text = "This is a very long text that should be wrapped into multiple lines when it exceeds the specified width"
        result = described_class.wrap(text, 40)
        expect(result.size).to be > 1
        result.each do |line|
          expect(line.length).to be <= 40
        end
      end

      it "preserves words (no mid-word breaks)" do
        text = "The quick brown fox jumps over the lazy dog"
        result = described_class.wrap(text, 25)
        result.each do |line|
          # Check that lines don't have trailing incomplete words
          expect(line).to match(/\A\S.*\S\z|\A\S\z/)
        end
      end
    end

    context "with text at exactly the width" do
      it "returns single line" do
        text = "a" * 80
        result = described_class.wrap(text, 80)
        expect(result).to eq([text])
      end
    end

    context "with multiple spaces" do
      it "normalizes whitespace" do
        text = "This    has    many     spaces"
        result = described_class.wrap(text, 80)
        expect(result.first).to eq("This has many spaces")
      end
    end

    context "with leading and trailing whitespace" do
      it "strips whitespace" do
        text = "  This has spaces  "
        result = described_class.wrap(text, 80)
        expect(result.first).to eq("This has spaces")
      end
    end

    context "with default width" do
      it "uses MAX_LINE_WIDTH" do
        long_text = "word " * 100 # Much longer than 80 chars
        result = described_class.wrap(long_text)
        expect(result.size).to be > 1
      end
    end

    context "with very narrow width" do
      it "handles width smaller than single word" do
        text = "verylongword short"
        result = described_class.wrap(text, 5)
        # Should still wrap at word boundaries even if word is longer
        expect(result).to include("verylongword")
        expect(result).to include("short")
      end
    end
  end

  describe ".wrap_string" do
    it "returns wrapped text with newlines" do
      text = "This is a long text that needs wrapping"
      result = described_class.wrap_string(text, 20)
      expect(result).to include("\n")
      expect(result.split("\n").size).to be > 1
    end

    it "returns single line for short text" do
      text = "Short"
      result = described_class.wrap_string(text, 80)
      expect(result).to eq(text)
      expect(result).not_to include("\n")
    end

    it "handles empty text" do
      result = described_class.wrap_string("", 80)
      expect(result).to eq("")
    end
  end

  describe "XSDVI compatibility" do
    it "handles typical XML documentation text" do
      text = "This element represents a person in the system. It includes attributes for name, age, and address."
      result = described_class.wrap(text, 80)

      expect(result).to be_an(Array)
      expect(result).not_to be_empty
      result.each do |line|
        expect(line.length).to be <= 80
      end
    end

    it "handles text with XML-like content" do
      text = "The xs:element declaration defines an element. Use minOccurs and maxOccurs for cardinality."
      result = described_class.wrap(text, 60)

      expect(result.join(" ")).to eq(text.gsub(/\s+/, " "))
    end
  end
end