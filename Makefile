.PHONY: all extract build clean help

# Default target
all: extract build

# Extract C code from presentation when source changes
extract: src/presentation.md
	@echo "Extracting C code from presentation..."
	@./scripts/extract-code

# Compile C code
build: extract
	@echo "Compiling C code..."
	@$(MAKE) -C fhe-programs/src $(MAKEFLAGS)

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@$(MAKE) -C fhe-programs/src clean
	@rm -f fhe-programs/src/voting.c

# Display help
help:
	@echo "Available targets:"
	@echo "  all      - Extract and compile C code (default)"
	@echo "  extract  - Extract C code from presentation"
	@echo "  build    - Compile C code"
	@echo "  clean    - Clean build artifacts"
	@echo "  help     - Display this help message"
