# frozen_string_literal: true

module TUI
  ##
  # {TUI::Frame} draws a one-cell border around its
  # children.
  #
  # Child widgets are rendered inside the frame with a
  # one-cell inset on each side. This is useful for
  # framing logs, prompts, and other panes in a REPL.
  class Frame < Widget
    attr_accessor :title

    ##
    # @param [String, nil] title
    # @param [Integer, Symbol] fg border foreground color
    # @param [Integer, Symbol] bg border background color
    # @param [Integer, String] horizontal
    # @param [Integer, String] vertical
    # @param [Integer, String] top_left
    # @param [Integer, String] top_right
    # @param [Integer, String] bottom_left
    # @param [Integer, String] bottom_right
    # @param (see TUI::Widget#initialize)
    def initialize(title: nil, fg: :white, bg: :default, horizontal: 0x2500, vertical: 0x2502, top_left: 0x250C,
      top_right: 0x2510, bottom_left: 0x2514, bottom_right: 0x2518, **kw)
      super(**kw)
      @title = title
      @fg = fg
      @bg = bg
      @horizontal = horizontal
      @vertical = vertical
      @top_left = top_left
      @top_right = top_right
      @bottom_left = bottom_left
      @bottom_right = bottom_right
    end

    ##
    # Draw the frame and render children inside it.
    #
    # @return [void]
    def render
      return if rw <= 1 || rh <= 1
      draw_horizontal(ay, @top_left, @top_right)
      draw_horizontal(ay + rh - 1, @bottom_left, @bottom_right)
      draw_vertical
      render_title
      @children.each do |child|
        child.x = 1
        child.y = 1
        child.resolve!(width: [rw - 2, 0].max, height: [rh - 2, 0].max)
        child.render
      end
    end

    private

    def draw_horizontal(y, left, right)
      return if rw <= 0
      left = Integer === left ? left : left.ord
      right = Integer === right ? right : right.ord
      horizontal = Integer === @horizontal ? @horizontal : @horizontal.ord
      TUI.set_cell(ax, y, left, @fg, @bg)
      inner = [rw - 2, 0].max
      inner.times do |dx|
        TUI.set_cell(ax + dx + 1, y, horizontal, @fg, @bg)
      end
      TUI.set_cell(ax + rw - 1, y, right, @fg, @bg) if rw > 1
    end

    def draw_vertical
      return if rh <= 2
      vertical = Integer === @vertical ? @vertical : @vertical.ord
      (rh - 2).times do |dy|
        TUI.set_cell(ax, ay + dy + 1, vertical, @fg, @bg)
        TUI.set_cell(ax + rw - 1, ay + dy + 1, vertical, @fg, @bg) if rw > 1
      end
    end

    def render_title
      return unless @title
      return if rw <= 4
      text = " #{@title} "
      TUI.print(ax + 2, ay, @fg, @bg, text[0, [rw - 4, 0].max])
    end
  end
end
