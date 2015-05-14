# Create firmware

FORTH=~/SwiftForth/bin/osx/sf
#FORTH=gforth -e

J1=../../J1

CORE=crossj1.fs basewords.fs nuc.fs

.PHONY: sim syn

j1.mif j1.lst: $(CORE) *.fs Makefile
	$(FORTH) main.fs

sim: j1.mif
	cp $< ../sim

syn: j1.mif
	cp $< ../syn

crossj1.fs: $(J1)/src/crossj1.fs
	cp $< $@

basewords.fs: $(J1)/src/basewords.fs
	cp $< $@

nuc.fs: $(J1)/src/nuc.fs
	cp $< $@
