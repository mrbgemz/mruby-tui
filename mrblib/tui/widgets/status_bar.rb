# frozen_string_literal: true

module TUI
  ##
  # {TUI::StatusBar} renders a one-line status bar.
  #
  # It can display left- and right-aligned text in a
  # single row, which is useful for mode, connection,
  # model, and prompt hints in REPL-style interfaces.
  class StatusBar < Widget
    attr_accessor :left, :right

    ##
    # @param [String] left
    # @param [String] right
    # @param [Integer, Symbol] fg foreground color
    # @param [Integer, Symbol] bg background color
    # @param [Boolean] bold whether to apply {TUI::Attr::BOLD}
    # @param (see TUI::Widget#initialize)
    def initialize(left = "", right: "", fg: :white, bg: :blue, bold: false, **kw)
      super(height: 1, **kw)
      @left = left
      @right = right
      @fg = fg
      @bg = bg
      @bold = bold
    end

    ##
    # Render the full-width status bar.
    #
    # @return [void]
    def render
      return if rw <= 0 || rh <= 0
      style = @bold ? TUI.color(@fg) | Attr::BOLD : @fg
      line = " #{@left}".ljust(rw)
      if !@right.empty? && @right.length < rw
        start = rw - @right.length - 1
        line[start, @right.length + 1] = " #{@right}"
      end
      TUI.print(ax, ay, style, @bg, line[0, rw])
      super
    end
  end
end
