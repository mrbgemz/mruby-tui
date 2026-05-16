# frozen_string_literal: true

module TUI
  ##
  # {TUI::TabPanel} is a container that renders one child
  # at a time, identified by an active index.
  #
  # Combine with {TUI::TabBar} to build tabbed interfaces.
  # The active child fills the entire panel area.
  class TabPanel < Widget
    attr_accessor :active

    ##
    # @param [Integer] active  Initial active tab index.
    # @param (see TUI::Widget#initialize)
    def initialize(active: 0, **kw)
      super(**kw)
      @active = active
    end

    ##
    # Render only the active child. Other children are
    # skipped.
    # @return [void]
    def render
      return if rw <= 0 || rh <= 0
      child = @children[@active]
      return unless child
      child.x = 0
      child.y = 0
      child.resolve!(width: rw, height: rh)
      child.render
    end
  end
end
