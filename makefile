#!/usr/bin/make -f
#
# Makefile for LoROM template
# Copyright 2014-2015 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#

# These are used in the title of the SFC program and the zip file.
title = lorom-template
version = 0.06

# Space-separated list of asm files without .s extension
# (use a backslash to continue on the next line)
objlist = \
  snesheader init main

AS65 := ca65
LD65 := ld65
CFLAGS65 := -g
objdir := obj/snes
srcdir := src

ifdef COMSPEC
PY := py.exe
else
PY :=
endif

# Calculate the current directory as Wine applications would see it.
# yep, that's 8 backslashes.  Apparently, there are 3 layers of escaping:
# one for the shell that executes sed, one for sed, and one for the shell
# that executes wine
# TODO: convert to use winepath -w
wincwd := $(shell pwd | sed -e "s'/'\\\\\\\\'g")

# .PHONY means these targets aren't actual filenames
.PHONY: all run nocash-run spcrun dist clean

all: $(title).sfc

clean:
	-rm $(objdir)/*.o $(objdir)/*.chrsfc $(objdir)/*.chrgb
	-rm $(objdir)/*.wav $(objdir)/*.brr $(objdir)/*.s

$(objdir)/index.txt: makefile
	echo "Files produced by build tools go here. (This file's existence forces the unzip tool to create this folder.)" > $@

# Rules for ROM

objlisto = $(foreach o,$(objlist),$(objdir)/$(o).o)
objlistospc = $(foreach o,$(objlistspc),$(objdir)/$(o).o)

map.txt $(title).sfc: lorom256k.cfg $(objlisto)
	$(LD65) -o $(title).sfc --dbgfile $(title).dbg -m map.txt -C $^
	$(PY) tools/fixchecksum.py $(title).sfc

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/snes.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/mktables.s: tools/mktables.py
	$< > $@