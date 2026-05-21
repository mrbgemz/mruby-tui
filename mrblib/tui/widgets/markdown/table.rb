# frozen_string_literal: true

##
# @api private
class TUI::Markdown
  class Table
    ##
    # @param [Hash] node
    # @param [Integer] width
    # @param [Hash] theme
    # @param [TUI::Markdown::Inline] inline
    # @param [TUI::Markdown::Wrap] wrap
    def initialize(node:, width:, theme:, inline:, wrap:)
      @node = node
      @width = width
      @theme = theme
      @inline = inline
      @wrap = wrap
    end
    
    ##
    # @return [Array<Array<Hash>>]
    def rows
      sections = @inline.children_of(@node)
      headers = []
      rows = []
      sections.each do |section|
        section_rows = @inline.children_of(section)
        next if section_rows.empty?
        if @inline.node_type(section) == :thead
          headers = table_row_cells(section_rows[0])
        else
          section_rows.each do |row|
            rows << table_row_cells(row)
          end
        end
      end
      headers = default_headers(0, @node[:n_cols] || 0) if headers.empty? && !rows.empty?
      if table_grid_fit?(headers, rows, @width)
        render_table_grid(headers, rows, @width)
      else
        render_table_stacked(headers, rows, @width)
      end
    end

    private

    ##
    # @api private
    # @param [Hash] row
    # @return [Array<String>]
    def table_row_cells(row)
      @inline.children_of(row).map { |cell| @inline.plain_text(cell).strip }
    end

    ##
    # @api private
    # @param [Integer] start
    # @param [Integer] count
    # @return [Array<String>]
    def default_headers(start, count)
      headers = []
      count.to_i.times do |index|
        headers << "Col #{start + index + 1}"
      end
      headers
    end

    ##
    # @api private
    # @param [Array<String>] headers
    # @param [Array<Array<String>>] rows
    # @param [Integer] width
    # @return [Boolean]
    def table_grid_fit?(headers, rows, width)
      count = [headers.length, rows.map(&:length).max || 0].max
      return false if count <= 0
      width >= (count * 4) + 1
    end

    ##
    # @api private
    # @param [Array<String>] headers
    # @param [Array<Array<String>>] rows
    # @param [Integer] width
    # @return [Array<Array<Hash>>]
    def render_table_grid(headers, rows, width)
      count = [headers.length, rows.map(&:length).max || 0].max
      return [[]] if count <= 0
      desired = Array.new(count, 1)
      headers.each_with_index do |value, index|
        desired[index] = [desired[index], value.to_s.length].max
      end
      rows.each do |row|
        row.each_with_index do |value, index|
          desired[index] = [desired[index], value.to_s.length].max
        end
      end
      frame_width = (count * 3) + 1
      available = [width - frame_width, count].max
      widths = Array.new(count, 1)
      remaining = available - count
      while remaining > 0
        changed = false
        count.times do |index|
          next unless widths[index] < desired[index]
          widths[index] += 1
          remaining -= 1
          changed = true
          break if remaining <= 0
        end
        break unless changed
      end
      lines = []
      unless headers.empty?
        lines.concat(render_table_grid_row(headers, widths, true))
        lines << [@wrap.segment(table_rule(widths), fg: @theme[:rule_fg], bg: @theme[:bg])]
      end
      rows.each do |row|
        lines.concat(render_table_grid_row(row, widths, false))
      end
      lines
    end

    ##
    # @api private
    # @param [Array<String>] values
    # @param [Array<Integer>] widths
    # @param [Boolean] header
    # @return [Array<Array<Hash>>]
    def render_table_grid_row(values, widths, header)
      cell_lines = []
      max_lines = 1
      widths.each_with_index do |cell_width, index|
        wrapped = @wrap.plain_text(values[index].to_s, cell_width)
        wrapped = [""] if wrapped.empty?
        cell_lines << wrapped
        max_lines = [max_lines, wrapped.length].max
      end
      rows = []
      max_lines.times do |line_index|
        text = +"| "
        widths.each_with_index do |cell_width, index|
          value = cell_lines[index][line_index] || ""
          text << value.ljust(cell_width)
          text << (index == widths.length - 1 ? " |" : " | ")
        end
        style = header ? {fg: @theme[:heading_fg], bg: @theme[:bg], bold: true} : {fg: @theme[:fg], bg: @theme[:bg]}
        rows << [@wrap.segment(text, style)]
      end
      rows
    end

    ##
    # @api private
    # @param [Array<Integer>] widths
    # @return [String]
    def table_rule(widths)
      line = +"|"
      widths.each do |cell_width|
        line << ("-" * (cell_width + 2))
        line << "|"
      end
      line
    end

    ##
    # @api private
    # @param [Array<String>] headers
    # @param [Array<Array<String>>] rows
    # @param [Integer] width
    # @return [Array<Array<Hash>>]
    def render_table_stacked(headers, rows, width)
      labels = headers.dup
      count = rows.map(&:length).max || labels.length
      if labels.length < count
        labels.concat(default_headers(labels.length, count - labels.length))
      end
      lines = []
      rows.each_with_index do |row, row_index|
        labels.each_with_index do |label, column_index|
          value = row[column_index].to_s
          prefix = "#{label}: "
          wrapped = @wrap.plain_text(value, [width - prefix.length, 1].max)
          wrapped = [""] if wrapped.empty?
          wrapped.each_with_index do |chunk, chunk_index|
            current_prefix = chunk_index.zero? ? prefix : (" " * prefix.length)
            lines << [@wrap.segment(current_prefix + chunk, fg: chunk_index.zero? ? @theme[:heading_fg] : @theme[:fg],
                                    bg: @theme[:bg], bold: chunk_index.zero?)]
          end
        end
        lines << [] if row_index < rows.length - 1
      end
      lines.empty? ? [[]] : lines
    end
  end
end
