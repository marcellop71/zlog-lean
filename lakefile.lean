import Lake
open System Lake DSL

-- zlog must be installed on the system
-- Install via: apt-get install libzlog-dev (Ubuntu) or build from source

package zlogLean where
  extraDepTargets := #[`libzlog_shim]
  moreLinkArgs := #[
    "-L/usr/local/lib",
    "-Wl,-rpath,/usr/local/lib",
    "-Wl,--allow-shlib-undefined",
    "-lzlog"
  ]

@[default_target]
lean_lib ZlogLean

lean_exe examples where
  root := `Examples.Main

/-- Compile `src` into `oFile` with a build trace over `src` and `deps` (local headers,
    `#include`d `.c` files), so editing any of them rebuilds the object and the archives
    that use it. `weakArgs` (include paths) are kept out of the trace. -/
def tracedO (oFile src : FilePath) (deps : Array FilePath := #[])
    (weakArgs traceArgs : Array String := #[]) : SpawnM (Job FilePath) := do
  let inputs ← (#[src] ++ deps).mapM inputTextFile
  let srcJob ← (Job.collectArray inputs).mapM fun _ => pure src
  buildO oFile srcJob weakArgs traceArgs

target zlog_shim_o pkg : FilePath := do
  tracedO (pkg.buildDir / "c" / "zlog_shim.o") (pkg.dir / "zlog" / "zlog_shim.c")
    (weakArgs := #["-I", (← getLeanIncludeDir).toString, "-I/usr/local/include"])
    (traceArgs := #["-fPIC", "-O2"])

extern_lib libzlog_shim pkg := do
  let shimObj ← zlog_shim_o.fetch
  let name := nameToStaticLib "zlog_shim"
  buildStaticLib (pkg.staticLibDir / name) #[shimObj]
