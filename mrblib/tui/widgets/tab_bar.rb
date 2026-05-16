# frozen_string_literal: true

module TUI
  ##
  # {TUI::TabBar} renders a horizontal tab bar with the
  # active tab highlighted.
  #
  # Useful for switching between views in a panel-based
  # layout. Connect it to a {TUI::TabPanel} for the
  # content switching.
  class TabBar < Widget
    attr_accessor :active, :tabs

    ##
    # @param [Array<String>] tabs  Tab labels.
    # @param [Integer] active      Initial active tab index.
    # @param [Integer, Symbol] fg  Tab foreground colour.
    # @param [Integer, Symbol] bg  Tab background colour.
    # @param [Integer, Symbol] active_fg  Active tab foreground.
    # @param [Integer, Symbol] active_bg  Active tab background.
    # @param (see TUI::Widget#initialize)
    def initialize(tabs = [], active: 0, fg: :white, bg: :default,
                   active_fg: :white, active_bg: :cyan, **kw)
      super(height: 1, **kw)
      @tabs = tabs
      @active = active
      @fg = fg
      @bg = bg
      @active_fg = active_fg
      @active_bg = active_bg
    end

    ##
    # Render tabs left-to-right. Active tab is highlighted.
    # @return [void]
    def render
      return if rw <= 0 || rh <= 0
      rw.times { |dx| TUI.set_cell(ax + dx, ay, 0x20, @fg, @bg) }
      x = ax
      @tabs.each_with_index do |tab, i|
        fg = TUI.color(i == @active ? @active_fg : @fg)
        bg = TUI.color(i == @active ? @active_bg : @bg)
        text = i == @active ? " [#{tab}] " : " #{tab}  "
        TUI.print(x, ay, fg | TUI::Attr::BOLD, bg, text)
        x += text.length
        break if x >= ax + rw
      end
      super
    end
  end
end
