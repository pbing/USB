# FPGA USB 1.1 Implementation

## Installation
```shell
git clone https://github.com/pbing/USB.git
cd USB
git submodule update --init --recursive
```

## Used Parts
- [Altera Cyclone II FPGA Starter Development Kit](http://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=53&No=83).

- The USB D+ and D- pads were [configured](https://github.com/pbing/USB/blob/master/doc/USB%20Pad%20Configuration.pdf)
  for low-speed (1.5 Mbit/s).

## Other IP
- [J1 CPU with Wishbone interface](https://github.com/pbing/J1_WB)
