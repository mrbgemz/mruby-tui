# frozen_string_literal: true

module TUI
  ##
  # {TUI::Fill} paints every cell in its rectangle.
  #
  # This is useful for backgrounds, separators, and
  # simple framed regions.
  class Fill < Widget
    ##
    # @param [Integer] ch Unicode codepoint to paint
    # @param [Integer] fg foreground color
    # @param [Integer] bg background color
    # @param (see TUI::Widget#initialize)
    def initialize(ch: 0x20, fg: Color::WHITE, bg: Color::BLUE, **kw)
      super(**kw)
      @ch = ch
      @fg = fg
      @bg = bg
    end

    ##
    # Paint the widget's full area.
    #
    # @return [void]
    def render
      return if rw <= 0 || rh <= 0
      rh.times do |dy|
        rw.times do |dx|
          TUI.set_cell(ax + dx, ay + dy, @ch, @fg, @bg)
        end
      end
      super
    end
  end
end
