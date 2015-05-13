\ I/O addresses
\ same as in rtl/ioaddr.sv

\ LED
h# 4000 constant io-ledg
h# 4002 constant io-ledr

\ HEX display
h# 4010 constant io-hex0
h# 4012 constant io-hex1
h# 4014 constant io-hex2
h# 4016 constant io-hex3

\ keys and switches
h# 4020 constant io-key 
h# 4022 constant io-sw  

\ USB endpoints
h# 5000 constant io-endpi0-control
h# 5002 constant io-endpi0-data

h# 5004 constant io-endpi1-control
h# 5006 constant io-endpi1-data

h# 5040 constant io-endpo0-control
h# 5042 constant io-endpo0-data

h# 5100 constant io-usb-control
