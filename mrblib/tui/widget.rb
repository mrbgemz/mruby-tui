# frozen_string_literal: true

module TUI
  ##
  # {TUI::Widget} is the base class of all widgets.
  #
  # @abstract Subclass and override {#render} to
  #  implement custom widgets.
  #
  # Widgets have a position and optional size relative
  # to their parent. The default implementation handles
  # parenting, absolute coordinates, and resolved width
  # and height for fill-style layouts.
  #
  # @example Creating a custom widget
  #   class StatusBar < TUI::Widget
  #     def render
  #       TUI.print(ax, ay, TUI::Color::WHITE, TUI::Color::BLUE, " status: ok ")
  #       super
  #     end
  #   end
  class Widget
    attr_accessor :x, :y, :width, :height, :parent

    ##
    # @param [Integer] x Offset from parent's left edge
    # @param [Integer] y Offset from parent's top edge
    # @param [Integer, nil] width nil fills remaining parent width
    # @param [Integer, nil] height nil fills remaining parent height
    def initialize(x: 0, y: 0, width: nil, height: nil)
      @x = x
      @y = y
      @width = width
      @height = height
      @parent = nil
      @children = []
      @resolved_width = nil
      @resolved_height = nil
    end

    ##
    # Add a child widget.
    #
    # The child's +parent+ is updated immediately.
    #
    # @param [TUI::Widget] child
    # @return [TUI::Widget]
    def add(child)
      @children << child
      child.parent = self
      child
    end

    ##
    # Remove all child widgets.
    #
    # This also clears each child's +parent+ reference.
    #
    # @return [void]
    def clear
      @children.each { _1.parent = nil }
      @children.clear
    end

    ##
    # Screen-space left edge.
    #
    # @return [Integer] absolute column position
    def ax
      p = @parent
      px = p ? p.ax : 0
      px + @x
    end

    ##
    # Screen-space top edge.
    #
    # @return [Integer] absolute row position
    def ay
      p = @parent
      py = p ? p.ay : 0
      py + @y
    end

    ##
    # Resolved width.
    #
    # If +width+ is +nil+, the widget fills the
    # remaining width in its parent.
    #
    # @return [Integer]
    def rw
      @resolved_width || @width || (parent ? [parent.rw - @x, 0].max : TUI.width)
    end

    ##
    # Resolved height.
    #
    # If +height+ is +nil+, the widget fills the
    # remaining height in its parent unless a container
    # assigns a temporary resolved height.
    #
    # @return [Integer]
    def rh
      @resolved_height || @height || (parent ? [parent.rh - @y, 0].max : TUI.height)
    end

    ##
    # Render this widget and its children. Subclasses
    # should override and call +super+.
    #
    # @return [void]
    def render
      @children.each(&:render)
    end

    ##
    # Called once before the first render cycle.
    #
    # Containers can override this to perform setup
    # after the widget tree has been assembled.
    #
    # @return [void]
    def mount
      @children.each(&:mount)
    end

    ##
    # Override the widget's resolved size for the
    # current layout pass.
    #
    # Containers can use this to assign a temporary
    # width or height without mutating the widget's
    # declared +width+ or +height+ attributes.
    #
    # Passing +nil+ clears the override for that axis.
    #
    # @param [Integer, nil] width
    # @param [Integer, nil] height
    # @return [void]
    def resolve!(width: nil, height: nil)
      @resolved_width = width
      @resolved_height = height
    end
  end
end
