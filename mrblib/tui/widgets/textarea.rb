# frozen_string_literal: true

module TUI
  ##
  # {TUI::TextArea} is a multi-line text input widget.
  #
  # Text wraps automatically when a line exceeds the widget
  # width. Each line is rendered at the correct y offset,
  # and the cursor follows the end of the last line.
  class TextArea < Widget
    attr_reader :text

    ##
    # @param [String] prompt
    # @param [Integer, Symbol] fg
    # @param [Integer, Symbol] bg
    # @param (see TUI::Widget#initialize)
    def initialize(prompt: "> ", fg: :white, bg: :black, **kw)
      super(**kw)
      @text = ""
      @prompt = prompt
      @fg = fg
      @bg = bg
    end

    ##
    # Paint the input background, prompt, and cursor.
    # @return [void]
    def render
      return if rw <= 0 || rh <= 0
      fill_background
      lines = text_lines
      visible_lines = lines.last([rh, lines.length].min)
      offset = [lines.length - rh, 0].max
      visible_lines.each_with_index do |line, i|
        draw_line(line, i)
      end
      cursor_y = [visible_lines.length - 1, rh - 1].min
      last_line = visible_lines.last || ""
      cursor_x = @prompt.length + last_line.length
      TUI.set_cursor(ax + cursor_x, ay + cursor_y)
      super
    end

    ##
    # Append a character to the buffer.
    # Auto-wraps to the next line when the current line
    # exceeds the available width.
    # @param [String] ch
    # @return [String]
    def put(ch)
      content_width = rw - @prompt.length
      return ch if content_width <= 0
      current_line = @text.split("\n").last || ""
      if ch == "\n"
        @text << ch
      elsif current_line.length >= content_width
        @text << "\n" << ch
      else
        @text << ch
      end
      ch
    end

    ##
    # Delete the last character in the buffer.
    # @return [String]
    def backspace
      @text = @text.chop
    end

    ##
    # Clear the input buffer.
    # @return [String]
    def clear
      @text = ""
    end

    ##
    # Return a copy of the current input value.
    # @return [String]
    def value
      @text.dup
    end

    ##
    # Test whether the input buffer is empty.
    # @return [Boolean]
    def empty?
      @text.empty?
    end

    private

    def text_lines
      lines = @text.split("\n", -1)
      lines = [""] if lines.empty?
      lines
    end

    def fill_background
      rh.times do |row|
        rw.times do |dx|
          TUI.set_cell(ax + dx, ay + row, 0x20, @fg, @bg)
        end
      end
    end

    def draw_line(line, row)
      TUI.print(ax, ay + row, TUI.color(@fg) | Attr::BOLD, @bg, "#{@prompt}#{line}")
    end
  end
end
