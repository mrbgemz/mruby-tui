# frozen_string_literal: true

module TUI
  ##
  # {TUI::Table} is a selectable, scrollable table widget
  # inspired by radicle-tui's table widget.
  #
  # Columns are defined with a header text and width constraint.
  # Rows are rendered from an array of items via a block that
  # returns an array of cell strings for each item.
  #
  # Keyboard navigation follows vim-style bindings with arrows,
  # page up/down, home, and end.
  #
  # @example
  #   table = TUI::Table.new(
  #     columns: [
  #       { header: "ID",    width: 6  },
  #       { header: "Name",  width: 20 },
  #       { header: "Score", width: 10 }
  #     ],
  #     items: (1..50).to_a,
  #     selected: nil
  #   ) do |item|
  #     [item.to_s, "Item #{item}", (item * 10).to_s]
  #   end
  class Table < Widget
    ##
    # @return [Integer, nil] currently selected index
    attr_reader :selected

    ##
    # @param [Array<Hash>] columns
    #   Each column has `:header` (String) and `:width` (Integer).
    # @param [Array] items
    #   The data rows. Yields each item to the block.
    # @param [Integer, nil] selected
    #   Initial selection index.
    # @param [Integer, Symbol] header_fg
    # @param [Integer, Symbol] row_fg
    # @param [Integer, Symbol] selected_fg
    # @param [Integer, Symbol] bg
    # @param [Boolean] show_scrollbar
    # @param [String, nil] empty_message
    #   Shown centered when the table has no items.
    # @param [Hash] kw  Passed to {Widget#initialize}
    def initialize(columns:, items:, selected: nil,
                   header_fg: :cyan, row_fg: :white,
                   selected_fg: :white, bg: :default,
                   show_scrollbar: true,
                   empty_message: nil, **kw)
      super(**kw)
      @columns = columns
      @items = items
      @selected = selected
      @scroll = 0
      @header_fg = header_fg
      @row_fg = row_fg
      @selected_fg = selected_fg
      @bg = bg
      @show_scrollbar = show_scrollbar
      @empty_message = empty_message
      @row_block = nil
    end

    ##
    # Provide a block that maps an item to an array of cell strings.
    # The block is called once per visible row during rendering.
    def rows(&block)
      @row_block = block
      self
    end

    ##
    # Replace the item list and reset selection.
    # @param [Array] items
    # @return [void]
    def items=(items)
      @items = items
      @selected = nil
      @scroll = 0
    end

    ##
    # Navigate the table based on a key event.
    # Returns +true+ if the selection changed.
    #
    # Supported keys:
    #   Up/k, Down/j, PageUp, PageDown, Home, End
    #
    # @param [Integer] key  A +TUI::Key+ constant value
    # @return [Boolean] whether the selection moved
    def navigate(key)
      return false if @items.empty?
      len = @items.length
      page = visible_rows
      old = @selected
      case key
      when Key::UP, Key::CTRL_K
        return false if @selected.nil? || @selected <= 0
        @selected -= 1
      when Key::CTRL_P
        return false if @selected.nil? || @selected <= 0
        @selected -= 1
      when Key::DOWN, Key::CTRL_J
        if @selected.nil?
          @selected = 0
        else
          return false if @selected >= len - 1
          @selected += 1
        end
      when Key::CTRL_N
        if @selected.nil?
          @selected = 0
        else
          return false if @selected >= len - 1
          @selected += 1
        end
      when Key::PGUP
        return false if @selected.nil? || @selected <= 0
        @selected = [@selected - page, 0].max
      when Key::PGDN
        if @selected.nil?
          @selected = 0
        else
          @selected = [@selected + page, len - 1].min
        end
      when Key::HOME
        return false if @selected.nil? || @selected <= 0
        @selected = 0
      when Key::END_
        return false if @selected == len - 1
        @selected = len - 1
      else
        return false
      end
      clamp_scroll
      @selected != old
    end

    ##
    # Draw the table.
    # @return [void]
    def render
      return if rw <= 0 || rh <= 0
      if @items.empty?
        render_empty
        super
        return
      end
      render_header
      render_rows
      super
    end

    private

    def visible_rows
      h = rh - 1  # reserve one row for header
      h = 1 if h < 1
      h
    end

    def clamp_scroll
      return unless @selected
      page = visible_rows
      if @selected < @scroll
        @scroll = @selected
      elsif @selected >= @scroll + page
        @scroll = @selected - page + 1
      end
      max_scroll = [@items.length - page, 0].max
      @scroll = max_scroll if @scroll > max_scroll
      @scroll = 0 if @scroll < 0
    end

    def render_header
      x = ax
      y = ay
      total_w = column_widths.sum + @columns.length - 1
      margin = [rw - total_w, 0].max
      x += margin / 2
      fg = TUI.color(@header_fg) | Attr::BOLD
      bg = TUI.color(@bg)
      @columns.each_with_index do |col, idx|
        w = col[:width]
        header = col[:header]
        TUI.print(x, y, fg, bg, header.to_s.ljust(w))
        if idx < @columns.length - 1
          TUI.set_cell(x + w, y, 0x20, fg, bg)
        end
        x += w + 1
      end
    end

    def render_rows
      return unless @row_block
      page = visible_rows
      x_start = ax
      y_start = ay + 1
      total_w = column_widths.sum + @columns.length - 1
      margin = [rw - total_w, 0].max
      x_start += margin / 2
      bg = TUI.color(@bg)
      @items.each_with_index do |item, idx|
        row_y = y_start + idx - @scroll
        break if row_y >= ay + rh
        next if row_y < ay
        cells = @row_block.call(item)
        is_selected = idx == @selected
        x = x_start
        cells.each_with_index do |cell, ci|
          break unless @columns[ci]
          w = @columns[ci][:width]
          text = cell.to_s
          if is_selected
            fg = TUI.color(@selected_fg) | Attr::REVERSE
            display = text.ljust(w)
            TUI.print(x, row_y, fg, bg, display)
          else
            fg = TUI.color(@row_fg)
            display = text.ljust(w)
            TUI.print(x, row_y, fg, bg, display)
          end
          x += w + 1
        end
        # Clear remainder of selected row
        if is_selected
          right_edge = x_start + total_w + (@columns.length - 1)
          if right_edge < ax + rw
            TUI.print(right_edge, row_y, TUI.color(@selected_fg) | Attr::REVERSE, bg,
                      " " * (ax + rw - right_edge))
          end
        end
      end
      render_scrollbar(y_start, page) if @show_scrollbar
    end

    def render_scrollbar(y_start, page)
      return if @items.length <= page
      thumb = "┃"
      track_h = rh - 1
      thumb_pos = if @items.length > page
                    ((@scroll.to_f / (@items.length - page)) * (track_h - 1)).round
                  else
                    0
                  end
      thumb_pos = 0 if thumb_pos < 0
      thumb_pos = track_h - 1 if thumb_pos >= track_h
      sx = ax + rw - 1
      fg = TUI.color(:white) | Attr::DIM
      bg = TUI.color(@bg)
      track_h.times do |dy|
        ch = dy == thumb_pos ? thumb : " "
        TUI.set_cell(sx, y_start + dy, ch.ord, fg, bg)
      end
    end

    def render_empty
      return unless @empty_message
      text = @empty_message
      x = ax + [(rw - text.length) / 2, 0].max
      y = ay + [rh / 2, 0].max
      fg = TUI.color(:magenta) | Attr::DIM
      TUI.print(x, y, fg, TUI.color(@bg), text)
    end

    def column_widths
      @columns.map { |c| c[:width] }
    end
  end
end
