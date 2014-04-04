# Create firmware

FORTH=~/SwiftForth/bin/osx/sf
#FORTH=gforth -e

j1.mif j1.lst: *.fs Makefile
	$(FORTH) main.fs

sim: j1.mif
	cp $< ../sim

syn: j1.mif
	cp $< ../syn
