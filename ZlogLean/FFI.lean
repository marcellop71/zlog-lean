/-
  ZlogLean/FFI.lean - Low-level FFI bindings to zlog C library
-/

namespace Zlog.FFI

/-- Opaque type for zlog category pointer -/
opaque CategoryPointer : NonemptyType
def Category := CategoryPointer.type
instance : Nonempty Category := CategoryPointer.property

/-! ## Initialization and Configuration -/

/-- Initialize zlog from a configuration file path -/
@[extern "lean_zlog_init"]
opaque zlog_init (configPath : @& String) : IO Bool

/-- Initialize zlog from a configuration string -/
@[extern "lean_zlog_init_from_string"]
opaque zlog_init_from_string (configString : @& String) : IO Bool

/-- Reload zlog configuration from file -/
@[extern "lean_zlog_reload"]
opaque zlog_reload (configPath : @& String) : IO Bool

/-- Finalize zlog and release resources -/
@[extern "lean_zlog_fini"]
opaque zlog_fini : IO Unit

/-- Get zlog version string -/
@[extern "lean_zlog_version"]
opaque zlog_version : IO String

/-! ## Category Management -/

/-- Get a logging category by name. Returns none if category not found. -/
@[extern "lean_zlog_get_category"]
opaque zlog_get_category (name : @& String) : IO (Option Category)

/-- Check if a log level is enabled for a category -/
@[extern "lean_zlog_level_enabled"]
opaque zlog_level_enabled (cat : @& Category) (level : UInt32) : Bool

/-- Switch the log level for a category -/
@[extern "lean_zlog_level_switch"]
opaque zlog_level_switch (cat : @& Category) (level : UInt32) : Bool

/-! ## Logging Functions -/

/-- Log a message at a specific level -/
@[extern "lean_zlog_log"]
opaque zlog_log (cat : @& Category) (level : UInt32) (file : @& String)
                (line : UInt32) (func : @& String) (msg : @& String) : IO Unit

/-- Log hex/binary data -/
@[extern "lean_zlog_hex"]
opaque zlog_hex (cat : @& Category) (level : UInt32) (file : @& String)
                (line : UInt32) (func : @& String) (data : @& ByteArray) : IO Unit

/-! ## Default Category API (dzlog) -/

/-- Initialize default category logging -/
@[extern "lean_dzlog_init"]
opaque dzlog_init (configPath : @& String) (category : @& String) : IO Bool

/-- Set the default category -/
@[extern "lean_dzlog_set_category"]
opaque dzlog_set_category (category : @& String) : IO Bool

/-- Check if a level is enabled for the default category -/
@[extern "lean_dzlog_level_enabled"]
opaque dzlog_level_enabled (level : UInt32) : IO Bool

/-- Log to the default category -/
@[extern "lean_dzlog_log"]
opaque dzlog_log (level : UInt32) (file : @& String) (line : UInt32)
                 (func : @& String) (msg : @& String) : IO Unit

/-! ## Mapped Diagnostic Context (MDC) -/

/-- Put a key-value pair into MDC -/
@[extern "lean_zlog_put_mdc"]
opaque zlog_put_mdc (key : @& String) (value : @& String) : IO Bool

/-- Get a value from MDC by key -/
@[extern "lean_zlog_get_mdc"]
opaque zlog_get_mdc (key : @& String) : IO (Option String)

/-- Remove a key from MDC -/
@[extern "lean_zlog_remove_mdc"]
opaque zlog_remove_mdc (key : @& String) : IO Unit

/-- Clean all MDC data -/
@[extern "lean_zlog_clean_mdc"]
opaque zlog_clean_mdc : IO Unit

/-! ## Utility Functions -/

/-- Display profiling information -/
@[extern "lean_zlog_profile"]
opaque zlog_profile : IO Unit

end Zlog.FFI
