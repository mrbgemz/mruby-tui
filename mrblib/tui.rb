# frozen_string_literal: true

##
# {TUI} is a minimal widget toolkit built on
# {Termbox2}[https://github.com/pusewicz/mruby-termbox2].
#
# Widgets form a tree. Each widget has a position and
# size relative to its parent. +nil+ width or height
# means "fill remaining space". Children are rendered
# in order, so later children appear on top.
#
# @example A simple chat layout
#   root = TUI::VBox.new
#   root.add TUI::Fill.new(height: 1, bg: TUI::Color::BLUE)
#   root.add TUI::Label.new("Chat", bold: true, height: 1)
#   root.add TUI::Log.new
#   root.add TUI::Input.new(height: 3)
#   TUI.run(root) { TUI.draw(root) }
module TUI
end
