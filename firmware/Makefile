# Create firmware

FORTH=~/SwiftForth/bin/linux/sf
#FORTH=gforth -e

J1=../../J1

.PHONY: sim syn init

j1.mif j1.lst: *.fs Makefile
	$(FORTH) main.fs

sim: j1.mif
	cp $< ../sim

syn: j1.mif
	cp $< ../syn

init: crossj1.fs basewords.fs nuc.fs

crossj1.fs: $(J1)/src/crossj1.fs
	cp $< $@

basewords.fs: $(J1)/src/basewords.fs
	cp $< $@

nuc.fs: $(J1)/src/nuc.fs
	cp $< $@
