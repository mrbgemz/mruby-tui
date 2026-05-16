# frozen_string_literal: true

##
# {TUI::List} renders a simple one-column list with
# one item per row.
#
# Items can be provided as a static array or as a
# callable object that returns the current array at
# render time.
#
# @example Fixed items
#   list = TUI::List.new(["alpha", "beta", "gamma"])
#
# @example Dynamic items
#   list = TUI::List.new(-> { fetch_items })
class TUI::List < TUI::Widget
  ##
  # @param [Array, #call] items
  #   Static items or a callable that returns the
  #   current item list.
  # @param [Integer, Symbol] fg
  # @param [Integer, Symbol] bg
  # @param [Hash] kw  Remaining keyword args for
  #   {TUI::Widget#initialize}
  def initialize(items, fg: :white, bg: :default, **kw)
    super(**kw)
    @items = items
    @fg = fg
    @bg = bg
  end

  ##
  # Draw the visible portion of the list.
  #
  # Each row is left padded with one space and clipped
  # to the widget width.
  #
  # @return [void]
  def render
    return if rw <= 0 || rh <= 0
    items.first(rh).each_with_index do |item, index|
      TUI.print(ax, ay + index, @fg, @bg, " #{item}".ljust(rw)[0, rw])
    end
    super
  end

  private

  ##
  # Resolve the current item source.
  #
  # @return [Array]
  def items
    value = @items.respond_to?(:call) ? @items.call : @items
    value || []
  end
end
