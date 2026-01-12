/-
  ZlogLean/Level.lean - Log level definitions matching zlog levels
-/

namespace Zlog

inductive Level where
  | debug
  | info
  | notice
  | warn
  | error
  | fatal
  deriving Repr, BEq, DecidableEq, Inhabited

namespace Level

def toUInt32 : Level → UInt32
  | .debug  => 20
  | .info   => 40
  | .notice => 60
  | .warn   => 80
  | .error  => 100
  | .fatal  => 120

def fromUInt32? : UInt32 → Option Level
  | 20  => some .debug
  | 40  => some .info
  | 60  => some .notice
  | 80  => some .warn
  | 100 => some .error
  | 120 => some .fatal
  | _   => none

/-- Convert from numeric level, defaulting to debug for unknown values -/
def fromUInt32 (n : UInt32) : Level :=
  (fromUInt32? n).getD .debug

instance : ToString Level where
  toString
  | .debug  => "DEBUG"
  | .info   => "INFO"
  | .notice => "NOTICE"
  | .warn   => "WARN"
  | .error  => "ERROR"
  | .fatal  => "FATAL"

instance : Ord Level where
  compare a b := compare a.toUInt32 b.toUInt32

instance : LE Level := leOfOrd
instance : LT Level := ltOfOrd

def isAtLeast (self other : Level) : Bool :=
  self.toUInt32 >= other.toUInt32

end Level

inductive ANSIColor where
  | reset
  | black
  | red
  | green
  | yellow
  | blue
  | magenta
  | cyan
  | white
  | brightBlack
  | brightRed
  | brightGreen
  | brightYellow
  | brightBlue
  | brightMagenta
  | brightCyan
  | brightWhite

namespace ANSIColor

def toCode : ANSIColor → String
  | .reset         => "\x1b[0m"
  | .black         => "\x1b[30m"
  | .red           => "\x1b[31m"
  | .green         => "\x1b[32m"
  | .yellow        => "\x1b[33m"
  | .blue          => "\x1b[34m"
  | .magenta       => "\x1b[35m"
  | .cyan          => "\x1b[36m"
  | .white         => "\x1b[37m"
  | .brightBlack   => "\x1b[90m"
  | .brightRed     => "\x1b[91m"
  | .brightGreen   => "\x1b[92m"
  | .brightYellow  => "\x1b[93m"
  | .brightBlue    => "\x1b[94m"
  | .brightMagenta => "\x1b[95m"
  | .brightCyan    => "\x1b[96m"
  | .brightWhite   => "\x1b[97m"

instance : ToString ANSIColor where
  toString := toCode

end ANSIColor

def Level.toColor : Level → ANSIColor
  | .debug  => .cyan
  | .info   => .green
  | .notice => .blue
  | .warn   => .yellow
  | .error  => .red
  | .fatal  => .magenta

def Level.toColoredString (level : Level) : String :=
  s!"{level.toColor}[{level}]{ANSIColor.reset}"

end Zlog
