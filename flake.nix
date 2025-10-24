{
  description = "Pandoc beamer presentation template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    sunscreen-llvm.url = "github:Sunscreen-tech/sunscreen-llvm";
    sunscreen-llvm.inputs.nixpkgs.follows = "nixpkgs";
    foundry.url = "github:shazow/foundry.nix/stable";
  };

  outputs = { self, nixpkgs, utils, sunscreen-llvm, foundry }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ foundry.overlay ];
        };
        sunscreen-llvm-pkg = sunscreen-llvm.packages.${system}.default;

        texlive = pkgs.texlive.combine {
          inherit (pkgs.texlive)
            scheme-small fontspec pgfopts beamer beamertheme-metropolis;
        };

        fonts = pkgs.makeFontsConf {
          fontDirectories = with pkgs; [ fira fira-mono iosevka ];
        };

        # Common setup for builds requiring cache directories
        setupCacheEnv = ''
          export HOME=$TMPDIR
          export XDG_CACHE_HOME=$TMPDIR/.cache
          mkdir -p $XDG_CACHE_HOME
        '';

        # Extract code from presentation as a separate derivation
        extractedCode = pkgs.runCommand "extract-code" {
          nativeBuildInputs = [ pkgs.pandoc ];
          src = pkgs.nix-gitignore.gitignoreSource [ ] ./.;
        } ''
          mkdir -p $out/fhe-programs/src $out/contracts

          cd $TMPDIR
          cp -r $src/* .
          chmod -R u+w .

          echo "Extracting code from presentation..."
          pandoc src/presentation.md --lua-filter=filters/extract-code.lua -o /dev/null

          # Copy extracted code to output
          if [ -d fhe-programs/src ]; then
            cp -r fhe-programs/src/* $out/fhe-programs/src/
          fi

          if [ -d contracts ]; then
            cp -r contracts/* $out/contracts/ || true
          fi

          echo "Code extraction complete"
        '';
      in {
        packages.default =
          pkgs.callPackage ./default.nix { inherit (pkgs) nix-gitignore; };

        checks = {
          # Check that C code extracts and compiles with Sunscreen LLVM
          c-compilation = pkgs.stdenv.mkDerivation {
            name = "check-c-compilation";
            src = pkgs.nix-gitignore.gitignoreSource [ ] ./.;

            nativeBuildInputs = [ sunscreen-llvm-pkg pkgs.pandoc ];

            dontBuild = true;
            doCheck = true;

            checkPhase = ''
              runHook preCheck

              echo "=== Tool versions ==="
              pandoc --version | head -1
              ${sunscreen-llvm-pkg}/bin/clang --version | head -1

              # Extract C code from presentation
              echo "=== Extracting C code from presentation ==="
              pandoc src/presentation.md --lua-filter=filters/extract-code.lua -o /dev/null

              # Verify extraction succeeded
              if [ ! -f "fhe-programs/src/voting.c" ]; then
                echo "Error: voting.c was not extracted" >&2
                exit 1
              fi

              # Verify Makefile exists
              if [ ! -f "fhe-programs/src/Makefile" ]; then
                echo "Error: fhe-programs/src/Makefile not found" >&2
                exit 1
              fi

              echo "C code extracted successfully ($(wc -l < fhe-programs/src/voting.c) lines)"

              # Compile with Sunscreen LLVM
              echo "=== Compiling C code with Sunscreen LLVM ==="
              cd fhe-programs/src
              export CLANG_DIR=${sunscreen-llvm-pkg}/bin

              # Verify CLANG_DIR points to valid clang
              if [ ! -x "$CLANG_DIR/clang" ]; then
                echo "Error: clang not found at $CLANG_DIR/clang" >&2
                exit 1
              fi

              if ! make 2>&1 | tee compile.log; then
                echo "=== Compilation failed ===" >&2
                cat compile.log >&2
                exit 1
              fi

              # Verify compilation produced outputs
              if [ ! -f "../compiled/voting" ]; then
                echo "Error: voting binary was not created" >&2
                exit 1
              fi

              echo "C compilation successful"

              runHook postCheck
            '';

            installPhase = ''
              mkdir -p $out/compiled
              if [ -d fhe-programs/compiled ] && [ "$(ls -A fhe-programs/compiled)" ]; then
                cp fhe-programs/compiled/* $out/compiled/
              fi
              echo "C code extraction and compilation check passed" > $out/result
            '';

            passthru = { inherit sunscreen-llvm-pkg extractedCode; };
          };

          # Check that Solidity code extracts and compiles
          solidity-compilation = pkgs.stdenv.mkDerivation {
            name = "check-solidity-compilation";
            src = pkgs.nix-gitignore.gitignoreSource [ ] ./.;

            nativeBuildInputs = [ pkgs.pandoc pkgs.foundry-bin ];

            dontBuild = true;
            doCheck = true;

            checkPhase = ''
              runHook preCheck

              ${setupCacheEnv}

              echo "=== Tool versions ==="
              pandoc --version | head -1
              forge --version

              # Verify foundry.toml exists
              if [ ! -f "foundry.toml" ]; then
                echo "Error: foundry.toml not found in source" >&2
                exit 1
              fi

              # Verify submodule dependency exists
              if [ ! -d "lib/sunscreen-contracts" ]; then
                echo "Error: lib/sunscreen-contracts submodule not found" >&2
                echo "Ensure flake is accessed with ?submodules=1" >&2
                exit 1
              fi

              # Extract Solidity code from presentation
              echo "=== Extracting Solidity code from presentation ==="
              pandoc src/presentation.md --lua-filter=filters/extract-code.lua -o /dev/null

              # Verify extraction succeeded
              if [ ! -f "contracts/BinaryVoting.sol" ]; then
                echo "Error: BinaryVoting.sol was not extracted" >&2
                exit 1
              fi

              echo "Solidity code extracted successfully"

              # Compile with Foundry
              echo "=== Compiling Solidity code with forge ==="
              if ! forge build 2>&1 | tee forge.log; then
                echo "=== Forge build failed ===" >&2
                cat forge.log >&2
                exit 1
              fi

              # Verify compilation produced outputs
              if [ ! -d "build/foundry" ]; then
                echo "Error: forge build did not create build/foundry directory" >&2
                exit 1
              fi

              echo "Solidity compilation successful"

              runHook postCheck
            '';

            installPhase = ''
              mkdir -p $out
              if [ -d build/foundry ]; then
                cp -r build/foundry $out/
              fi
              echo "Solidity code extraction and compilation check passed" > $out/result
            '';

            passthru = { inherit extractedCode; };
          };

          # Check that presentation builds successfully with QR codes
          presentation-build = pkgs.stdenv.mkDerivation {
            name = "check-presentation-build";
            src = pkgs.nix-gitignore.gitignoreSource [ ] ./.;

            nativeBuildInputs = [ pkgs.pandoc pkgs.qrencode pkgs.bash ];
            buildInputs = [ texlive ];

            FONTCONFIG_FILE = fonts;

            dontBuild = true;
            doCheck = true;

            checkPhase = ''
              runHook preCheck

              ${setupCacheEnv}
              mkdir -p $XDG_CACHE_HOME/fontconfig

              echo "=== Tool versions ==="
              pandoc --version | head -1
              qrencode --version | head -1

              # Verify build script exists
              if [ ! -x "scripts/build-presentation" ]; then
                echo "Error: scripts/build-presentation not found or not executable" >&2
                exit 1
              fi

              # Verify generate-qrcodes script exists
              if [ ! -x "scripts/generate-qrcodes" ]; then
                echo "Error: scripts/generate-qrcodes not found or not executable" >&2
                exit 1
              fi

              # Build presentation (includes QR code generation)
              echo "=== Building presentation ==="
              if ! bash scripts/build-presentation 2>&1 | tee build.log; then
                echo "=== Build failed ===" >&2
                cat build.log >&2
                exit 1
              fi

              # Verify QR codes were generated
              echo "=== Verifying QR codes ==="
              for qr in figs/qr-voting-demo.png figs/qr-spf-docs.png figs/qr-processor-docs.png; do
                if [ ! -f "$qr" ]; then
                  echo "Error: $qr was not generated" >&2
                  exit 1
                fi
              done

              # Verify PDFs were created
              echo "=== Verifying PDFs ==="
              if [ ! -f "build/presentation.pdf" ]; then
                echo "Error: presentation.pdf was not created" >&2
                exit 1
              fi

              if [ ! -f "build/presentation-handout.pdf" ]; then
                echo "Error: presentation-handout.pdf was not created" >&2
                exit 1
              fi

              echo "Presentation build successful"

              runHook postCheck
            '';

            installPhase = ''
              mkdir -p $out
              if [ -d build ]; then
                cp -r build $out/
              fi
              if ls figs/qr-*.png 1> /dev/null 2>&1; then
                mkdir -p $out/qrcodes
                cp figs/qr-*.png $out/qrcodes/
              fi
              echo "Presentation build check passed" > $out/result
            '';
          };

          # Run all checks sequentially
          all = pkgs.runCommand "check-all" {
            nativeBuildInputs = [
              self.checks.${system}.c-compilation
              self.checks.${system}.solidity-compilation
              self.checks.${system}.presentation-build
            ];
          } ''
            echo "All checks passed successfully"
            mkdir -p $out
            echo "All checks passed" > $out/result
          '';
        };

        # Development shell using mkShellNoCC to avoid pulling in the standard
        # C compiler toolchain. This ensures Sunscreen's LLVM clang is the
        # primary compiler on PATH for FHE program compilation.
        devShells.default = pkgs.mkShellNoCC {
          nativeBuildInputs = [ sunscreen-llvm-pkg ];

          buildInputs = with pkgs; [
            # Tex related packages
            texlive
            pandoc
            watchexec
            qrencode

            # Foundry related packages
            foundry-bin
            solc
          ];

          shellHook = ''
            export FONTCONFIG_FILE="${fonts}"
            export PATH="$PWD/scripts:$PATH"
            export CLANG=${sunscreen-llvm-pkg}/bin/clang
            export CLANG_DIR=${sunscreen-llvm-pkg}/bin
            echo "Pandoc presentation development environment"
            echo "Sunscreen clang available: $(clang --version | head -1)"
            echo ""
            echo "Available commands:"
            echo "  make               - Extract and compile C code"
            echo "  contracts build    - Extract and compile Solidity contracts"
            echo "  contracts test     - Extract and run contract tests"
            echo "  build-contracts    - Alias for 'contracts build'"
            echo "  test-contracts     - Alias for 'contracts test'"
            echo "  watch-presentation - Rebuild presentation on changes"
          '';
        };
      });
}
