# frozen_string_literal: true

module TUI
  ##
  # {TUI::Markdown} renders a markdown AST into a scrollable terminal view.
  #
  # The widget expects the AST shape produced by mruby-markdown. Layout is
  # resolved at render time using the current widget width.
  class Markdown < TUI::Widget
    ##
    # @return [Hash, nil] current markdown AST
    attr_reader :ast
    ##
    # @param [Hash] ast markdown AST from mruby-markdown
    # @param [Integer, Symbol] fg default foreground colour
    # @param [Integer, Symbol] bg default background colour
    # @param [Integer, Symbol] heading_fg heading foreground colour
    # @param [Integer, Symbol] code_fg code foreground colour
    # @param [Integer, Symbol] code_bg code background colour
    # @param [Integer, Symbol] link_fg link foreground colour
    # @param [Integer, Symbol] quote_fg quote prefix colour
    # @param [Integer, Symbol] rule_fg horizontal rule colour
    # @param [Integer, nil] max_width optional content width clamp
    # @param (see TUI::Widget#initialize)
    def initialize(ast:, fg: :white, bg: :default,
                  heading_fg: :cyan, code_fg: :yellow, code_bg: :default,
                  link_fg: :blue, quote_fg: :green, rule_fg: :white,
                  max_width: nil, **kw)
      super(**kw)
      @ast = ast
      @theme = {
        fg: fg,
        bg: bg,
        heading_fg: heading_fg,
        code_fg: code_fg,
        code_bg: code_bg,
        link_fg: link_fg,
        quote_fg: quote_fg,
        rule_fg: rule_fg
      }
      @max_width = max_width
      @scroll = 0
      @rows_cache = nil
      @rows_cache_width = nil
      @rows_cache_ast = nil
    end

    ##
    # Replace the rendered AST and reset scroll/layout caches.
    #
    # @param [Hash] ast markdown AST from mruby-markdown
    # @return [void]
    def ast=(ast)
      @ast = ast
      @rows_cache = nil
      @rows_cache_width = nil
      @rows_cache_ast = nil
      @scroll = 0
    end

    ##
    # Scroll upward by one rendered row.
    #
    # @return [void]
    def scroll_up
      max_r = total_rows
      body = rh
      @scroll = [@scroll + 1, max_r - body].min if max_r > body
    end

    ##
    # Scroll downward by one rendered row.
    #
    # @return [void]
    def scroll_down
      @scroll = [@scroll - 1, 0].max
    end

    ##
    # Render the visible portion of the markdown document.
    #
    # @return [void]
    def render
      return if rw <= 0 || rh <= 0
      paint_background
      rows = rendered_rows
      start = [rows.length - rh - @scroll, 0].max
      visible = rows[start, rh] || []
      visible.each_with_index do |row, dy|
        render_row(row, dy)
      end
      super
    end

    private

    ##
    # @api private
    # @return [Integer]
    def total_rows
      rendered_rows.length
    end

    ##
    # @api private
    # @return [Integer]
    def content_width
      width = [rw, 1].max
      @max_width ? [width, @max_width.to_i].min : width
    end

    ##
    # @api private
    # @return [Array<Array<Hash>>]
    def rendered_rows
      width = content_width
      if @rows_cache && @rows_cache_width == width && @rows_cache_ast.equal?(@ast)
        return @rows_cache
      end
      rows = TUI::Markdown::Renderer.new(ast: @ast, width:, theme: @theme).rows
      @rows_cache = rows
      @rows_cache_width = width
      @rows_cache_ast = @ast
      rows
    end

    ##
    # @api private
    # @return [void]
    def paint_background
      blank = " " * rw
      rh.times do |dy|
        TUI.print(ax, ay + dy, @theme[:fg], @theme[:bg], blank)
      end
    end

    ##
    # @api private
    # @param [Array<Hash>] row
    # @param [Integer] dy
    # @return [void]
    def render_row(row, dy)
      x = ax
      row.each do |segment|
        if segment[:hr]
          x += hr(segment, x, ay, dy)
        else
          text = segment[:text].to_s
          next if text.empty?
          TUI.print(x, ay + dy, segment_fg(segment), segment[:bg] || @theme[:bg], text)
          x += text.length
        end
      end
    end

    ##
    # @api private
    # @param [Hash] segment
    # @return [Integer]
    def segment_fg(segment)
      fg = TUI.color(segment[:fg] || @theme[:fg])
      fg |= TUI::Attr::BOLD if segment[:bold]
      fg |= TUI::Attr::ITALIC if segment[:italic]
      fg |= TUI::Attr::UNDERLINE if segment[:underline]
      fg
    end

    ##
    # @api private
    # @return [Integer]
    def hr(segment, x, ay, dy)
      TUI.hline(
        x,
        ay + dy,
        segment[:width].to_i,
        segment[:ch] || 0x2500,
        fg: segment_fg(segment),
        bg: segment[:bg] || @theme[:bg]
      )
      segment[:width].to_i
    end
  end
end
