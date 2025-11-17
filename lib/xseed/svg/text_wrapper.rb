# frozen_string_literal: true

module Xseed
  module Svg
    # Utility for wrapping long text into multiple lines
    # Implements XSDVI's WordUtils.wrap functionality
    class TextWrapper
      # Maximum line width in characters
      MAX_LINE_WIDTH = 80

      # Wraps text to fit within specified width
      # @param text [String] Text to wrap
      # @param width [Integer] Maximum width in characters
      # @return [Array<String>] Array of wrapped lines
      def self.wrap(text, width = MAX_LINE_WIDTH)
        return [] if text.nil? || text.empty?

        # Remove excessive whitespace
        text = text.strip.gsub(/\s+/, " ")

        words = text.split(/\s+/)
        lines = []
        current_line = []
        current_length = 0

        words.each do |word|
          word_length = word.length

          # Check if adding this word would exceed width
          if current_length + word_length + 1 > width
            # Start new line if current line has content
            lines << current_line.join(" ") unless current_line.empty?
            current_line = [word]
            current_length = word_length
          else
            # Add word to current line
            current_line << word
            # Account for space between words (except for first word)
            current_length += word_length + (current_line.size > 1 ? 1 : 0)
          end
        end

        # Add remaining line
        lines << current_line.join(" ") unless current_line.empty?

        lines
      end

      # Wraps text and returns as a single string with newlines
      # @param text [String] Text to wrap
      # @param width [Integer] Maximum width in characters
      # @return [String] Wrapped text with newlines
      def self.wrap_string(text, width = MAX_LINE_WIDTH)
        wrap(text, width).join("\n")
      end
    end
  end
end