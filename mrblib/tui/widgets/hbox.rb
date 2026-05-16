# frozen_string_literal: true

module TUI
  ##
  # {TUI::HBox} arranges children horizontally.
  #
  # Children with an explicit +width+ keep that width.
  # Children with +nil+ width are treated as flexible
  # and share the remaining horizontal space.
  class HBox < Widget
    ##
    # @param (see TUI::Widget#initialize)
    def initialize(x: 0, y: 0, width: nil, height: nil)
      super
      @fixed = []
      @flex = []
    end

    ##
    # Add a child and classify it as fixed or flexible.
    #
    # @param [TUI::Widget] child
    # @return [TUI::Widget]
    def add(child)
      super
      if child.width
        @fixed << child
      else
        @flex << child
      end
      child
    end

    ##
    # Lay out children and render them in order.
    #
    # @return [void]
    def render
      cx = ax
      parent_h = rh
      total_fixed_w = 0
      @fixed.each { total_fixed_w += _1.rw }
      remaining = [rw - total_fixed_w, 0].max
      flex_count = @flex.size
      @children.each do |child|
        child.x = cx - ax
        child.y = 0
        if child.width
          child.resolve!(height: parent_h)
          cx += child.rw
        else
          share = flex_count.zero? ? 0 : remaining / flex_count
          child.resolve!(width: share, height: parent_h)
          cx += share
          remaining -= share
          flex_count -= 1
        end
      end
      super
    end
  end
end
