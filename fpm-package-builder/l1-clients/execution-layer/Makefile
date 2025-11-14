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
            -not -path "*/node_modules/*"

# ---------- FIND SUB-MAKEFILES ----------
SUBDIRS := $(shell find . -mindepth 2 -type f -name "Makefile" $(EXCLUDES) -exec dirname {} \; | sort)

.PHONY: default all clean %

# ---------- DEFAULT ----------
default: all

# ---------- WRAPPER TARGETS ----------
all clean:
	@$(MAKE) do-run TARGET=$@

%:
	@$(MAKE) do-run TARGET=$@

# ---------- MAIN EXECUTION ----------
do-run:
	@RESULT_FILE=$$(mktemp /tmp/make_results_XXXXXX.txt); \
	echo "$$RESULT_FILE" > /tmp/current_results_file; \
	printf "\n➜ $(BLUE)Running target '$(GREEN)$(TARGET)$(BLUE)' in all subdirs...$(RESET)\n\n"; \
	total_start=$$(date +%s.%N); \
	for dir in $(SUBDIRS); do \
		start=$$(date +%s.%N); \
		printf "➜ $(BLUE)Entering$(RESET) %s\n" "$$dir"; \
		if $(MAKE) -s -C "$$dir" $(TARGET); then \
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
	printf "⏱  $(BLUE)Total time: $(YELLOW)%ss$(RESET)\n\n" "$$total_elapsed"

	@$(MAKE) summary

# ---------- SUMMARY ----------
summary:
	@RESULT_FILE=$$(cat /tmp/current_results_file); \
	printf "$(BLUE)────── SUMMARY ──────$(RESET)\n"; \
	printf "%-40s %-10s %-10s\n" "Directory" "Result" "Time(s)"; \
	printf "%-40s %-10s %-10s\n" "----------------------------------------" "--------" "--------"; \
	while IFS="|" read -r dir result time; do \
		if [ "$$result" = "SUCCESS" ]; then color="$(GREEN)"; else color="$(RED)"; fi; \
		printf "%-40s %-10b %-10s\n" "$$dir" "$$color$$result$(RESET)" "$$time"; \
	done < "$$RESULT_FILE"; \
	printf "$(BLUE)──────────────────────$(RESET)\n"