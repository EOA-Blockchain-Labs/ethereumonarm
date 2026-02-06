SHELL := /bin/bash

# ---------- COLORS ----------
GREEN  := \033[1;32m
RED    := \033[1;31m
BLUE   := \033[1;34m
YELLOW := \033[1;33m
RESET  := \033[0m

# ---------- EXCLUSIONS ----------
EXCLUDES := -not -path "./.git/*" \
            -not -path "*/.cache/*" \
            -not -path "*/.build/*" \
            -not -path "*/node_modules/*" \
            -not -path "./packages/*"

# ---------- FIND SUB-MAKEFILES ----------
L1CLIENTS := $(shell find l1-clients -mindepth 2 -type f -name "Makefile" $(EXCLUDES) -exec dirname {} \; | sort)
L2CLIENTS := $(shell find l2-clients -mindepth 2 -type f -name "Makefile" $(EXCLUDES) -exec dirname {} \; | sort)
UTILS     := $(shell find utils -mindepth 2 -type f -name "Makefile" $(EXCLUDES) -exec dirname {} \; | sort)
WEB3      := $(shell find web3 -mindepth 2 -type f -name "Makefile" $(EXCLUDES) -exec dirname {} \; | sort)
INFRA     := $(shell find infra -mindepth 2 -type f -name "Makefile" $(EXCLUDES) -exec dirname {} \; | sort)
SUBDIRS   := $(sort $(L1CLIENTS) $(L2CLIENTS) $(UTILS) $(WEB3) $(INFRA))

# ---------- DOCKER CONFIGURATION ----------
DOCKER_IMAGE := eoa-builder
DOCKER_PLATFORM := linux/arm64
PWD := $(shell pwd)

# Check if Docker image exists (returns non-empty if exists)
DOCKER_IMAGE_EXISTS := $(shell docker images -q $(DOCKER_IMAGE) 2>/dev/null)

# ---------- PHONY TARGETS ----------
.PHONY: default all clean l1-clients l2-clients infra utils web3 do-run summary lint test help
.PHONY: docker-image docker-shell ensure-docker-image check-qemu

# ---------- DEFAULT ----------
default: all

# ---------- DOCKER MANAGEMENT ----------
# Check for QEMU (needed for x86_64 hosts building ARM64)
check-qemu:
	@if [ "$$(uname -m)" = "x86_64" ]; then \
		if [ ! -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ] && [ ! -f /proc/sys/fs/binfmt_misc/aarch64 ]; then \
			echo "$(YELLOW)⚠️  Warning: Host is x86_64 but qemu-aarch64 binfmt seems missing.$(RESET)"; \
			echo "   Installing QEMU binfmt for ARM64 emulation..."; \
			docker run --privileged --rm tonistiigi/binfmt --install all || true; \
		fi \
	fi

# Build the Docker image
docker-image: check-qemu
	@echo "🐳 Building Docker image $(DOCKER_IMAGE) for $(DOCKER_PLATFORM)..."
	docker build --platform $(DOCKER_PLATFORM) -t $(DOCKER_IMAGE) .
	@echo "✅ Docker image $(DOCKER_IMAGE) built successfully."

# Ensure Docker image exists, build if not
ensure-docker-image:
	@if [ -z "$$(docker images -q $(DOCKER_IMAGE) 2>/dev/null)" ]; then \
		echo "$(YELLOW)🐳 Docker image '$(DOCKER_IMAGE)' not found. Building it now...$(RESET)"; \
		$(MAKE) docker-image; \
	fi

# Interactive shell inside the builder container
docker-shell: ensure-docker-image check-qemu
	@echo "🐳 Entering Docker shell..."
	docker run --rm -it --platform $(DOCKER_PLATFORM) -v "$(PWD)":/workspace $(DOCKER_IMAGE) bash

# ---------- WRAPPER TARGETS ----------
all: ensure-docker-image
	@$(MAKE) do-run DIRS_TO_RUN="$(SUBDIRS)" TARGET_TO_RUN="all" TARGET_NAME="all"

clean:
	@$(MAKE) do-run-local DIRS_TO_RUN="$(SUBDIRS)" TARGET_TO_RUN="clean" TARGET_NAME="clean"

l1-clients: ensure-docker-image
	@$(MAKE) do-run DIRS_TO_RUN="$(L1CLIENTS)" TARGET_TO_RUN="all" TARGET_NAME="l1-clients (all)"

l2-clients: ensure-docker-image
	@$(MAKE) do-run DIRS_TO_RUN="$(L2CLIENTS)" TARGET_TO_RUN="all" TARGET_NAME="l2-clients (all)"

web3: ensure-docker-image
	@$(MAKE) do-run DIRS_TO_RUN="$(WEB3)" TARGET_TO_RUN="all" TARGET_NAME="web3 (all)"

infra: ensure-docker-image
	@$(MAKE) do-run DIRS_TO_RUN="$(INFRA)" TARGET_TO_RUN="all" TARGET_NAME="infra (all)"

utils: ensure-docker-image
	@$(MAKE) do-run DIRS_TO_RUN="$(UTILS)" TARGET_TO_RUN="all" TARGET_NAME="utils (all)"

# ---------- DYNAMIC TARGETS ----------
# Allows running 'make <package_name>' (e.g., 'make geth', 'make prysm')
TARGETS := $(notdir $(SUBDIRS))
.PHONY: $(TARGETS)

$(TARGETS): ensure-docker-image
	@DIR=$$(echo "$(SUBDIRS)" | tr ' ' '\n' | grep "/$@$$" | head -n 1); \
	if [ -n "$$DIR" ]; then \
	    $(MAKE) do-run DIRS_TO_RUN="$$DIR" TARGET_TO_RUN="all" TARGET_NAME="$@"; \
	else \
	    echo "$(RED)❌ Error: Could not resolve target '$@' to a directory.$(RESET)"; \
	    exit 1; \
	fi

# ---------- MAIN EXECUTION (DOCKER) ----------
do-run: check-qemu
	@export LC_NUMERIC=C; \
	printf "\n🐳 $(BLUE)Running target '$(GREEN)$(TARGET_NAME)$(BLUE)' via Docker...$(RESET)\n\n"; \
	RESULT_FILE=$$(mktemp); \
	total_start=$$(date +%s.%N); \
	for dir in $(DIRS_TO_RUN); do \
	    start=$$(date +%s.%N); \
	    printf "📦 $(BLUE)Building$(RESET) %s (Target: $(GREEN)$(TARGET_TO_RUN)$(RESET))\n" "$$dir"; \
	    if docker run --rm --platform $(DOCKER_PLATFORM) \
	        -v "$(PWD)":/workspace -w /workspace \
	        -v /var/run/docker.sock:/var/run/docker.sock \
	        $(DOCKER_IMAGE) \
	        make -s -C "$$dir" $(TARGET_TO_RUN); then \
	        end=$$(date +%s.%N); \
	        elapsed=$$(printf "%.2f" $$(echo "$$end - $$start" | bc)); \
	        printf "   ✅ $(GREEN)Success$(RESET) (%s) — $(YELLOW)%ss$(RESET)\n\n" "$$dir" "$$elapsed"; \
	        echo "$$dir|SUCCESS|$$elapsed" >> "$$RESULT_FILE"; \
	    else \
	        end=$$(date +%s.%N); \
	        elapsed=$$(printf "%.2f" $$(echo "$$end - $$start" | bc)); \
	        printf "   ❌ $(RED)Error$(RESET) (%s) — $(YELLOW)%ss$(RESET)\n\n" "$$dir" "$$elapsed"; \
	        echo "$$dir|ERROR|$$elapsed" >> "$$RESULT_FILE"; \
	    fi; \
	done; \
	total_end=$$(date +%s.%N); \
	total_elapsed=$$(printf "%.2f" $$(echo "$$total_end - $$total_start" | bc)); \
	printf "⏱  $(BLUE)Total time: $(YELLOW)%ss$(RESET)\n\n" "$$total_elapsed"; \
	if [ -s "$$RESULT_FILE" ]; then \
	    printf "$(BLUE)────── SUMMARY ──────$(RESET)\n"; \
	    printf "%-65s %-10s %-10s\n" "Directory" "Result" "Time(s)"; \
	    printf "%-65s %-10s %-10s\n" "-----------------------------------------------------------------" "--------" "--------"; \
	    while IFS="|" read -r dir result time; do \
	        if [ "$$result" = "SUCCESS" ]; then color="$(GREEN)"; symbol="✅"; else color="$(RED)"; symbol="❌"; fi; \
	        printf "%-65s %-10b %-10s\n" "$$dir" "$$symbol $$color$$result$(RESET)" "$$time"; \
	    done < "$$RESULT_FILE"; \
	    printf "$(BLUE)──────────────────────$(RESET)\n"; \
	fi; \
	rm -f "$$RESULT_FILE"

# ---------- LOCAL EXECUTION (for clean, etc.) ----------
do-run-local:
	@printf "\n� $(BLUE)Running target '$(GREEN)$(TARGET_NAME)$(BLUE)' locally...$(RESET)\n\n"; \
	for dir in $(DIRS_TO_RUN); do \
	    printf "📦 $(BLUE)Entering$(RESET) %s (Target: $(GREEN)$(TARGET_TO_RUN)$(RESET))\n" "$$dir"; \
	    if $(MAKE) -s -C "$$dir" $(TARGET_TO_RUN); then \
	        printf "   ✅ $(GREEN)Success$(RESET) (%s)\n\n" "$$dir"; \
	    else \
	        printf "   ❌ $(RED)Error$(RESET) (%s)\n\n" "$$dir"; \
	    fi; \
	done

# ---------- SUMMARY ----------
summary:
	@printf "$(BLUE)────── SUMMARY ──────$(RESET)\n"; \
	printf "%-65s %-10s %-10s\n" "Directory" "Result" "Time(s)"; \
	printf "%-65s %-10s %-10s\n" "-----------------------------------------------------------------" "--------" "--------"; \
	[ ! -f "$(RESULT_FILE)" ] && { printf "$(RED)No results file found at $(RESULT_FILE)$(RESET)\n"; exit 1; }; \
	while IFS="|" read -r dir result time; do \
	    if [ "$$result" = "SUCCESS" ]; then color="$(GREEN)"; symbol="✅"; else color="$(RED)"; symbol="❌"; fi; \
	    printf "%-65s %-10b %-10s\n" "$$dir" "$$symbol $$color$$result$(RESET)" "$$time"; \
	done < "$(RESULT_FILE)"; \
	printf "$(BLUE)──────────────────────$(RESET)\n"

# ---------- LINT ----------
lint:
	@echo "🔎 Running shellcheck on shell scripts..."
	@if command -v shellcheck >/dev/null 2>&1; then \
	    find build-scripts -type f -name '*.sh' | xargs -r shellcheck -x -S warning && \
	    echo "✅ All scripts passed lint." || echo "❌ Lint issues found."; \
	else \
	    echo "❌ shellcheck not installed. Install with: apt install shellcheck"; \
	    exit 1; \
	fi

# ---------- TEST ----------
test: ensure-docker-image
	@$(MAKE) do-run DIRS_TO_RUN="$(SUBDIRS)" TARGET_TO_RUN="test" TARGET_NAME="test"

# ---------- HELP ----------
help:
	@printf "\n"
	@printf "  $(BLUE)Ethereum on ARM — Package Builder$(RESET)\n"
	@printf "\n"
	@printf "  Usage: make <target>\n"
	@printf "\n"
	@printf "  $(YELLOW)Note:$(RESET) All builds run inside Docker automatically.\n"
	@printf "         The Docker image will be built on first use if needed.\n"
	@printf "\n"
	@printf "  $(GREEN)Targets:$(RESET)\n"
	@echo "    all           Build all packages (default)"
	@echo "    clean         Clean all build artifacts"
	@echo "    test          Run tests for all packages"
	@echo "    l1-clients    Build L1 clients only"
	@echo "    l2-clients    Build L2 clients only"
	@echo "    infra         Build infrastructure packages only"
	@echo "    utils         Build utility packages only"
	@echo "    web3          Build web3 packages only"
	@echo "    lint          Run shellcheck on shell scripts"
	@echo "    docker-image  Rebuild the Docker builder image"
	@echo "    docker-shell  Enter interactive Docker shell"
	@echo "    help          Show this help message"
	@printf "\n"
	@printf "  $(GREEN)Package Targets:$(RESET)\n"
	@echo "    $(TARGETS)" | fold -s -w 70 | sed 's/^/    /'
	@printf "\n"
	@printf "  $(YELLOW)Subdirectories:$(RESET) $(words $(SUBDIRS)) packages found\n"
	@printf "\n"