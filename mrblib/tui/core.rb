# frozen_string_literal: true

module TUI
  ##
  # Block until an event arrives. Returns a
  # {Termbox2::Event} with +type+, +key+, +ch+,
  # +mod+, +w+, +h+, +x+, +y+ fields, extended
  # with {Event} for query methods.
  #
  # @return [Termbox2::Event]
  def self.poll_event
    ev = Termbox2.poll_event
    ev.extend(Event)
    ev
  end

  ##
  # @see poll_event
  def self.read_event
    poll_event
  end

  ##
  # Non-blocking event poll. Returns an event if one
  # is available within the given timeout, or nil if
  # the timeout expires.
  #
  # @param [Integer] timeout_ms
  #  Timeout in milliseconds
  # @return [Termbox2::Event, nil]
  def self.peek_event(timeout_ms = 0)
    ev = Termbox2.peek_event(timeout_ms)
    ev&.extend(Event)
  end

  ##
  # @return [Integer] the terminal width in columns
  def self.width
    Termbox2.width
  end

  ##
  # @return [Integer] the terminal height in rows
  def self.height
    Termbox2.height
  end

  ##
  # Print text at a screen position, safely clipping
  # at the terminal boundaries.
  #
  # @param [Integer] x The column
  # @param [Integer] y The row
  # @param [Integer, Symbol] fg The foreground colour or symbol key from {TUI::COLORS}
  # @param [Integer, Symbol] bg The background colour or symbol key from {TUI::COLORS}
  # @param [String] text The text to print
  #
  # @example
  #   TUI.print(0, 0, :white, :black, "status: ok")
  #
  # @return [nil]
  def self.print(x, y, fg, bg, text)
    w = TUI.width
    h = TUI.height
    return if w <= 0 || h <= 0
    return if y.negative? || y >= h || x >= w
    text = text.to_s
    if x.negative?
      offset = -x
      return if offset >= char_length(text)
      text = drop_chars(text, offset)
      x = 0
    end
    visible = w - x
    return if visible <= 0
    line = sanitize_printable(take_chars(text, visible))
    return if line.nil? || line.empty?
    fg = TUI.color(fg)
    bg = TUI.color(bg)
    begin
      Termbox2.print(x, y, fg, bg, line)
    rescue Termbox2::Error
      line = trim_invalid_suffix(line)
      return if line.nil? || line.empty?
      begin
        Termbox2.print(x, y, fg, bg, line)
      rescue Termbox2::Error
        print_fallback(x, y, fg, bg, line, visible)
      end
    end
  end

  ##
  # Set a single cell in the back buffer.
  #
  # @param [Integer] x
  # @param [Integer] y
  # @param [Integer] ch Unicode codepoint
  # @param [Integer, Symbol] fg foreground colour or symbol key from {TUI::COLORS}
  # @param [Integer, Symbol] bg background colour or symbol key from {TUI::COLORS}
  # @return [void]
  def self.set_cell(x, y, ch, fg, bg)
    return if x.negative? || y.negative?
    w = width
    h = height
    return if w <= 0 || h <= 0
    return if x >= w || y >= h
    Termbox2.set_cell(x, y, ch, color(fg), color(bg))
  end

  ##
  # Draw a horizontal line using repeated cells.
  #
  # @param [Integer] x
  # @param [Integer] y
  # @param [Integer] width
  # @param [Integer, String] ch Unicode codepoint or single-character string
  # @param [Integer, Symbol] fg foreground colour or symbol key from {TUI::COLORS}
  # @param [Integer, Symbol] bg background colour or symbol key from {TUI::COLORS}
  # @return [void]
  def self.hline(x, y, width, ch = 0x2500, fg: :white, bg: :default)
    return if width <= 0
    cell = Integer === ch ? ch : ch.ord
    width.times do |dx|
      set_cell(x + dx, y, cell, fg, bg)
    end
  end

  ##
  # Flush the back buffer to the terminal.
  #
  # @return [void]
  def self.present
    Termbox2.present
  end

  ##
  # Clear the back buffer.
  #
  # @return [void]
  def self.clear
    Termbox2.clear
  end

  ##
  # Set the cursor position.
  #
  # @param [Integer] x
  # @param [Integer] y
  # @return [void]
  def self.set_cursor(x, y)
    Termbox2.set_cursor(x, y)
  end

  ##
  # Test whether a key value should be treated as a
  # backspace-style editing key.
  #
  # @param [Integer] key
  # @return [Boolean]
  def self.backspace?(key)
    Key::BACKSPACES.include?(key)
  end

  ##
  # Initialises termbox2, mounts the widget tree,
  # and yields the root widget for the event loop.
  #
  # @example
  #   TUI.run(root) do
  #     loop do
  #       event = TUI.read_event
  #       break unless event
  #       TUI.draw(root)
  #     end
  #   end
  #
  # @param [TUI::Widget] root
  # @yieldparam [TUI::Widget] root The mounted root widget
  # @return [void]
  def self.run(root)
    Termbox2.with_init do
      Termbox2.set_input_mode(Termbox2::INPUT_ESC)
      Termbox2.hide_cursor
      root.mount
      yield(root) if block_given?
    end
  end

  ##
  # Full repaint: clear, render, present.
  #
  # @param [TUI::Widget] root
  # @return [void]
  def self.draw(root)
    return if width <= 0 || height <= 0
    TUI.clear
    root.render
    TUI.present
  end

  ##
  # Resolve a color value accepted by the drawing API.
  #
  # @param [Integer, Symbol] value
  # @return [Integer]
  # @raise [KeyError]
  #  When a symbol is not present in {TUI::COLORS}
  def self.color(value)
    return value unless Symbol === value
    COLORS.fetch(value)
  end

  def self.sanitize_printable(text)
    out = +""
    text.each_char do |char|
      codepoint = char.ord
      out << ((codepoint < 0x20 || codepoint == 0x7F) ? " " : char)
    end
    out
  end

  def self.trim_invalid_suffix(text)
    return text if !text.respond_to?(:valid_encoding?) || text.valid_encoding?
    bytes = text.bytesize
    while bytes > 0
      bytes -= 1
      candidate = text.byteslice(0, bytes)
      return candidate if candidate && candidate.valid_encoding?
    end
    +""
  end

  def self.print_fallback(x, y, fg, bg, text, visible)
    dx = 0
    text.each_char do |char|
      break if dx >= visible
      codepoint = char.ord
      codepoint = 0x20 if codepoint < 0x20 || codepoint == 0x7F
      begin
        Termbox2.set_cell(x + dx, y, codepoint, fg, bg)
      rescue Termbox2::Error
        Termbox2.set_cell(x + dx, y, 0x3F, fg, bg)
      end
      dx += 1
    end
  end

  def self.char_length(text)
    n = 0
    text.each_char { n += 1 }
    n
  end

  def self.take_chars(text, count)
    out = +""
    n = 0
    text.each_char do |char|
      break if n >= count
      out << char
      n += 1
    end
    out
  end

  def self.drop_chars(text, count)
    out = +""
    n = 0
    text.each_char do |char|
      if n >= count
        out << char
      else
        n += 1
      end
    end
    out
  end
end
