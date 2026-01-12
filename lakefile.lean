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

target zlog_shim_o pkg : FilePath := do
  let srcFile := pkg.dir / "zlog" / "zlog_shim.c"
  let oFile := pkg.buildDir / "c" / "zlog_shim.o"
  IO.FS.createDirAll oFile.parent.get!
  let flags := #["-fPIC", "-O2", "-I", (← getLeanIncludeDir).toString, "-I/usr/local/include"]
  compileO oFile srcFile flags
  return .pure oFile

extern_lib libzlog_shim pkg := do
  let shimObj ← zlog_shim_o.fetch
  let name := nameToStaticLib "zlog_shim"
  buildStaticLib (pkg.staticLibDir / name) #[shimObj]
