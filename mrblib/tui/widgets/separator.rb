# frozen_string_literal: true

module TUI
  ##
  # {TUI::Separator} draws a thin horizontal line
  # across its full width.
  #
  # Useful for dividing sections without the visual
  # weight of a full {Frame}.
  #
  # @example
  #   TUI::Separator.new  # single ── line
  #   TUI::Separator.new(ch: " ", bg: :blue)  # subtle tint bar
  class Separator < Widget
    ##
    # @param [Integer, String] ch  The line character or codepoint (default U+2500)
    # @param [Integer, Symbol] fg  Foreground colour
    # @param [Integer, Symbol] bg  Background colour
    # @param [Hash] kw  Remaining keyword args for {Widget#initialize}
    def initialize(ch: 0x2500, fg: :white, bg: :default, **kw)
      super(height: 1, **kw)
      @ch = ch
      @fg = fg
      @bg = bg
    end

    ##
    # Draw the separator line.
    # @return [void]
    def render
      return if rw <= 0 || rh <= 0
      ch = Integer === @ch ? @ch : @ch.ord
      rw.times do |dx|
        TUI.set_cell(ax + dx, ay, ch, @fg, @bg)
      end
      super
    end
  end
end
