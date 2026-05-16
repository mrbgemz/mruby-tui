# frozen_string_literal: true

module TUI
  ##
  # {TUI::Input} is a prompt-style text input widget.
  #
  # It stores text internally and renders it with a
  # leading +>+ prompt on a single line. When the widget
  # height is larger than one line, +valign+ controls
  # the vertical placement.
  class Input < Widget
    attr_reader :text

    ##
    # @param [String] prompt
    # @param [Integer, Symbol] fg
    # @param [Integer, Symbol] bg
    # @param [Integer, Symbol] prompt_fg
    # @param [:top, :middle, :bottom] valign
    # @param (see TUI::Widget#initialize)
    def initialize(prompt: "> ", fg: :white, bg: :black, prompt_fg: nil,
                   valign: :top, **kw)
      super(**kw)
      @text = ""
      @prompt = prompt
      @fg = fg
      @bg = bg
      @prompt_fg = prompt_fg || fg
      @valign = valign
    end

    ##
    # Paint the input background, prompt, and cursor.
    # @return [void]
    def render
      return if rw <= 0 || rh <= 0
      dy = valign_offset
      rh.times do |row|
        rw.times do |dx|
          TUI.set_cell(ax + dx, ay + row, 0x20, @fg, @bg)
        end
      end
      TUI.print(ax, ay + dy, TUI.color(@prompt_fg) | Attr::BOLD, @bg, "#{@prompt}#{@text}")
      TUI.set_cursor(ax + @prompt.length + @text.length, ay + dy)
      super
    end

    ##
    # Append a character to the buffer.
    # @param [String] ch
    # @return [String]
    def put(ch)
      @text << ch
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

    def valign_offset
      case @valign
      when :middle then [rh / 2, 0].max
      when :bottom then [rh - 1, 0].max
      else 0
      end
    end
  end
end
