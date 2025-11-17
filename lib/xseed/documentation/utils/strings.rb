# frozen_string_literal: true

module Xseed
  module Documentation
    module Utils
      # String manipulation utilities
      # Ported from xs3p utils/strings.xsl
      module Strings
        # Translates occurrences of single and double quotes with escape
        # characters
        #
        # @param text [String] Text to translate
        # @return [String] Text with escaped quotes
        def self.escape_quotes(text)
          return text if text.nil? || text.empty?

          # Escape single quotes
          result = text.gsub("'", "\\\\'")
          # Escape double quotes
          result.gsub('"', '\\\\"')
        end

        # Repeatedly output content
        #
        # @param content [String] The content to be output
        # @param count [Integer] Number of times to output the content
        # @return [String] Repeated content
        def self.repeat(content, count)
          return "" if count <= 0

          content * count
        end

        # Translates occurrences of a string in a piece of text with another
        # string
        #
        # @param value [String] Text to translate
        # @param str_to_replace [String] String to be replaced
        # @param replacement_str [String] Replacement text
        # @return [String] Translated text
        def self.translate(value, str_to_replace, replacement_str)
          return value if value.nil? || value.empty?
          return value unless value.include?(str_to_replace)

          value.gsub(str_to_replace, replacement_str)
        end

        # Normalizes whitespace in a string by:
        # - Converting tabs and newlines to spaces
        # - Collapsing multiple spaces to single space
        # - Trimming leading and trailing whitespace
        #
        # @param text [String] Text to normalize
        # @return [String] Normalized text
        def self.normalize_whitespace(text)
          return "" if text.nil? || text.empty?

          text.gsub(/[\t\n\r]+/, " ")
              .gsub(/\s+/, " ")
              .strip
        end

        # Splits a string by whitespace into an array
        #
        # @param text [String] Text to split
        # @return [Array<String>] Array of tokens
        def self.split_whitespace(text)
          return [] if text.nil? || text.empty?

          normalize_whitespace(text).split
        end
      end
    end
  end
end
