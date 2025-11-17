# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../lib/xseed/documentation/utils/strings"

RSpec.describe Xseed::Documentation::Utils::Strings do
  describe ".escape_quotes" do
    it "escapes single quotes" do
      result = described_class.escape_quotes("it's")
      expect(result).to eq("it\\'s")
    end

    it "escapes double quotes" do
      result = described_class.escape_quotes('say "hello"')
      expect(result).to eq('say \\"hello\\"')
    end

    it "escapes both single and double quotes" do
      result = described_class.escape_quotes(%q(it's "quoted"))
      expect(result).to eq(%q(it\\'s \\"quoted\\"))
    end

    it "returns unchanged string without quotes" do
      result = described_class.escape_quotes("hello world")
      expect(result).to eq("hello world")
    end

    it "handles empty string" do
      result = described_class.escape_quotes("")
      expect(result).to eq("")
    end
  end

  describe ".repeat" do
    it "repeats content specified number of times" do
      result = described_class.repeat("x", 3)
      expect(result).to eq("xxx")
    end

    it "returns content once when count is 1" do
      result = described_class.repeat("hello", 1)
      expect(result).to eq("hello")
    end

    it "returns empty string when count is 0" do
      result = described_class.repeat("x", 0)
      expect(result).to eq("")
    end

    it "returns empty string when count is negative" do
      result = described_class.repeat("x", -1)
      expect(result).to eq("")
    end

    it "repeats multi-character content" do
      result = described_class.repeat("ab", 3)
      expect(result).to eq("ababab")
    end
  end

  describe ".translate" do
    it "replaces all occurrences of substring" do
      result = described_class.translate("hello world", "o", "0")
      expect(result).to eq("hell0 w0rld")
    end

    it "replaces substring with multi-character string" do
      result = described_class.translate("hello", "l", "LL")
      expect(result).to eq("heLLLLo")
    end

    it "replaces multi-character substring" do
      result = described_class.translate("foobar", "oo", "00")
      expect(result).to eq("f00bar")
    end

    it "returns original string when substring not found" do
      result = described_class.translate("hello", "x", "y")
      expect(result).to eq("hello")
    end

    it "handles empty replacement string" do
      result = described_class.translate("hello", "l", "")
      expect(result).to eq("heo")
    end

    it "handles empty original string" do
      result = described_class.translate("", "x", "y")
      expect(result).to eq("")
    end
  end

  describe ".normalize_whitespace" do
    it "collapses multiple spaces to single space" do
      result = described_class.normalize_whitespace("hello    world")
      expect(result).to eq("hello world")
    end

    it "trims leading and trailing whitespace" do
      result = described_class.normalize_whitespace("  hello  ")
      expect(result).to eq("hello")
    end

    it "converts tabs and newlines to spaces" do
      result = described_class.normalize_whitespace("hello\t\nworld")
      expect(result).to eq("hello world")
    end

    it "handles empty string" do
      result = described_class.normalize_whitespace("")
      expect(result).to eq("")
    end
  end

  describe ".split_whitespace" do
    it "splits string by whitespace" do
      result = described_class.split_whitespace("one two three")
      expect(result).to eq(%w[one two three])
    end

    it "handles multiple spaces" do
      result = described_class.split_whitespace("one    two")
      expect(result).to eq(%w[one two])
    end

    it "handles tabs and newlines" do
      result = described_class.split_whitespace("one\ttwo\nthree")
      expect(result).to eq(%w[one two three])
    end

    it "returns empty array for empty string" do
      result = described_class.split_whitespace("")
      expect(result).to eq([])
    end

    it "returns empty array for whitespace-only string" do
      result = described_class.split_whitespace("   ")
      expect(result).to eq([])
    end
  end
end
