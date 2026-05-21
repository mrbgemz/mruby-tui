# frozen_string_literal: true

##
# @api private
class TUI::Markdown
  class Wrap
    ##
    # @param [Hash] theme
    def initialize(theme:)
      @theme = theme
    end
    
    ##
    # @param [String] text
    # @param [Integer] width
    # @return [Array<String>]
    def plain_text(text, width)
      parts = TUI::Utils.split(text.to_s, "\n", keep_empty: true)
      lines = []
      parts.each do |paragraph|
        if paragraph.empty?
          lines << ""
        else
          plain_paragraph(paragraph, width).each do |line|
            lines << line
          end
        end
      end
      lines.empty? ? [""] : lines
    end

    ##
    # @param [Array<Hash>] segments
    # @param [Integer] width
    # @return [Array<Array<Hash>>]
    def segments(segments, width)
      lines = segment_lines(segments)
      rows = [[]]
      row_width = 0
      pending_space = nil
      lines.each_with_index do |line, index|
        if preformatted_segment_line?(line)
          append_preformatted_segment_line(rows, line, width)
        else
          row_width = 0
          pending_space = nil
          tokenize_line(line).each do |token|
            text = token[:text]
            next if text.empty?
            if whitespace?(text)
              if row_width.zero?
                row_width = append_chunks(rows, row_width, token, width)
              else
                pending_space = token
              end
              next
            end
            if pending_space && row_width.positive?
              needed = pending_space[:text].length + text.length
              if row_width + needed <= width
                row_width = append_chunks(rows, row_width, pending_space, width)
              else
                rows << []
                row_width = 0
              end
              pending_space = nil
            end
            row_width = append_chunks(rows, row_width, token, width)
          end
        end
        if index < lines.length - 1
          rows << []
          row_width = 0
          pending_space = nil
        end
      end
      rows.empty? ? [[]] : rows
    end

    ##
    # @param [String] text
    # @return [Array<String>]
    def split_lines(text)
      TUI::Utils.split(text.to_s, "\n", keep_empty: true)
    end

    ##
    # @param [Array<Hash>, nil] row
    # @return [Boolean]
    def blank_row?(row)
      row.nil? || row.empty? || row.all? { |segment| segment[:text].to_s.empty? }
    end

    ##
    # @param [String] text
    # @param [Hash, nil] values
    # @return [Hash]
    def segment(text, values = nil)
      values ||= {}
      {
        text: text,
        fg: values[:fg] || @theme[:fg],
        bg: values[:bg] || @theme[:bg],
        bold: !!values[:bold],
        italic: !!values[:italic],
        underline: !!values[:underline]
      }
    end

    ##
    # @param [Array<Hash>] row
    # @param [Hash] value
    # @return [void]
    def push_segment(row, value)
      text = value[:text].to_s
      return if text.empty?
      previous = row[-1]
      if previous && same_style?(previous, value)
        previous[:text] << text
      else
        row << segment(text, value)
      end
    end

    private

    ##
    # @api private
    # @param [String] text
    # @param [Integer] width
    # @return [Array<String>]
    def plain_paragraph(text, width)
      width = [width, 1].max
      lines = []
      line = +""
      TUI::Utils.split(text).each do |word|
        if line.empty?
          append_plain_word(lines, word, width) { |value| line = value }
        elsif line.length + 1 + word.length <= width
          line << " " << word
        else
          lines << line
          append_plain_word(lines, word, width) { |value| line = value }
        end
      end
      lines << line unless line.empty?
      lines.empty? ? [""] : lines
    end

    ##
    # @api private
    # @param [Array<String>] lines
    # @param [String] word
    # @param [Integer] width
    # @yieldparam [String] value
    # @return [void]
    def append_plain_word(lines, word, width)
      if word.length <= width
        yield(word)
        return
      end
      chunks = chunk_text(word, width)
      chunks[0...-1].each { |chunk| lines << chunk }
      yield(chunks[-1] || "")
    end

    ##
    # @api private
    # @param [String] text
    # @param [Integer] width
    # @return [Array<String>]
    def chunk_text(text, width)
      width = [width, 1].max
      chunks = []
      remaining = text.to_s
      while remaining.length > width
        chunks << remaining[0, width]
        remaining = remaining[width..] || ""
      end
      chunks << remaining
      chunks
    end

    ##
    # @api private
    # @param [Array<Hash>] segments
    # @return [Array<Array<Hash>>]
    def segment_lines(segments)
      lines = [[]]
      segments.each do |segment|
        parts = TUI::Utils.split(segment[:text], "\n", keep_empty: true)
        parts.each_with_index do |part, index|
          value = segment.dup
          value[:text] = part
          lines[-1] << value
          lines << [] if index < parts.length - 1
        end
      end
      lines
    end

    ##
    # @api private
    # @param [Array<Hash>] segments
    # @return [Array<Hash>]
    def tokenize_line(segments)
      tokens = []
      segments.each do |segment|
        append_text_tokens(tokens, segment, segment[:text])
      end
      tokens
    end

    ##
    # @api private
    # @param [Array<Hash>] segments
    # @return [Boolean]
    def preformatted_segment_line?(segments)
      text = line_text(segments)
      text.start_with?(" ", "\t", "|", ">")
    end

    ##
    # @api private
    # @param [Array<Hash>] segments
    # @return [String]
    def line_text(segments)
      text = +""
      segments.each { |segment| text << segment[:text].to_s }
      text
    end

    ##
    # @api private
    # @param [Array<Array<Hash>>] rows
    # @param [Array<Hash>] segments
    # @param [Integer] width
    # @return [void]
    def append_preformatted_segment_line(rows, segments, width)
      current = []
      current_width = 0
      segments.each do |segment|
        remaining = segment[:text].to_s
        while remaining.length > 0
          available = width - current_width
          if available <= 0
            rows << current
            current = []
            current_width = 0
            available = width
          end
          chunk = remaining[0, available]
          push_segment(current, segment.merge(text: chunk))
          current_width += chunk.length
          remaining = remaining[chunk.length..] || ""
          if remaining.length > 0
            rows << current
            current = []
            current_width = 0
          end
        end
      end
      rows[-1] = current
    end

    ##
    # @api private
    # @param [Array<Hash>] tokens
    # @param [Hash] segment
    # @param [String] text
    # @return [void]
    def append_text_tokens(tokens, segment, text)
      text.scan(/[^\s]+|[\s]+/).each do |part|
        tokens << segment.merge(text: part)
      end
    end

    ##
    # @api private
    # @param [String] text
    # @return [Boolean]
    def whitespace?(text)
      text.strip.empty?
    end

    ##
    # @api private
    # @param [Array<Array<Hash>>] rows
    # @param [Integer] row_width
    # @param [Hash] token
    # @param [Integer] width
    # @return [Integer]
    def append_chunks(rows, row_width, token, width)
      remaining = token[:text]
      current_width = row_width
      while remaining.length > 0
        available = width - current_width
        if available <= 0
          rows << []
          current_width = 0
          available = width
        end
        chunk = remaining[0, available]
        push_segment(rows[-1], token.merge(text: chunk))
        current_width += chunk.length
        remaining = remaining[chunk.length..] || ""
        if remaining.length > 0
          rows << []
          current_width = 0
        end
      end
      current_width
    end

    ##
    # @api private
    # @param [Hash] left
    # @param [Hash] right
    # @return [Boolean]
    def same_style?(left, right)
      left[:fg] == (right[:fg] || @theme[:fg]) &&
        left[:bg] == (right[:bg] || @theme[:bg]) &&
        left[:bold] == !!right[:bold] &&
        left[:italic] == !!right[:italic] &&
        left[:underline] == !!right[:underline]
    end
  end
end
