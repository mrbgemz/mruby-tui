# frozen_string_literal: true

##
# @api private
class TUI::Markdown
  class Renderer
    ##
    # @param [Hash] ast
    # @param [Integer] width
    # @param [Hash] theme
    def initialize(ast:, width:, theme:)
      @ast = ast
      @width = width
      @theme = theme
      @inline = TUI::Markdown::Inline.new(theme:)
      @wrap = TUI::Markdown::Wrap.new(theme:)
    end
    
    ##
    # @return [Array<Array<Hash>>]
    def rows
      root_children = @inline.children_of(@ast)
      return [[]] if root_children.empty?
      rows = render_blocks(root_children, @width)
      rows.empty? ? [[]] : rows
    end

    private

    ##
    # @api private
    # @param [Array<Hash>] nodes
    # @param [Integer] width
    # @return [Array<Array<Hash>>]
    def render_blocks(nodes, width)
      rows = []
      nodes.each do |node|
        block_rows = render_block(node, width)
        next if block_rows.empty?
        rows << [] unless rows.empty? || @wrap.blank_row?(rows[-1])
        rows.concat(block_rows)
      end
      rows
    end

    ##
    # @api private
    # @param [Hash] node
    # @param [Integer] width
    # @return [Array<Array<Hash>>]
    def render_block(node, width)
      return [] if node.nil? || width <= 0
      case @inline.node_type(node)
      when :paragraph
        @wrap.segments(@inline.segments(@inline.children_of(node)), width)
      when :heading
        style = @inline.merge_style(@inline.base_style, fg: @theme[:heading_fg], bold: true)
        @wrap.segments(@inline.segments(@inline.children_of(node), style), width)
      when :quote
        prefix_block(render_blocks(@inline.children_of(node), [width - 2, 1].max), "> ", "> ", @theme[:quote_fg])
      when :code_block
        render_code_block(node, width)
      when :hr
        [[@wrap.segment("-" * width, fg: @theme[:rule_fg], bg: @theme[:bg])]]
      when :ul
        render_list(node, width, false)
      when :ol
        render_list(node, width, true)
      when :table
        TUI::Markdown::Table.new(node:, width:, theme: @theme, inline: @inline, wrap: @wrap).rows
      else
        children = @inline.children_of(node)
        return @wrap.segments(@inline.segments(children), width) if @inline.inline_container?(node)
        render_blocks(children, width)
      end
    end

    ##
    # @api private
    # @param [Hash] node
    # @param [Integer] width
    # @return [Array<Array<Hash>>]
    def render_code_block(node, width)
      lines = @wrap.split_lines(@inline.plain_text(node))
      lines = [""] if lines.empty?
      rows = []
      lines.each do |line|
        chunk_text(line, width).each do |chunk|
          rows << [@wrap.segment(chunk, fg: @theme[:code_fg], bg: @theme[:code_bg])]
        end
      end
      rows
    end

    ##
    # @api private
    # @param [Hash] node
    # @param [Integer] width
    # @param [Boolean] ordered
    # @return [Array<Array<Hash>>]
    def render_list(node, width, ordered)
      rows = []
      items = @inline.children_of(node)
      items.each_with_index do |item, index|
        marker = ordered ? "#{index + 1}. " : "- "
        item_rows = render_blocks(@inline.children_of(item), [width - marker.length, 1].max)
        item_rows = [[]] if item_rows.empty?
        rows.concat(prefix_block(item_rows, marker, " " * marker.length, @theme[:fg]))
      end
      rows
    end

    ##
    # @api private
    # @param [String] text
    # @param [Integer] width
    # @return [Array<String>]
    def chunk_text(text, width)
      width = [width, 1].max
      chunks = []
      remaining = text.to_s
      while remaining.length > width
        chunks << remaining[0, width]
        remaining = remaining[width..] || ""
      end
      chunks << remaining
      chunks
    end

    ##
    # @api private
    # @param [Array<Array<Hash>>] rows
    # @param [String] first_prefix
    # @param [String] rest_prefix
    # @param [Integer, Symbol] fg
    # @return [Array<Array<Hash>>]
    def prefix_block(rows, first_prefix, rest_prefix, fg)
      prefixed = []
      rows.each_with_index do |row, index|
        prefix = index.zero? ? first_prefix : rest_prefix
        segments = []
        @wrap.push_segment(segments, text: prefix, fg:, bg: @theme[:bg], bold: false, italic: false, underline: false)
        row.each do |segment|
          @wrap.push_segment(segments, segment)
        end
        prefixed << segments
      end
      prefixed
    end
  end
end
