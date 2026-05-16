# frozen_string_literal: true

module TUI
  Error = Class.new(Termbox2::Error)

  ##
  # Key constants. Compare against the +key+ field of
  # a key event.
  #
  # Printable characters are usually read from the
  # event's +ch+ field, while special keys use these
  # named constants.
  module Key
    ESC       = Termbox2::KEY_ESC
    ENTER     = Termbox2::KEY_ENTER
    TAB       = Termbox2::KEY_TAB
    SPACE     = Termbox2::KEY_SPACE
    BACKSPACE = Termbox2::KEY_BACKSPACE
    BACKSPACE2 = Termbox2::KEY_BACKSPACE2
    DELETE    = Termbox2::KEY_DELETE
    HOME      = Termbox2::KEY_HOME
    END_      = Termbox2::KEY_END
    PGUP      = Termbox2::KEY_PGUP
    PGDN      = Termbox2::KEY_PGDN
    INSERT    = Termbox2::KEY_INSERT
    UP        = Termbox2::KEY_ARROW_UP
    DOWN      = Termbox2::KEY_ARROW_DOWN
    LEFT      = Termbox2::KEY_ARROW_LEFT
    RIGHT     = Termbox2::KEY_ARROW_RIGHT
    F1        = Termbox2::KEY_F1
    F2        = Termbox2::KEY_F2
    F3        = Termbox2::KEY_F3
    F4        = Termbox2::KEY_F4
    F5        = Termbox2::KEY_F5
    F6        = Termbox2::KEY_F6
    F7        = Termbox2::KEY_F7
    F8        = Termbox2::KEY_F8
    F9        = Termbox2::KEY_F9
    F10       = Termbox2::KEY_F10
    F11       = Termbox2::KEY_F11
    F12       = Termbox2::KEY_F12
    CTRL_A    = Termbox2::KEY_CTRL_A
    CTRL_C    = Termbox2::KEY_CTRL_C
    CTRL_D    = Termbox2::KEY_CTRL_D
    CTRL_L    = Termbox2::KEY_CTRL_L
    CTRL_U    = Termbox2::KEY_CTRL_U
    CTRL_W    = Termbox2::KEY_CTRL_W

    ##
    # Common backspace-style key values emitted by
    # terminals and termbox2 backends.
    BACKSPACES = [BACKSPACE, BACKSPACE2, DELETE].freeze
  end

  ##
  # Named terminal colours exposed by {Termbox2}.
  #
  # These constants can be used anywhere mruby-tui
  # expects a foreground or background color.
  #
  # @example
  #   TUI.print(0, 0, TUI::Color::WHITE, TUI::Color::BLUE, " title ")
  #
  # Symbol aliases are also available through {COLORS}:
  #
  # @example
  #   TUI.print(0, 0, :white, :blue, " title ")
  module Color
    DEFAULT = Termbox2::DEFAULT
    BLACK   = Termbox2::BLACK
    RED     = Termbox2::RED
    GREEN   = Termbox2::GREEN
    YELLOW  = Termbox2::YELLOW
    BLUE    = Termbox2::BLUE
    MAGENTA = Termbox2::MAGENTA
    CYAN    = Termbox2::CYAN
    WHITE   = Termbox2::WHITE
  end

  COLORS = {
    default: Color::DEFAULT,
    black: Color::BLACK,
    red: Color::RED,
    green: Color::GREEN,
    yellow: Color::YELLOW,
    blue: Color::BLUE,
    magenta: Color::MAGENTA,
    cyan: Color::CYAN,
    white: Color::WHITE
  }.freeze

  ##
  # Text attribute flags exposed by {Termbox2}.
  #
  # Combine these flags with values from {Color} using
  # bitwise +|+.
  #
  # @example
  #   fg = TUI::Color::WHITE | TUI::Attr::BOLD
  module Attr
    BOLD      = Termbox2::BOLD
    ITALIC    = Termbox2::ITALIC
    UNDERLINE = Termbox2::UNDERLINE
    REVERSE   = Termbox2::REVERSE
    BLINK     = Termbox2::BLINK
    DIM       = Termbox2::DIM
    BRIGHT    = Termbox2::BRIGHT
  end

  ##
  # Event type constants and query methods.
  #
  # This module serves two purposes:
  # 1. Provides event type constants (KEY, RESIZE, MOUSE)
  # 2. Can be extended onto event objects from
  #    {TUI.poll_event} to add query methods
  #
  # @example
  #   ev = TUI.poll_event
  #   if ev.key?(:esc)
  #     break
  #   elsif ev.event?(:resize)
  #     TUI.draw(root)
  #   end
  module Event
    KEY    = Termbox2::EVENT_KEY
    RESIZE = Termbox2::EVENT_RESIZE
    MOUSE  = Termbox2::EVENT_MOUSE

    KEYS = {
      esc:       Key::ESC,
      enter:     Key::ENTER,
      tab:       Key::TAB,
      space:     Key::SPACE,
      backspace: Key::BACKSPACE,
      delete:    Key::DELETE,
      home:      Key::HOME,
      end_:      Key::END_,
      pgup:      Key::PGUP,
      pgdn:      Key::PGDN,
      insert:    Key::INSERT,
      up:        Key::UP,
      down:      Key::DOWN,
      left:      Key::LEFT,
      right:     Key::RIGHT,
      f1:        Key::F1,
      f2:        Key::F2,
      f3:        Key::F3,
      f4:        Key::F4,
      f5:        Key::F5,
      f6:        Key::F6,
      f7:        Key::F7,
      f8:        Key::F8,
      f9:        Key::F9,
      f10:       Key::F10,
      f11:       Key::F11,
      f12:       Key::F12,
      ctrl_a:    Key::CTRL_A,
      ctrl_c:    Key::CTRL_C,
      ctrl_d:    Key::CTRL_D,
      ctrl_l:    Key::CTRL_L,
      ctrl_u:    Key::CTRL_U,
      ctrl_w:    Key::CTRL_W
    }.freeze

    EVENTS = {
      key:    KEY,
      resize: RESIZE,
      mouse:  MOUSE
    }.freeze

    ##
    # Returns true when the event's key matches the
    # given name.
    #
    # @param [Symbol] name
    # @return [Boolean]
    def key?(name)
      key == KEYS[name] || key == Key.const_get(name)
    rescue NameError
      false
    end

    ##
    # Returns true when the event's type matches the
    # given name.
    #
    # @param [Symbol] name
    # @return [Boolean]
    def event?(name)
      type == EVENTS[name]
    end
  end
end
