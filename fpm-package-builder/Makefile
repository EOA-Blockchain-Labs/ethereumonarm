SHELL := /bin/bash

# Find all subdirectories in the current directory recursively that contain a Makefiles
SUBDIRS := $(shell find . -mindepth 2 -type f -name "Makefile" -exec dirname {} \;)

# Define the default target 'all', which depends on 'prepare', 'deb', and 'clean'
all: prepare deb clean

# Define the 'prepare' target, which downloads the latest binary and prepares package files
prepare:
# Loop over all subdirectories and execute 'make prepare' if a Makefile exists in that directory
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir prepare; \
	done

# Define the 'deb' target, which creates a Debian package
deb:
# Loop over all subdirectories and execute 'make deb' if a Makefile exists in that directory
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir deb; \
	done

# Define the 'clean' target, which cleans up any temporary files
clean:
# Loop over all subdirectories and execute 'make clean' if a Makefile exists in that directory
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done

# Mark the 'clean' target as a phony target, since it doesn't produce an output file
.PHONY: cleans