# FPGA USB 1.1, Low-Speed Implementation

Derived from an example [application](https://github.com/pbing/USB/tree/master/doc/Microchip) which emulates a mouse.
The cursor will move in a continual octagon.

## Status
- FPGA proven as additional mouse for Windows 10
- Does work with macOS yet.

## Installation
```shell
git clone https://github.com/pbing/USB.git
cd USB
git submodule update --init --recursive
```

## Used Parts
- [Cyclone V GX Starter Kit](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=167&No=830&PartNo=1)

- The USB D+ and D- pads were [configured](https://github.com/pbing/USB/blob/master/doc/USB%20Pad%20Configuration.pdf)
  for low-speed (1.5 Mbit/s).

## Other IP
- [J1 CPU with Wishbone interface](https://github.com/pbing/J1_WB)
