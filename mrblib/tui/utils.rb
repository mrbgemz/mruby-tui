# frozen_string_literal: true

module TUI
  ##
  # Small utility helpers used by mruby-tui.
  module Utils
    ##
    # Split a string using a plain-string separator or
    # ASCII whitespace.
    #
    # This avoids relying on {String#split} features
    # that are not consistently available across mruby
    # builds.
    #
    # @param [String] text
    # @param [String, nil] separator
    #  When +nil+, split on runs of ASCII whitespace.
    # @param [Boolean] keep_empty
    #  When true, preserve empty fields between
    #  separators and at the end of the string.
    # @return [Array<String>]
    def self.split(text, separator = nil, keep_empty: false)
      text = text.to_s
      return split_whitespace(text) unless separator
      split_string(text, separator, keep_empty:)
    end

    ##
    # @api private
    def self.split_string(text, separator, keep_empty: false)
      parts = []
      start = 0
      width = separator.length
      loop do
        index = text.index(separator, start)
        break unless index
        part = text[start...index]
        parts << part if keep_empty || !part.empty?
        start = index + width
      end
      tail = text[start..] || ""
      parts << tail if keep_empty || !tail.empty?
      parts
    end

    ##
    # @api private
    def self.split_whitespace(text)
      parts = []
      token = +""
      text.each_char do |char|
        if whitespace?(char)
          unless token.empty?
            parts << token
            token = +""
          end
        else
          token << char
        end
      end
      parts << token unless token.empty?
      parts
    end

    ##
    # @api private
    def self.whitespace?(char)
      char == " " || char == "\t" || char == "\n" || char == "\r" || char == "\f" || char == "\v"
    end
  end
end
