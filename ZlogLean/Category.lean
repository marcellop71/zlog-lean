/-
  ZlogLean/Category.lean - Zlog category management
-/

import ZlogLean.FFI
import ZlogLean.Level

namespace Zlog

structure Category where
  name : String
  ptr : FFI.Category

namespace Category

def get? (name : String) : IO (Option Category) := do
  match ← FFI.zlog_get_category name with
  | some ptr => pure (some { name, ptr })
  | none => pure none

def get (name : String) : IO Category := do
  match ← get? name with
  | some cat => pure cat
  | none => throw <| IO.userError s!"Category '{name}' not found. Is zlog initialized?"

def levelEnabled (cat : Category) (level : Level) : Bool :=
  FFI.zlog_level_enabled cat.ptr level.toUInt32

def setLevel (cat : Category) (level : Level) : Bool :=
  FFI.zlog_level_switch cat.ptr level.toUInt32

def log (cat : Category) (level : Level) (msg : String)
        (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  FFI.zlog_log cat.ptr level.toUInt32 file line func msg

def logColored (cat : Category) (level : Level) (msg : String)
               (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  let coloredMsg := s!"{level.toColor}{msg}{ANSIColor.reset}"
  FFI.zlog_log cat.ptr level.toUInt32 file line func coloredMsg

def logHex (cat : Category) (level : Level) (data : ByteArray)
           (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  FFI.zlog_hex cat.ptr level.toUInt32 file line func data

def debug (cat : Category) (msg : String)
          (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  cat.log .debug msg file line func

def info (cat : Category) (msg : String)
         (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  cat.log .info msg file line func

def notice (cat : Category) (msg : String)
           (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  cat.log .notice msg file line func

def warn (cat : Category) (msg : String)
         (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  cat.log .warn msg file line func

def error (cat : Category) (msg : String)
          (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  cat.log .error msg file line func

def fatal (cat : Category) (msg : String)
          (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  cat.log .fatal msg file line func

def debugC (cat : Category) (msg : String)
           (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  cat.logColored .debug msg file line func

def infoC (cat : Category) (msg : String)
          (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  cat.logColored .info msg file line func

def noticeC (cat : Category) (msg : String)
            (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  cat.logColored .notice msg file line func

def warnC (cat : Category) (msg : String)
          (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  cat.logColored .warn msg file line func

def errorC (cat : Category) (msg : String)
           (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  cat.logColored .error msg file line func

def fatalC (cat : Category) (msg : String)
           (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  cat.logColored .fatal msg file line func

end Category

end Zlog
