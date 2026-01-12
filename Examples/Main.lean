import ZlogLean

open Zlog

def exampleCategoryLogging : IO Unit := do
  IO.println "\n=== Category-based Logging ==="

  -- Get categories
  let appCat ← Category.get "my_app"
  let dbCat ← Category.get "database"

  -- Log with different categories
  appCat.info "Application starting..."
  appCat.debug "Debug information"

  dbCat.info "Connecting to database"
  dbCat.warn "Connection pool running low"

  appCat.info "Application ready"

def exampleDefaultLogging : IO Unit := do
  IO.println "\n=== Default Category Logging ==="

  -- Set the default category (required before using Zlog.debug etc.)
  let _ ← Zlog.Default.setCategory "default"

  -- Simple logging functions (no color)
  Zlog.debug "This is a debug message"
  Zlog.info "This is an info message"
  Zlog.notice "This is a notice"
  Zlog.warn "This is a warning"
  Zlog.error "This is an error"

  IO.println "\n=== Colored Logging ==="

  -- Colored logging functions (with ANSI colors)
  Zlog.debugC "This is a colored debug message"
  Zlog.infoC "This is a colored info message"
  Zlog.noticeC "This is a colored notice"
  Zlog.warnC "This is a colored warning"
  Zlog.errorC "This is a colored error"
  Zlog.fatalC "This is a colored fatal message"

def exampleMDC : IO Unit := do
  IO.println "\n=== Mapped Diagnostic Context (MDC) ==="

  -- Set context values
  let _ ← MDC.put "user_id" "12345"
  let _ ← MDC.put "request_id" "req-abc-123"

  Zlog.info "Processing request with context"

  -- Get a context value
  let userId ← MDC.get "user_id"
  IO.println s!"Current user_id in MDC: {userId.getD "none"}"

  -- Clean up
  MDC.clean

def exampleLoggerT : IO Unit := do
  IO.println "\n=== LoggerT Monad Transformer ==="

  let cat ← Category.get "my_app"
  let config : LoggerConfig := { category := cat, minLevel := .debug }

  -- Run logging in the LoggerT monad
  let action : LoggerM Unit := do
    LoggerT.info "Starting operation"
    LoggerT.debug "Processing step 1"
    LoggerT.debug "Processing step 2"
    LoggerT.info "Operation complete"

  LoggerT.runWith config action

def main : IO Unit := do
  IO.println "ZlogLean Example"
  IO.println "================"

  -- Use default config path
  let configPath := "config/zlog.conf"

  IO.println s!"Initializing zlog with config: {configPath}"

  -- Initialize zlog
  let ok ← init configPath
  if !ok then
    IO.eprintln s!"Failed to initialize zlog from '{configPath}'"
    IO.eprintln "Make sure the config file exists and zlog is installed."
    IO.eprintln ""
    IO.eprintln "Example zlog.conf:"
    IO.eprintln "  [global]"
    IO.eprintln "  strict init = true"
    IO.eprintln ""
    IO.eprintln "  [formats]"
    IO.eprintln "  simple = \"%d %V [%c] %m%n\""
    IO.eprintln ""
    IO.eprintln "  [rules]"
    IO.eprintln "  *.* >stdout; simple"
    return

  -- Show version
  let ver ← version
  IO.println s!"zlog version: {ver}"

  -- Run examples
  exampleCategoryLogging
  exampleDefaultLogging
  exampleMDC
  exampleLoggerT

  -- Cleanup
  fini

  IO.println "\n=== Done ==="
