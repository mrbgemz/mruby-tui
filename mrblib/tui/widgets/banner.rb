# frozen_string_literal: true

module TUI
  ##
  # {TUI::Banner} renders multi-line ASCII art with
  # configurable alignment and colour.
  #
  # The banner treats each input line as a fixed row and
  # preserves spacing exactly.  It clips to the available
  # width and height without reflowing or word-wrapping,
  # making it a good fit for logos, headers, and decorative
  # separators.
  #
  # @example A centred banner
  #   art = <<~ART
  #     ____  _   _
  #    / ___|| | | |
  #    \\___ \\| |_| |
  #     ___) |  _  |
  #    |____/|_| |_|
  #   ART
  #   root.add TUI::Banner.new(art, fg: :cyan, align: :center)
  class Banner < Widget
    ##
    # @param [String, Array<String>] art
    #  Multi-line ASCII art. A String is split on newlines.
    #  An Array is used as-is; each element is one row.
    # @param [Integer, Symbol] fg
    #  Foreground colour (default +:white+).
    # @param [Integer, Symbol] bg
    #  Background colour (default +:default+).
    # @param [:left, :center, :right] align
    #  Horizontal alignment within the widget bounds
    #  (default +:center+).
    # @param [:top, :middle, :bottom] valign
    #  Vertical alignment within the widget bounds
    #  (default +:top+).
    # @param [Hash] kw
    #  Remaining keyword args forwarded to {Widget#initialize}.
    #  If +height+ is not given it is derived from the art.
    def initialize(art, fg: :white, bg: :default,
                   align: :center, valign: :top, **kw)
      @lines = art.is_a?(String) ? art.each_line.map(&:chomp) : art.dup
      kw[:height] = @lines.size unless kw.key?(:height)
      super(**kw)
      @fg = fg
      @bg = bg
      @align = align
      @valign = valign
    end

    ##
    # Render the banner.
    #
    # @return [void]
    def render
      return if rw <= 0 || rh <= 0
      avail_w = rw
      avail_h = rh
      art_h = @lines.size
      dy = case @valign
           when :middle then [(avail_h - art_h) / 2, 0].max
           when :bottom then [avail_h - art_h, 0].max
           else 0
           end
      visible_lines = @lines[0, avail_h - dy]
      visible_lines.each_with_index do |line, idx|
        row = ay + dy + idx
        break if row >= ay + avail_h
        line = line[0, avail_w] if line.length > avail_w
        dx = case @align
             when :center then [(avail_w - line.length) / 2, 0].max
             when :right  then [avail_w - line.length, 0].max
             else 0
             end
        TUI.print(ax + dx, row, @fg, @bg, line)
      end
      super
    end
  end
end
