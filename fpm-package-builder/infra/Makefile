# ======================================================================
# Passthrough Makefile — Forwards targets to all subdirectories
# ======================================================================
# This is a simple dispatcher for local debugging inside the container.
# For normal builds, use the root Makefile: make <package-name>
# ======================================================================

SHELL := /bin/bash
SUBDIRS := $(shell find . -mindepth 2 -type f -name "Makefile" \
    -not -path "*/.git/*" \
    -not -path "*/.cache/*" \
    -not -path "*/.build/*" \
    -exec dirname {} \; | sort)

.PHONY: all clean $(SUBDIRS)

all clean:
	@for dir in $(SUBDIRS); do \
	    echo "📦 Running $@ in $$dir"; \
	    $(MAKE) -C "$$dir" $@ || exit 1; \
	done

%:
	@for dir in $(SUBDIRS); do \
	    $(MAKE) -C "$$dir" $@ || exit 1; \
	done