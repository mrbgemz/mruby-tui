# frozen_string_literal: true

module TUI
  ##
  # {TUI::Tree} is an expandable, collapsible tree widget
  # inspired by radicle-tui's tree widget.
  #
  # Each node is a {Node} with a label, an optional list of
  # child nodes, and an open/closed state.
  #
  # Keyboard navigation:
  #   Up/k, Down/j  — move selection
  #   Right/l       — expand selected node
  #   Left/h        — collapse selected node
  #
  # @example
  #   tree = TUI::Tree.new do |t|
  #     t.root = TUI::Tree::Node.new("Root", [
  #       TUI::Tree::Node.new("Child 1", [
  #         TUI::Tree::Node.new("Grandchild 1"),
  #         TUI::Tree::Node.new("Grandchild 2")
  #       ]),
  #       TUI::Tree::Node.new("Child 2")
  #     ])
  #   end
  class Tree < Widget
    ##
    # A single node in the tree.
    class Node
      ## @return [String] display label
      attr_accessor :label

      ## @return [Array<Node>, nil] child nodes
      attr_accessor :children

      ## @return [Boolean] whether the node is expanded
      attr_accessor :open

      ## @param [String] label
      ## @param [Array<Node>, nil] children
      ## @param [Boolean] open
      def initialize(label, children = nil, open: false)
        @label = label
        @children = children
        @open = open
      end

      ##
      # Walk the tree depth-first and yield each visible node
      # followed by its indentation depth.
      def each_visible(depth = 0, &block)
        yield(self, depth)
        return unless @open && @children
        @children.each { |c| c.each_visible(depth + 1, &block) }
      end

      ##
      # Count visible nodes (for scroll bounds).
      def visible_count
        count = 1
        return count unless @open && @children
        @children.each { |c| count += c.visible_count }
        count
      end

      ##
      # Find the Nth visible node (0-based).
      def visible_at(index, depth = 0)
        return [self, depth] if index == 0
        remaining = index - 1
        return nil if remaining < 0
        if @open && @children
          @children.each do |c|
            result = c.visible_at(remaining, depth + 1)
            return result if result
            remaining -= c.visible_count
          end
        end
        nil
      end
    end

    ##
    # @return [Node, nil] root node
    attr_accessor :root

    ##
    # @return [Integer, nil] currently selected visible index
    attr_reader :selected

    ##
    # @param [Integer, Symbol] fg
    # @param [Integer, Symbol] selected_fg
    # @param [Integer, Symbol] bg
    # @param [Hash] kw  Passed to {Widget#initialize}
    def initialize(fg: :white, selected_fg: :white, bg: :default, **kw)
      super(**kw)
      @root = nil
      @selected = nil
      @scroll = 0
      @fg = fg
      @selected_fg = selected_fg
      @bg = bg
      @yield_self = false
      yield(self) if block_given?
    end

    ##
    # Navigate the tree based on a key event.
    # Returns +true+ if the selection changed.
    #
    # @param [Integer] key  A +TUI::Key+ constant
    # @return [Boolean]
    def navigate(key)
      return false unless @root
      total = @root.visible_count
      old = @selected
      case key
      when Key::UP, Key::CTRL_K, Key::CTRL_P
        return false if @selected.nil? || @selected <= 0
        @selected -= 1
      when Key::DOWN, Key::CTRL_J, Key::CTRL_N
        if @selected.nil?
          @selected = 0
        else
          return false if @selected >= total - 1
          @selected += 1
        end
      when Key::RIGHT, Key::CTRL_L
        return false if @selected.nil?
        node, = @root.visible_at(@selected)
        if node && node.children && !node.children.empty? && !node.open
          node.open = true
        end
      when Key::LEFT, Key::CTRL_H
        return false if @selected.nil?
        node, = @root.visible_at(@selected)
        if node && node.open
          node.open = false
        end
      else
        return false
      end
      clamp_scroll
      @selected != old
    end

    ##
    # Draw the tree.
    # @return [void]
    def render
      return if rw <= 0 || rh <= 0 || !@root
      fg = TUI.color(@fg)
      bg_c = TUI.color(@bg)
      sel_fg = TUI.color(@selected_fg) | Attr::REVERSE
      y = ay
      visible = 0
      @root.each_visible do |node, depth|
        break if y >= ay + rh
        next if visible < @scroll
        is_sel = visible == @selected
        indent = "  " * depth
        prefix = if node.children && !node.children.empty?
                   node.open ? "▼ " : "▶ "
                 else
                   "  "
                 end
        label = "#{indent}#{prefix}#{node.label}"
        if is_sel
          clear = " " * [rw - label.length, 0].max
          TUI.print(ax, y, sel_fg, bg_c, label + clear)
        else
          TUI.print(ax, y, fg, bg_c, label)
        end
        y += 1
        visible += 1
      end
      super
    end

    private

    def clamp_scroll
      return unless @root && @selected
      page = rh
      if @selected < @scroll
        @scroll = @selected
      elsif @selected >= @scroll + page
        @scroll = @selected - page + 1
      end
      max_scroll = [@root.visible_count - page, 0].max
      @scroll = max_scroll if @scroll > max_scroll
      @scroll = 0 if @scroll < 0
    end
  end
end
