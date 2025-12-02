VERSION := $(shell cat VERSION 2>/dev/null || echo "dev")

CC ?= gcc
CFLAGS += -Wall -Wextra -Werror -Wpedantic -Wshadow -Wstrict-prototypes \
          -Wno-unused-function -std=c11 -Isrc/libs -DTRY_VERSION=\"$(VERSION)\"
LDFLAGS ?=

SRC_DIR = src
OBJ_DIR = obj
DIST_DIR = dist
BIN = $(DIST_DIR)/try

SRCS = $(wildcard $(SRC_DIR)/*.c)
OBJS = obj/commands.o obj/main.o obj/terminal.o obj/tui.o obj/utils.o obj/fuzzy.o obj/tokens.o

# Ragel-generated sources (tokens.c is checked in, ragel only needed for modifications)
RAGEL_SRCS = $(SRC_DIR)/tokens.c

all: $(BIN)

# Generate C from Ragel (only if .rl is newer than .c AND ragel is available)
# tokens.c is read-only to prevent accidental edits - modify tokens.rl instead
$(SRC_DIR)/tokens.c: $(SRC_DIR)/tokens.rl
	@if command -v ragel >/dev/null 2>&1; then \
		chmod +w $@ 2>/dev/null || true; \
		ragel -C -G2 $< -o $@; \
		chmod -w $@; \
		echo "Regenerated tokens.c from tokens.rl"; \
	else \
		echo "WARNING: ragel not installed. Using existing tokens.c"; \
		echo "         Install ragel if you need to modify tokens.rl"; \
		touch $@; \
	fi

$(BIN): $(OBJS) | $(DIST_DIR)
	$(CC) $(LDFLAGS) -o $@ $^ -lm

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

$(DIST_DIR):
	mkdir -p $(DIST_DIR)

clean:
	rm -rf $(OBJ_DIR) $(DIST_DIR)

# tokens.o depends on the generated tokens.c
# Ragel-generated code has intentional switch fallthrough and unused variables
$(OBJ_DIR)/tokens.o: $(SRC_DIR)/tokens.c | $(OBJ_DIR)
	$(CC) $(CFLAGS) -Wno-unused-const-variable -Wno-implicit-fallthrough -c -o $@ $<

install: $(BIN)
	install -m 755 $(BIN) /usr/local/bin/try

# Fetch specs (clones if needed, pulls latest, creates upstream symlink)
spec-update:
	@./spec/get_specs.sh

test-fast: $(BIN) spec-update
	@echo "Running spec tests..."
	spec/upstream/tests/runner.sh ./dist/try

test-valgrind: $(BIN) spec-update
	@echo "Running spec tests under valgrind..."
	spec/upstream/tests/runner.sh "valgrind -q --leak-check=full ./dist/try"

test-unit: $(OBJ_DIR)/tokens.o | $(DIST_DIR)
	@echo "Building and running unit tests..."
	$(CC) $(CFLAGS) -o $(DIST_DIR)/tokens_test src/tokens_test.c $(OBJ_DIR)/tokens.o
	$(DIST_DIR)/tokens_test

test: test-unit test-fast
	@command -v valgrind >/dev/null 2>&1 && $(MAKE) test-valgrind || echo "Skipping valgrind tests (valgrind not installed)"

# Update PKGBUILD and .SRCINFO with current VERSION
update-pkg:
	@sed -i 's/^pkgver=.*/pkgver=$(VERSION)/' PKGBUILD
	@makepkg --printsrcinfo > .SRCINFO
	@echo "Updated PKGBUILD and .SRCINFO to version $(VERSION)"

.PHONY: all clean install test test-fast test-valgrind test-unit spec-update update-pkg
