# frozen_string_literal: true

module TUI
  ##
  # {TUI::Shortcuts} renders a key-binding hint bar,
  # inspired by radicle-tui's shortcuts widget.
  #
  # Each shortcut is a `[key, action]` pair rendered as
  # `key action` across the full width, with a configurable
  # divider between entries.
  #
  # @example
  #   TUI::Shortcuts.new([
  #     ["j/k", "Navigate"],
  #     ["Enter", "Select"],
  #     ["q", "Quit"]
  #   ])
  class Shortcuts < Widget
    ##
    # @param [Array<Array(String, String)>] shortcuts
    #   Pairs of `[key_combo, description]`.
    # @param [String] divider
    #   Character placed between entries (default "·").
    # @param [Boolean] bold_keys
    # @param [Integer, Symbol] key_fg
    # @param [Integer, Symbol] action_fg
    # @param [Integer, Symbol] divider_fg
    # @param [Integer, Symbol] bg
    # @param [Boolean] right_align
    # @param [Hash] kw  Passed to {Widget#initialize}
    def initialize(shortcuts,
                   divider: "·",
                   bold_keys: true,
                   key_fg: :yellow, action_fg: :white,
                   divider_fg: :default, bg: :default,
                   right_align: false, **kw)
      super(height: 1, **kw)
      @shortcuts = shortcuts
      @divider = divider
      @bold_keys = bold_keys
      @key_fg = key_fg
      @action_fg = action_fg
      @divider_fg = divider_fg
      @bg = bg
      @right_align = right_align
    end

    ##
    # Draw the shortcut bar.
    # @return [void]
    def render
      return if rw <= 0 || rh <= 0
      parts = []
      @shortcuts.each do |(key, action)|
        parts << { key:, action: }
      end
      if @right_align
        render_right_aligned(parts, TUI.color(@bg))
      else
        render_left_aligned(parts, TUI.color(@bg))
      end
      super
    end

    private

    def render_left_aligned(parts, bg_c)
      x = ax
      y = ay
      len = parts.length
      parts.each_with_index do |part, idx|
        key_fg = TUI.color(@key_fg)
        key_fg = key_fg | Attr::BOLD if @bold_keys
        TUI.print(x, y, key_fg, bg_c, part[:key])
        x += part[:key].length
        TUI.print(x, y, TUI.color(@action_fg), bg_c, " #{part[:action]}")
        x += part[:action].length + 1
        if idx < len - 1
          TUI.print(x, y, TUI.color(@divider_fg), bg_c, " #{@divider} ")
          x += @divider.length + 2
        end
        break if x >= ax + rw
      end
      # Clear remainder
      if x < ax + rw
        TUI.print(x, y, TUI.color(@action_fg), bg_c, " " * (ax + rw - x))
      end
    end

    def render_right_aligned(parts, bg_c)
      total = parts.sum do |p|
        p[:key].length + p[:action].length + 3
      end
      total -= 1  # last divider
      total = [total, 0].max
      x = ax + [rw - total, 0].max
      y = ay
      parts.each_with_index do |part, idx|
        break if x >= ax + rw
        key_fg = TUI.color(@key_fg)
        key_fg = key_fg | Attr::BOLD if @bold_keys
        TUI.print(x, y, key_fg, bg_c, part[:key])
        x += part[:key].length
        TUI.print(x, y, TUI.color(@action_fg), bg_c, " #{part[:action]}")
        x += part[:action].length + 1
        if idx < parts.length - 1
          TUI.print(x, y, TUI.color(@divider_fg), bg_c, " #{@divider} ")
          x += @divider.length + 2
        end
      end
    end
  end
end
