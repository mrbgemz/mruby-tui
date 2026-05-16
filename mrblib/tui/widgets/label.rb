# frozen_string_literal: true

module TUI
  ##
  # {TUI::Label} renders a single styled line of text.
  #
  # The content is left padded by one space and clipped
  # to the available width.
  class Label < Widget
    ##
    # @param [String] text
    # @param [Integer] fg foreground color
    # @param [Integer] bg background color
    # @param [Boolean] bold whether to apply {TUI::Attr::BOLD}
    # @param (see TUI::Widget#initialize)
    def initialize(text, fg: Color::WHITE, bg: Color::DEFAULT, bold: false, **kw)
      super(**kw)
      @text = text
      @fg = fg
      @bg = bg
      @bold = bold
    end

    ##
    # Render the label content.
    #
    # @return [void]
    def render
      return if rw <= 0 || rh <= 0
      style = @bold ? @fg | Attr::BOLD : @fg
      line = " #{@text}".ljust(rw)[0, rw]
      TUI.print(ax, ay, style, @bg, line)
      super
    end
  end
end
