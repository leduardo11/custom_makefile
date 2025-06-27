# -----------------------------------------------------------------------------
# Usage Guide (Makefile is self-contained)
# -----------------------------------------------------------------------------
# make                  - Build the project (default target, verbose debug build)
# make run              - Build quietly with debug flags and run
# make release          - Optimized release build (verbose)
# make debug            - Clean, verbose debug build, then run
# make clean            - Remove all build artifacts
# make info             - Print build configuration details
#
# Optional Library Flags:
#   USELIB_RAYLIB=1     - Enable raylib support
#   USELIB_SQLITE=1     - Enable SQLite support
#
# Examples:
#   make USELIB_RAYLIB=1
#   make release USELIB_SQLITE=1
# -----------------------------------------------------------------------------

# Default target
.DEFAULT_GOAL := all

# Project structure
PROJECT_NAME := c_course
SRC_DIR := src
OBJ_DIR := obj
BIN_DIR := bin
INCLUDE_DIR := include
ASSETS_DIR := resources

# Optional libraries (set to 1 to enable)
USELIB_RAYLIB := 0
USELIB_SQLITE := 0

# Toolchain
CXX := g++
CC := gcc
UNAME_S := $(shell uname)

# Standards and warnings
STD := -std=c++20
COMMON_WARNINGS := -Wall -Werror -Wextra -Wpedantic
DEBUG_FLAGS := -g $(COMMON_WARNINGS)
RELEASE_FLAGS := -O3 -DNDEBUG $(COMMON_WARNINGS)

# Platform-specific includes and libs
ifeq ($(UNAME_S),Darwin)
    PLATFORM_INCLUDES := -I/opt/homebrew/include
    PLATFORM_LIBS := -L/opt/homebrew/lib
    LDFLAGS_PLATFORM := -framework OpenGL -framework Cocoa -framework IOKit \
                        -framework CoreAudio -framework CoreVideo
else
    PLATFORM_INCLUDES := -I/usr/local/include
    PLATFORM_LIBS := -L/usr/local/lib
    LDFLAGS_PLATFORM := -lGL -lrt -lX11
endif

# Base includes
BASE_INCLUDES := -I$(INCLUDE_DIR) $(PLATFORM_INCLUDES)

# Final build flags
CXXFLAGS := $(DEBUG_FLAGS) $(STD) $(BASE_INCLUDES)
CFLAGS := $(DEBUG_FLAGS) -std=c11 $(BASE_INCLUDES)
CXXFLAGS_RELEASE := $(RELEASE_FLAGS) $(STD) $(BASE_INCLUDES)
CFLAGS_RELEASE := $(RELEASE_FLAGS) -std=c11 $(BASE_INCLUDES)

# Library flags (conditional)
LDFLAGS_LIBS :=
ifeq ($(USELIB_RAYLIB),1)
    CXXFLAGS += -DUSE_RAYLIB -I$(PLATFORM_INCLUDES)/raylib
    CFLAGS += -DUSE_RAYLIB -I$(PLATFORM_INCLUDES)/raylib
    LDFLAGS_LIBS += -lraylib
endif

ifeq ($(USELIB_SQLITE),1)
    CXXFLAGS += -DUSE_SQLITE
    CFLAGS += -DUSE_SQLITE
    LDFLAGS_LIBS += -lsqlite3
endif

# Final linker flags
LDFLAGS_COMMON := -lpthread -lm -ldl
LDFLAGS := $(PLATFORM_LIBS) $(LDFLAGS_LIBS) $(LDFLAGS_PLATFORM) $(LDFLAGS_COMMON)

# Sources and headers
CPP_SRC := $(wildcard $(SRC_DIR)/*.cpp)
C_SRC := $(wildcard $(SRC_DIR)/*.c)
SRC := $(CPP_SRC) $(C_SRC)
OBJ := $(patsubst $(SRC_DIR)/%.cpp, $(OBJ_DIR)/%.o, $(CPP_SRC)) \
       $(patsubst $(SRC_DIR)/%.c, $(OBJ_DIR)/%.o, $(C_SRC))
HEADERS := $(wildcard $(INCLUDE_DIR)/*.h)
OUT := $(BIN_DIR)/$(PROJECT_NAME)

# Entry point check
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

# Targets
.PHONY: all clean run release debug info

all: 
	@echo "=== Building (default target) with debug flags ==="
	@echo "CXXFLAGS: $(CXXFLAGS)"
	@echo "CFLAGS:   $(CFLAGS)"
	@echo "LDFLAGS:  $(LDFLAGS)"
	@$(MAKE) $(BIN_DIR) copy_assets $(OUT)

release: clean
	@echo "=== Building release version with optimized flags ==="
	@echo "CXXFLAGS: $(CXXFLAGS_RELEASE)"
	@echo "CFLAGS:   $(CFLAGS_RELEASE)"
	@echo "LDFLAGS:  $(LDFLAGS)"
	@$(MAKE) CXXFLAGS="$(CXXFLAGS_RELEASE)" CFLAGS="$(CFLAGS_RELEASE)" all

debug: clean
	@echo "=== Building debug version with debug flags ==="
	@echo "CXXFLAGS: $(CXXFLAGS)"
	@echo "CFLAGS:   $(CFLAGS)"
	@echo "LDFLAGS:  $(LDFLAGS)"
	@$(MAKE) all
	@$(MAKE) run

run: $(OUT)
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

