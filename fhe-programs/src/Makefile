.PHONY: all clean

SOURCES := $(wildcard *.c)
BASENAMES := $(basename $(SOURCES))
EXECUTABLES := $(addprefix ../compiled/, $(BASENAMES))

# Use CLANG_DIR if specified, otherwise use clang from PATH
ifdef CLANG_DIR
CLANG := $(CLANG_DIR)/clang
else
CLANG := clang
endif

all: $(EXECUTABLES)

../compiled/%: %.c | ../compiled
	$(CLANG) -O2 -fno-builtin-memset -target parasol -o $@ $<

../compiled:
	mkdir -p $@

clean:
	$(RM) $(EXECUTABLES)
	$(RM) -r ../compiled
