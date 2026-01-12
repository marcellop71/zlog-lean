/-
  ZlogLean/Default.lean - Default category logging (dzlog API)
-/

import ZlogLean.FFI
import ZlogLean.Level

namespace Zlog.Default

def init (configPath : String) (categoryName : String) : IO Bool :=
  FFI.dzlog_init configPath categoryName

def setCategory (categoryName : String) : IO Bool :=
  FFI.dzlog_set_category categoryName

def levelEnabled (level : Level) : IO Bool :=
  FFI.dzlog_level_enabled level.toUInt32

def log (level : Level) (msg : String)
        (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  FFI.dzlog_log level.toUInt32 file line func msg

def logColored (level : Level) (msg : String)
               (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  let coloredMsg := s!"{level.toColor}{msg}{ANSIColor.reset}"
  FFI.dzlog_log level.toUInt32 file line func coloredMsg

def debug (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  log .debug msg file line func

def info (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  log .info msg file line func

def notice (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  log .notice msg file line func

def warn (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  log .warn msg file line func

def error (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  log .error msg file line func

def fatal (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  log .fatal msg file line func

def debugC (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  logColored .debug msg file line func

def infoC (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  logColored .info msg file line func

def noticeC (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  logColored .notice msg file line func

def warnC (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  logColored .warn msg file line func

def errorC (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  logColored .error msg file line func

def fatalC (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : IO Unit :=
  logColored .fatal msg file line func

end Zlog.Default

namespace Zlog

def debug (msg : String) : IO Unit :=
  Default.debug msg

def info (msg : String) : IO Unit :=
  Default.info msg

def notice (msg : String) : IO Unit :=
  Default.notice msg

def warn (msg : String) : IO Unit :=
  Default.warn msg

def error (msg : String) : IO Unit :=
  Default.error msg

def fatal (msg : String) : IO Unit :=
  Default.fatal msg

def debugC (msg : String) : IO Unit :=
  Default.debugC msg

def infoC (msg : String) : IO Unit :=
  Default.infoC msg

def noticeC (msg : String) : IO Unit :=
  Default.noticeC msg

def warnC (msg : String) : IO Unit :=
  Default.warnC msg

def errorC (msg : String) : IO Unit :=
  Default.errorC msg

def fatalC (msg : String) : IO Unit :=
  Default.fatalC msg

end Zlog
