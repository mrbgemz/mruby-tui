# frozen_string_literal: true

module TUI
  ##
  # {TUI::VBox} arranges children vertically.
  #
  # Children with an explicit +height+ keep that height.
  # Children with +nil+ height are treated as flexible
  # and share the remaining vertical space.
  class VBox < Widget
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
      if child.height
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
      cy = ay
      parent_w = rw
      total_fixed_h = 0
      @fixed.each { total_fixed_h += _1.rh }
      remaining = [rh - total_fixed_h, 0].max
      flex_count = @flex.size
      @children.each do |child|
        child.x = 0
        child.y = cy - ay
        if child.height
          child.resolve!(width: parent_w)
          cy += child.rh
        else
          share = flex_count.zero? ? 0 : remaining / flex_count
          child.resolve!(width: parent_w, height: share)
          cy += share
          remaining -= share
          flex_count -= 1
        end
      end
      super
    end
  end
end
