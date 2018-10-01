# Create firmware

FORTH = /usr/local/opt/SwiftForth/bin/osx/sf
#FORTH = gforth -e

VPATH = ../J1_WB/j1_forth

SRC = crossj1.fs \
      basewords.fs \
      nuc.fs \
      main.fs

.PHONY: sim syn

j1.mif j1.lst: $(SRC) *.fs
	$(FORTH) main.fs

sim: j1.mif
	cp $^ ../sim

syn: j1.mif
	cp $^ ../syn
