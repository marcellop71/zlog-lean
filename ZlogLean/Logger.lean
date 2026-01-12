/-
  ZlogLean/Logger.lean - High-level logging API and monad transformer
-/

import ZlogLean.FFI
import ZlogLean.Level
import ZlogLean.Category

namespace Zlog

/-! ## Zlog Initialization -/

def init (configPath : String) : IO Bool :=
  FFI.zlog_init configPath

def initWithCategory (configPath : String) (category : String) : IO Bool := do
  let ok ← FFI.zlog_init configPath
  if ok then
    let _ ← FFI.dzlog_set_category category
  pure ok

def initFromString (configString : String) : IO Bool :=
  FFI.zlog_init_from_string configString

def reload (configPath : String) : IO Bool :=
  FFI.zlog_reload configPath

def fini : IO Unit :=
  FFI.zlog_fini

def version : IO String :=
  FFI.zlog_version

def profile : IO Unit :=
  FFI.zlog_profile

/-! ## Mapped Diagnostic Context (MDC)

MDC provides thread-local key-value context for log messages.
-/

namespace MDC

def put (key : String) (value : String) : IO Bool :=
  FFI.zlog_put_mdc key value

def get (key : String) : IO (Option String) :=
  FFI.zlog_get_mdc key

def remove (key : String) : IO Unit :=
  FFI.zlog_remove_mdc key

def clean : IO Unit :=
  FFI.zlog_clean_mdc

def withValue (key : String) (value : String) (action : IO α) : IO α := do
  let _ ← put key value
  let result ← action
  remove key
  pure result

end MDC

/-! ## Logger Monad Transformer -/

structure LoggerConfig where
  category : Category
  minLevel : Level := .debug

abbrev LoggerT (m : Type → Type) := ReaderT LoggerConfig m

abbrev LoggerM := LoggerT IO

instance [Monad m] : MonadReader LoggerConfig (LoggerT m) := inferInstance

/-- MonadLift IO IO instance for LoggerM -/
instance : MonadLift IO IO := ⟨id⟩

namespace LoggerT

variable {m : Type → Type} [Monad m] [MonadLift IO m]

def runWith (config : LoggerConfig) (action : LoggerT m α) : m α :=
  action.run config

abbrev run := @runWith

def logAt (level : Level) (msg : String)
          (file : String := "") (line : UInt32 := 0) (func : String := "") : LoggerT m Unit := do
  let config ← read
  if level.isAtLeast config.minLevel then
    liftM <| config.category.log level msg file line func

def debug (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : LoggerT m Unit :=
  logAt .debug msg file line func

def info (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : LoggerT m Unit :=
  logAt .info msg file line func

def notice (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : LoggerT m Unit :=
  logAt .notice msg file line func

def warn (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : LoggerT m Unit :=
  logAt .warn msg file line func

def error (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : LoggerT m Unit :=
  logAt .error msg file line func

def fatal (msg : String) (file : String := "") (line : UInt32 := 0) (func : String := "") : LoggerT m Unit :=
  logAt .fatal msg file line func

/-- Run an action with a modified minimum log level -/
def withMinLevel (level : Level) (action : LoggerT m α) : LoggerT m α :=
  withReader (fun cfg => { cfg with minLevel := level }) action

/-- Run an action with a different category -/
def withCategory (cat : Category) (action : LoggerT m α) : LoggerT m α :=
  withReader (fun cfg => { cfg with category := cat }) action

/-- Log the start and end of an action -/
def traceAction [ToString α] (name : String) (action : LoggerT m α) : LoggerT m α := do
  debug s!"Starting: {name}"
  let result ← action
  debug s!"Completed: {name} -> {result}"
  pure result

end LoggerT

def logDebug {m : Type → Type} [Monad m] [MonadLift IO m] (msg : String) : LoggerT m Unit :=
  LoggerT.debug msg

def logInfo {m : Type → Type} [Monad m] [MonadLift IO m] (msg : String) : LoggerT m Unit :=
  LoggerT.info msg

def logNotice {m : Type → Type} [Monad m] [MonadLift IO m] (msg : String) : LoggerT m Unit :=
  LoggerT.notice msg

def logWarn {m : Type → Type} [Monad m] [MonadLift IO m] (msg : String) : LoggerT m Unit :=
  LoggerT.warn msg

def logError {m : Type → Type} [Monad m] [MonadLift IO m] (msg : String) : LoggerT m Unit :=
  LoggerT.error msg

def logFatal {m : Type → Type} [Monad m] [MonadLift IO m] (msg : String) : LoggerT m Unit :=
  LoggerT.fatal msg

end Zlog
