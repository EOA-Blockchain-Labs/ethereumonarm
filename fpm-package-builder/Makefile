SHELL := /bin/bash
SUBDIRS := $(wildcard */.)
all: prepare deb clean

prepare: ## Donwload the latest binary and prepare the package files
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir prepare; \
	done

deb: ## Create deb package
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir deb; \
	done

.PHONY: clean
clean: ## Clean up
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done
