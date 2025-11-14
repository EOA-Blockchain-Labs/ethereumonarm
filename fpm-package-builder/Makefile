SHELL := /bin/bash

# ---------- COLORS ----------
GREEN  := \033[1;32m
RED    := \033[1;31m
BLUE   := \033[1;34m
YELLOW := \033[1;33m
RESET  := \033[0m

# ---------- EXCLUSIONS ----------
# Excludes common directories from the search process
EXCLUDES := -not -path "./.git/*" \
            -not -path "*/.cache/*" \
            -not -path "*/.build/*" \
            -not -path "*/node_modules/*" \
            -not -path "./packages/*"

# ---------- FIND SUB-MAKEFILES ----------
# Define all directory groups. The 'find' commands start inside each
# group folder (e.g., 'find l1-clients ...') and use 'mindepth 2',
# which correctly skips the parent wrapper Makefiles (like 'l1-clients/Makefile').
L1CLIENTS := $(shell find l1-clients -mindepth 2 -type f -name "Makefile" $(EXCLUDES) -exec dirname {} \; | sort)
L2CLIENTS := $(shell find l2-clients -mindepth 2 -type f -name "Makefile" $(EXCLUDES) -exec dirname {} \; | sort)
UTILS     := $(shell find utils -mindepth 2 -type f -name "Makefile" $(EXCLUDES) -exec dirname {} \; | sort)
WEB3      := $(shell find web3 -mindepth 2 -type f -name "Makefile" $(EXCLUDES) -exec dirname {} \; | sort)
INFRA     := $(shell find infra -mindepth 2 -type f -name "Makefile" $(EXCLUDES) -exec dirname {} \; | sort)

# SUBDIRS is now the unique, sorted combination of all component groups.
# This avoids running 'make' in parent directories (like 'l1-clients')
# and only runs 'make' in the actual sub-project directories.
SUBDIRS   := $(sort $(L1CLIENTS) $(L2CLIENTS) $(UTILS) $(WEB3) $(INFRA))

# ---------- PHONY TARGETS ----------
.PHONY: default all clean l1-clients l2-clients infra utils web3 do-run summary

# ---------- DEFAULT ----------
default: all

# ---------- WRAPPER TARGETS ----------
# These are the main targets you call.
#   DIRS_TO_RUN:   The list of directories to operate on.
#   TARGET_TO_RUN: The make target (e.g., 'all', 'clean') to execute.
#   TARGET_NAME:   A friendly name for the console output.

all:
	@$(MAKE) do-run DIRS_TO_RUN="$(SUBDIRS)" TARGET_TO_RUN="all" TARGET_NAME="all"

clean:
	@$(MAKE) do-run DIRS_TO_RUN="$(SUBDIRS)" TARGET_TO_RUN="clean" TARGET_NAME="clean"

l1-clients:
	@$(MAKE) do-run DIRS_TO_RUN="$(L1CLIENTS)" TARGET_TO_RUN="all" TARGET_NAME="l1-clients (all)"

l2-clients:
	@$(MAKE) do-run DIRS_TO_RUN="$(L2CLIENTS)" TARGET_TO_RUN="all" TARGET_NAME="l2-clients (all)"

web3:
	@$(MAKE) do-run DIRS_TO_RUN="$(WEB3)" TARGET_TO_RUN="all" TARGET_NAME="web3 (all)"

infra:
	@$(MAKE) do-run DIRS_TO_RUN="$(INFRA)" TARGET_TO_RUN="all" TARGET_NAME="infra (all)"

utils:
	@$(MAKE) do-run DIRS_TO_RUN="$(UTILS)" TARGET_TO_RUN="all" TARGET_NAME="utils (all)"


# ---------- MAIN EXECUTION ----------
do-run:
	@RESULT_FILE=$$(mktemp /tmp/make_results_XXXXXX.txt); \
	printf "\n➜ $(BLUE)Running target '$(GREEN)$(TARGET_NAME)$(BLUE)' in selected subdirs...$(RESET)\n\n"; \
	total_start=$$(date +%s.%N); \
	for dir in $(DIRS_TO_RUN); do \
		start=$$(date +%s.%N); \
		printf "➜ $(BLUE)Entering$(RESET) %s (Target: $(GREEN)$(TARGET_TO_RUN)$(RESET))\n" "$$dir"; \
		if $(MAKE) -s -C "$$dir" $(TARGET_TO_RUN); then \
			end=$$(date +%s.%N); \
			elapsed=$$(printf "%.2f" $$(echo "$$end - $$start" | bc)); \
			printf "   $(GREEN)✔ Success$(RESET) (%s) — $(YELLOW)%ss$(RESET)\n\n" "$$dir" "$$elapsed"; \
			echo "$$dir|SUCCESS|$$elapsed" >> "$$RESULT_FILE"; \
		else \
			end=$$(date +%s.%N); \
			elapsed=$$(printf "%.2f" $$(echo "$$end - $$start" | bc)); \
			printf "   $(RED)✖ Error$(RESET) (%s) — $(YELLOW)%ss$(RESET)\n\n" "$$dir" "$$elapsed"; \
			echo "$$dir|ERROR|$$elapsed" >> "$$RESULT_FILE"; \
		fi; \
	done; \
	total_end=$$(date +%s.%N); \
	total_elapsed=$$(printf "%.2f" $$(echo "$$total_end - $$total_start" | bc)); \
	printf "⏱  $(BLUE)Total time: $(YELLOW)%ss$(RESET)\n\n" "$$total_elapsed"; \
	$(MAKE) summary RESULT_FILE="$$RESULT_FILE"; \
	rm -f "$$RESULT_FILE"; # Clean up the temporary file

# ---------- SUMMARY ----------
summary:
	@printf "$(BLUE)────── SUMMARY ──────$(RESET)\n"; \
	printf "%-65s %-10s %-10s\n" "Directory" "Result" "Time(s)"; \
	printf "%-65s %-10s %-10s\n" "-----------------------------------------------------------------" "--------" "--------"; \
	[ ! -f "$(RESULT_FILE)" ] && { printf "$(RED)No results file found at $(RESULT_FILE)$(RESET)\n"; exit 1; }; \
	while IFS="|" read -r dir result time; do \
		if [ "$$result" = "SUCCESS" ]; then color="$(GREEN)"; else color="$(RED)"; fi; \
		printf "%-65s %-10b %-10s\n" "$$dir" "$$color$$result$(RESET)" "$$time"; \
	done < "$(RESULT_FILE)"; \
	printf "$(BLUE)──────────────────────$(RESET)\n"