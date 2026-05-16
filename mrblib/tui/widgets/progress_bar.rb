# frozen_string_literal: true

module TUI
  ##
  # {TUI::ProgressBar} draws a progress bar across its
  # full width.
  #
  # @example
  #   bar = TUI::ProgressBar.new
  #   bar.value = 60
  #   bar.max   = 100
  #
  #   bar.ratio = 0.6         # same thing
  class ProgressBar < Widget
    ##
    # @return [Integer] current value
    attr_accessor :value

    ##
    # @return [Integer] maximum value
    attr_accessor :max

    ##
    # @return [String, nil] optional status text rendered at the right edge
    attr_accessor :text

    ##
    # @param [Integer] value  Current value (default 0)
    # @param [Integer] max  Maximum value (default 100)
    # @param [Integer, Symbol] fill_fg  Filled bar colour
    # @param [Integer, Symbol] empty_fg  Empty bar colour
    # @param [String] fill_ch  Filled character (default █)
    # @param [String] empty_ch  Empty character (default ░)
    # @param [Boolean] show_pct  Show percentage text (default true)
    # @param [String, nil] text  Optional right-aligned text
    # @param [Hash] kw  Remaining keyword args for {Widget#initialize}
    def initialize(value: 0, max: 100,
                   fill_fg: :green, empty_fg: :white,
                   fill_ch: "█", empty_ch: "░",
                   show_pct: true,
                   text: nil,
                   **kw)
      super(height: 1, **kw)
      @value = value
      @max = max
      @fill_fg = fill_fg
      @empty_fg = empty_fg
      @fill_ch = fill_ch
      @empty_ch = empty_ch
      @show_pct = show_pct
      @text = text
    end

    ##
    # Set progress as a ratio 0.0–1.0.
    # @param [Float] ratio
    def ratio=(ratio)
      @value = (ratio * @max).round
    end

    ##
    # @return [Float] current ratio 0.0–1.0
    def ratio
      return 0.0 if @max <= 0
      [[@value.to_f / @max, 0.0].max, 1.0].min
    end

    ##
    # Draw the progress bar.
    # @return [void]
    def render
      return if rw <= 0 || rh <= 0
      filled = (ratio * rw).round
      filled = 1 if @value.to_i.positive? && filled.zero?
      filled = rw if filled > rw
      pct = (ratio * 100).round
      empty = rw - filled
      bar_fg = pct >= 90 ? :red : pct >= 75 ? :yellow : @fill_fg
      TUI.print(ax, ay, bar_fg, :default, @fill_ch * filled) if filled.positive?
      TUI.print(ax + filled, ay, @empty_fg, :default, @empty_ch * empty) if empty.positive?
      overlay = suffix_text
      unless overlay.empty?
        overlay = overlay[-rw, rw] if overlay.length > rw
        ox = ax + [(rw - overlay.length) / 2, 0].max
        TUI.print(ox, ay, :white, :default, overlay)
      end
      super
    end

    private

    def suffix_text
      return " #{@text}" if @text && !@text.empty?
      return sprintf(" %3d%%", (ratio * 100).round) if @show_pct
      ""
    end
  end
end
