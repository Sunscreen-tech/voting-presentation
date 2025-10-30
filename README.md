# Private Voting with FHE

[![C Compilation](https://github.com/sunscreen-tech/voting-presentation/actions/workflows/c-compilation.yml/badge.svg)](https://github.com/sunscreen-tech/voting-presentation/actions/workflows/c-compilation.yml)
[![Solidity Compilation](https://github.com/sunscreen-tech/voting-presentation/actions/workflows/solidity-compilation.yml/badge.svg)](https://github.com/sunscreen-tech/voting-presentation/actions/workflows/solidity-compilation.yml)
[![Presentation Build](https://github.com/sunscreen-tech/voting-presentation/actions/workflows/presentation-build.yml/badge.svg)](https://github.com/sunscreen-tech/voting-presentation/actions/workflows/presentation-build.yml)
[![Nix Flake](https://img.shields.io/badge/nix-flake-blue?logo=nixos)](https://nixos.org)

[![Download Presentation PDF](https://img.shields.io/badge/-Download%20Presentation%20PDF-blue)](https://sunscreen-tech.github.io/voting-presentation/presentation.pdf)
[![Download Handout PDF](https://img.shields.io/badge/-Download%20Handout%20PDF-blue)](https://sunscreen-tech.github.io/voting-presentation/presentation-handout.pdf)

Presentation about private voting using Fully Homomorphic Encryption. This project combines presentation slides with executable code examples, including FHE C programs and Solidity smart contracts.

## Prerequisites

Install Nix using the Determinate Nix installer:

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

## Building

Build the presentation PDFs:

```sh
nix build
```

Output is available in `./result/` with PDFs at:
- `result/presentation.pdf` - slide deck
- `result/presentation-handout.pdf` - handout version

## Development

Enter the development environment:

```sh
nix develop
```

The development shell includes Sunscreen's LLVM toolchain with clang for FHE compilation, Foundry for Solidity, and Pandoc with LaTeX for presentation building. Upon entering the shell, available commands are displayed.

Build manually:

```sh
build-presentation
```

Watch mode for live rebuilding:

```sh
watch-presentation
```

Built PDFs are placed in `build/`.

## Working with Code

The presentation contains executable FHE C programs and Solidity smart contracts. Code is automatically extracted from the presentation source and compiled.

### FHE Programs

Extract and compile C programs with the top-level Makefile:

```sh
make
```

This extracts C code from the presentation and compiles it using Sunscreen's LLVM toolchain targeting the parasol architecture. Compiled binaries are placed in `fhe-programs/compiled/`.

Individual targets:

```sh
make extract  # Extract C code only
make build    # Compile extracted code
make clean    # Remove build artifacts
```

### Solidity Contracts

Extract and build contracts:

```sh
contracts build     # Extract and compile with forge
contracts test      # Extract and test with forge
```

The `contracts` script extracts Solidity contracts from the presentation and compiles/tests them using Foundry. Compiled artifacts are placed in `build/foundry/`.
