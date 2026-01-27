{
  description = "zlog-lean - Lean 4 bindings for zlog logging library";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Platform-specific Lean 4 binary
        leanVersion = "4.27.0";
        leanPlatform = if pkgs.stdenv.isDarwin then "darwin" else "linux";
        leanArch = if pkgs.stdenv.isDarwin then "darwin" else "linux";
        leanSha256 = if pkgs.stdenv.isDarwin
          then "sha256-5MpUHYaIHDVJfLbmwaITWPA6Syz7Lo1OFOWNwqCoBa4="
          else "sha256-BW4tyFZPwGSoAeafPrGMBEubVGvIsOWiwAJH+KHLjOY=";

        lean4Bin = pkgs.stdenv.mkDerivation {
          pname = "lean4";
          version = leanVersion;
          src = pkgs.fetchurl {
            url = "https://github.com/leanprover/lean4/releases/download/v${leanVersion}/lean-${leanVersion}-${leanPlatform}.tar.zst";
            sha256 = leanSha256;
          };
          nativeBuildInputs = [ pkgs.zstd ]
            ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.autoPatchelfHook ];
          buildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.stdenv.cc.cc.lib pkgs.zlib ];
          unpackPhase = ''
            tar --zstd -xf $src
          '';
          installPhase = ''
            mkdir -p $out
            cp -r lean-${leanVersion}-${leanArch}/* $out/
          '';
        };
        leanBin = lean4Bin;
        lakeBin = lean4Bin;

        # zlog library (prefer nixpkgs, fallback to a local build if missing)
        zlog = if pkgs ? zlog then pkgs.zlog else pkgs.stdenv.mkDerivation {
          pname = "zlog";
          version = "1.2.18";
          src = pkgs.fetchFromGitHub {
            owner = "HardySimpson";
            repo = "zlog";
            rev = "1.2.18";
            sha256 = "sha256-79yyOGKgqUR1KI2+ngZd7jfVcz4Dw1IxaYfBJyjsxYc=";
          };
          nativeBuildInputs = [ pkgs.gnumake ];
          installPhase = ''
            mkdir -p $out/lib $out/include
            cp src/libzlog.so* $out/lib/ || cp src/libzlog.a $out/lib/
            cp src/zlog.h $out/include/
            cp src/zlog-chk-conf $out/bin/ || true
          '';
          preInstall = "mkdir -p $out/bin";
        };
        zlogDev = pkgs.lib.getDev zlog;

        # Native dependencies for building
        nativeDeps = [
          zlog
          pkgs.gmp
        ];

        # Library path variable name (different on Darwin vs Linux)
        libPathVar = if pkgs.stdenv.isDarwin then "DYLD_LIBRARY_PATH" else "LD_LIBRARY_PATH";

        # Development shell with all dependencies
        devShell = pkgs.mkShell {
          buildInputs = nativeDeps ++ [
            leanBin
            lakeBin
            pkgs.clang
            pkgs.lld
          ];

          # Set up library paths
          LIBRARY_PATH = pkgs.lib.makeLibraryPath nativeDeps;
          C_INCLUDE_PATH = "${zlogDev}/include";

          shellHook = ''
            export ${libPathVar}="${pkgs.lib.makeLibraryPath nativeDeps}"
            echo "zlog-lean development environment"
            echo "Lean version: $(lean --version 2>/dev/null || echo 'Lean not found')"
            echo "zlog available at: ${zlog}"
          '';
        };

        # Build the Lean package
        zlogLeanPackage = pkgs.stdenv.mkDerivation {
          pname = "zlog-lean";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = [ leanBin lakeBin pkgs.clang pkgs.lld pkgs.makeWrapper ];
          buildInputs = nativeDeps;

          configurePhase = ''
            export HOME=$TMPDIR
          '';

          buildPhase = ''
            # Set up library paths for FFI compilation
            export ${libPathVar}="${pkgs.lib.makeLibraryPath nativeDeps}"
            export LIBRARY_PATH="${pkgs.lib.makeLibraryPath nativeDeps}"
            export C_INCLUDE_PATH="${zlogDev}/include"

            # Build the package
            lake build
          '';

          installPhase = ''
            mkdir -p $out/bin $out/lib

            # Copy executables if they exist
            if [ -d .lake/build/bin ]; then
              for bin in .lake/build/bin/*; do
                if [ -f "$bin" ]; then
                  cp "$bin" $out/bin/
                  wrapProgram "$out/bin/$(basename "$bin")" \
                    --prefix ${libPathVar} : "${pkgs.lib.makeLibraryPath nativeDeps}"
                fi
              done
            fi

            # Copy libraries
            if [ -d .lake/build/lib ]; then
              cp -r .lake/build/lib/* $out/lib/
            fi

            # Copy Lake package metadata for downstream consumers
            mkdir -p $out/share/lean
            cp -r .lake/build/ir $out/share/lean/ || true
            cp lakefile.lean $out/share/lean/
            cp lean-toolchain $out/share/lean/
          '';
        };

      in {
        devShells.default = devShell;

        # Export zlog for dependent projects
        packages = {
          inherit zlog;
          default = zlogLeanPackage;
        };

        # Export library paths for dependent flakes
        lib = {
          inherit zlog nativeDeps zlogLeanPackage;
          zlogInclude = "${zlogDev}/include";
          zlogLib = "${zlog}/lib";
        };
      }
    );
}
