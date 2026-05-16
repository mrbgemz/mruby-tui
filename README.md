## About

mruby-tui is a small terminal UI toolkit for mruby. It provides a
compact widget tree on top of
[mruby-termbox2](https://github.com/pusewicz/mruby-termbox2), with
widgets for building chat panes, tables, trees, prompts,
status bars, and other full-screen terminal layouts.

## Quick start

#### Hello world

```ruby
root = TUI::VBox.new
root.add TUI::Label.new("Hello, world!", bold: true, height: 1)
TUI.run(root) { TUI.draw(root) }
```

#### Event loop

```ruby
TUI.run(root) do
  TUI.draw(root)
  loop do
    event = TUI.read_event
    break unless event
    if event.key?(:esc)
      break
    elsif event.event?(:resize)
      TUI.draw(root)
    end
  end
end
```

#### Layout

```ruby
root = TUI::VBox.new
root.add TUI::StatusBar.new("App", right: "ESC quit")
root.add TUI::Separator.new
root.add TUI::Fill.new(height: 1)
root.add TUI::Input.new(height: 3)
```

#### Tabs

```ruby
tab_bar = TUI::TabBar.new(["Chat", "Settings"])
panel = TUI::TabPanel.new
panel.add TUI::Chat.new(show_roles: true)
panel.add TUI::Input.new(height: 5)

# Switch tabs by setting the active index:
tab_bar.active = 1
panel.active = 1
```

#### Table

```ruby
table = TUI::Table.new(
  columns: [
    {header: "ID",   width: 6},
    {header: "Name", width: 20},
    {header: "Score", width: 10}
  ],
  items: (1..50).to_a
) do |item|
  [item.to_s, "Item #{item}", (item * 10).to_s]
end
```

#### Tree

```ruby
tree = TUI::Tree.new do |t|
  t.root = TUI::Tree::Node.new("Root", [
    TUI::Tree::Node.new("Child", [
      TUI::Tree::Node.new("Grandchild")
    ])
  ])
end
```

## Features

**TUI::Widget**<br>
Base class for all widgets. Handles parent/child relationships,
absolute coordinates (ax, ay), and size resolution (rw, rh).

**TUI::VBox**<br>
Vertical layout container. Fixed-height children keep their assigned
height. Children with nil height share remaining space.

**TUI::HBox**<br>
Horizontal layout container. Fixed-width children keep their assigned
width. Children with nil width share remaining space.

**TUI::Frame**<br>
Framed container with an optional title. Frames children with a
one-cell inset.

**TUI::TabBar**<br>
Horizontal tab bar with the active tab highlighted in a configurable
colour. Tabs are set as an array of strings; switch by setting
`active=` to the desired index.

**TUI::TabPanel**<br>
Container that renders one child at a time based on its `active`
index. Other children are skipped. Combine with TabBar to build
tabbed interfaces.

**TUI::StatusBar**<br>
One-line bar with left- and right-aligned text.

**TUI::Separator**<br>
Horizontal separator line drawn across the full widget width.

**TUI::Fill**<br>
Fills an area with a character and colours. Useful for backgrounds
and spacers.

**TUI::Label**<br>
Single-line text with foreground, background, and bold styling.

**TUI::Input**<br>
Single-line prompt-style text input with cursor positioning.

**TUI::ProgressBar**<br>
Progress bar with configurable fill/empty characters and colours.

**TUI::Banner**<br>
Multi-line ASCII art display with horizontal and vertical alignment.

**TUI::List**<br>
Simple list that renders one item per row from a static array
or callable source.

**TUI::Table**<br>
Selectable, scrollable table with column headers, vim-style key
bindings, scrollbar, and selected-row highlighting.

**TUI::Tree**<br>
Expandable/collapsible tree with nested nodes, keyboard navigation,
and collapse/expand indicators.

**TUI::Shortcuts**<br>
Key-binding hint bar with configurable alignment and divider.

## Integration

Add to your mruby build config:

```ruby
MRuby::Build.new("app") do |conf|
  conf.toolchain
  conf.gembox "default"
  conf.gem github: "llmrb/mruby-tui", branch: "main"
end
```

Dependencies are declared in mrbgem.rake:

| Dependency | Purpose |
|---|---|
| mruby-termbox2 | Terminal back buffer, input events, colours |

Drawing helpers (TUI.print, TUI.set_cell) accept either raw colour
constants (TUI::Color::BLUE) or symbol aliases (:blue).

## License

BSD Zero Clause
<br>
See LICENSE
