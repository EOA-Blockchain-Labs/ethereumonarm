SHELL := /bin/bash

# Find all subdirectories in the current directory recursively that contain a Makefiles
SUBDIRS := $(shell find . -mindepth 2 -type f -name "Makefile" -exec dirname {} \;)
L1CLIENTS := $(shell find l1-clients -mindepth 2 -type f -name "Makefile" -exec dirname {} \;)
L2CLIENTS := $(shell find l2-clients -mindepth 2 -type f -name "Makefile" -exec dirname {} \;)
UTILS := $(shell find utils -mindepth 2 -type f -name "Makefile" -exec dirname {} \;)
WEB3 := $(shell find web3 -mindepth 2 -type f -name "Makefile" -exec dirname {} \;)
INFRA := $(shell find infra -mindepth 2 -type f -name "Makefile" -exec dirname {} \;)

all:	
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir all || true; \
	done

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean || true; \
	done

l1-clients:

	for dir in $(L1CLIENTS); do \
		$(MAKE) -C $$dir all || true; \
	done
	
l2-clients:

	for dir in $(L2CLIENTS); do \
		$(MAKE) -C $$dir all || true; \
	done

web3:

	for dir in $(WEB3); do \
		$(MAKE) -C $$dir all || true; \
	done
infra:

	for dir in $(INFRA); do \
		$(MAKE) -C $$dir all || true; \
	done

utils:

	for dir in $(UTILS); do \
		$(MAKE) -C $$dir || true; \
	done
		

.PHONY: all clean l1-clients l2-clients infra utils web3