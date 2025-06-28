# -----------------------------------------------------------------------------
# Usage Guide
# -----------------------------------------------------------------------------
# make                  - Build (default: debug build)
# make run              - Run the compiled binary
# make release          - Optimized release build (no ASan)
# make debug            - Clean, rebuild with debug flags, then run
# make clean            - Remove all build artifacts
# make info             - Show configuration
#
# Optional Flags:
#   USELIB_RAYLIB=1     - Enable raylib support
#   USELIB_SQLITE=1     - Enable SQLite support
# -----------------------------------------------------------------------------

.DEFAULT_GOAL := all

PROJECT_NAME := c_test
SRC_DIR := src
OBJ_DIR := obj
BIN_DIR := bin
INCLUDE_DIR := include
ASSETS_DIR := resources

USELIB_RAYLIB ?= 0
USELIB_SQLITE ?= 0

UNAME_S := $(shell uname)

# Toolchain selection and ASan enable flag
ifeq ($(UNAME_S),Darwin)
    CXX := clang++
    CC := clang
    USE_ASAN := 0    # Disable ASan on macOS to avoid linker issues
else
    CXX := g++
    CC := gcc
    USE_ASAN := 1    # Enable ASan on Linux by default
endif

# Standards and warnings
STD := -std=c++20
COMMON_WARNINGS := -Wall -Werror -Wextra -Wpedantic

# ASan flags
ASAN_FLAGS := -fsanitize=address -fno-omit-frame-pointer

# Debug and Release Flags
ifeq ($(USE_ASAN),1)
    DEBUG_FLAGS := -g $(COMMON_WARNINGS) $(ASAN_FLAGS)
else
    DEBUG_FLAGS := -g $(COMMON_WARNINGS)
endif

RELEASE_FLAGS := -O3 -DNDEBUG $(COMMON_WARNINGS)

# Platform-specific includes/libs
ifeq ($(UNAME_S),Darwin)
    PLATFORM_INCLUDES := -I/opt/homebrew/include
    PLATFORM_LIBS := -L/opt/homebrew/lib
    LDFLAGS_PLATFORM := -framework OpenGL -framework Cocoa -framework IOKit \
                        -framework CoreAudio -framework CoreVideo
    RAYLIB_INCLUDE := /opt/homebrew/include/raylib
else
    PLATFORM_INCLUDES := -I/usr/local/include
    PLATFORM_LIBS := -L/usr/local/lib
    LDFLAGS_PLATFORM := -lGL -lrt -lX11
    RAYLIB_INCLUDE := /usr/local/include/raylib
endif

BASE_INCLUDES := -I$(INCLUDE_DIR) $(PLATFORM_INCLUDES)

# Compiler flags
CXXFLAGS := $(DEBUG_FLAGS) $(STD) $(BASE_INCLUDES)
CFLAGS := $(DEBUG_FLAGS) -std=c11 $(BASE_INCLUDES)
CXXFLAGS_RELEASE := $(RELEASE_FLAGS) $(STD) $(BASE_INCLUDES)
CFLAGS_RELEASE := $(RELEASE_FLAGS) -std=c11 $(BASE_INCLUDES)

# Libraries to link
LDFLAGS_LIBS :=
ifeq ($(USELIB_RAYLIB),1)
    CXXFLAGS += -DUSE_RAYLIB -I$(RAYLIB_INCLUDE)
    CFLAGS += -DUSE_RAYLIB -I$(RAYLIB_INCLUDE)
    LDFLAGS_LIBS += -lraylib
endif

ifeq ($(USELIB_SQLITE),1)
    CXXFLAGS += -DUSE_SQLITE
    CFLAGS += -DUSE_SQLITE
    LDFLAGS_LIBS += -lsqlite3
endif

LDFLAGS := $(PLATFORM_LIBS) $(LDFLAGS_LIBS) $(LDFLAGS_PLATFORM) -lpthread -lm -ldl

# Source files
CPP_SRC := $(wildcard $(SRC_DIR)/*.cpp)
C_SRC := $(wildcard $(SRC_DIR)/*.c)
SRC := $(CPP_SRC) $(C_SRC)
OBJ := $(patsubst $(SRC_DIR)/%.cpp, $(OBJ_DIR)/%.o, $(CPP_SRC)) \
       $(patsubst $(SRC_DIR)/%.c, $(OBJ_DIR)/%.o, $(C_SRC))
HEADERS := $(wildcard $(INCLUDE_DIR)/*.h)
OUT := $(BIN_DIR)/$(PROJECT_NAME)

MAIN_SRC_C := $(wildcard $(SRC_DIR)/main.c)
MAIN_SRC_CPP := $(wildcard $(SRC_DIR)/main.cpp)

ifeq ($(strip $(MAIN_SRC_C)$(MAIN_SRC_CPP)),)
$(error No main.c or main.cpp file found in $(SRC_DIR))
endif
ifneq ($(strip $(MAIN_SRC_C)),)
ifneq ($(strip $(MAIN_SRC_CPP)),)
$(error Both main.c and main.cpp exist! Please keep only one.)
endif
LINKER := $(CC)
else
LINKER := $(CXX)
endif

.PHONY: all clean run release debug info copy_assets

all: $(BIN_DIR) copy_assets $(OUT)
	@echo "=== Build complete ==="
	@echo "Binary: $(OUT)"

release: clean
	@echo "=== Building release version ==="
	@$(MAKE) CXXFLAGS="$(CXXFLAGS_RELEASE)" CFLAGS="$(CFLAGS_RELEASE)" all

debug: clean
	@echo "=== Building debug version ==="
	@$(MAKE) all
	@$(MAKE) run

run: $(OUT)
	@echo "=== Running $(OUT) ==="
	@./$(OUT)

info:
	@echo "UNAME_S:        $(UNAME_S)"
	@echo "Sources:        $(SRC)"
	@echo "Objects:        $(OBJ)"
	@echo "Linker:         $(LINKER)"
	@echo "CXXFLAGS:       $(CXXFLAGS)"
	@echo "LDFLAGS:        $(LDFLAGS)"
	@echo "Raylib enabled: $(USELIB_RAYLIB)"
	@echo "SQLite enabled: $(USELIB_SQLITE)"

$(OUT): $(OBJ)
	$(LINKER) $(OBJ) -o $@ $(LDFLAGS)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp $(HEADERS) | $(OBJ_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c $(HEADERS) | $(OBJ_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BIN_DIR) $(OBJ_DIR):
	mkdir -p $@

copy_assets:
	@if [ -d "$(ASSETS_DIR)" ] && [ "$$(ls -A $(ASSETS_DIR) 2>/dev/null)" ]; then \
		cp -r $(ASSETS_DIR) $(BIN_DIR)/; \
	fi

clean:
	rm -rf $(BIN_DIR) $(OBJ_DIR)
