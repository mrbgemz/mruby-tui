# frozen_string_literal: true

load File.expand_path("mrblib/tui/version.rb", __dir__)

MRuby::Gem::Specification.new("mruby-tui") do |spec|
  spec.license = "0BSD"
  spec.authors = "0x1eef"
  spec.version = TUI::VERSION
  spec.description = "A small terminal UI runtime for mruby"

  spec.add_dependency "mruby-termbox2",
    github: "0x1eef/mruby-termbox2",
    branch: "v0.2.0"

  spec.rbfiles = %w[
    mrblib/tui/version.rb
    mrblib/tui.rb
    mrblib/tui/constants.rb
    mrblib/tui/core.rb
    mrblib/tui/utils.rb
    mrblib/tui/widget.rb
    mrblib/tui/widgets/vbox.rb
    mrblib/tui/widgets/hbox.rb
    mrblib/tui/widgets/frame.rb
    mrblib/tui/widgets/separator.rb
    mrblib/tui/widgets/status_bar.rb
    mrblib/tui/widgets/fill.rb
    mrblib/tui/widgets/label.rb
    mrblib/tui/widgets/input.rb
    mrblib/tui/widgets/textarea.rb
    mrblib/tui/widgets/progress_bar.rb
    mrblib/tui/widgets/banner.rb
    mrblib/tui/widgets/table.rb
    mrblib/tui/widgets/shortcuts.rb
    mrblib/tui/widgets/list.rb
    mrblib/tui/widgets/tree.rb
    mrblib/tui/widgets/tab_bar.rb
    mrblib/tui/widgets/tab_panel.rb
    mrblib/tui/widgets/markdown.rb
    mrblib/tui/widgets/markdown/inline.rb
    mrblib/tui/widgets/markdown/wrap.rb
    mrblib/tui/widgets/markdown/table.rb
    mrblib/tui/widgets/markdown/renderer.rb
  ].map { File.expand_path(_1, __dir__) }
end
