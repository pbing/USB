\ I/O addresses
\ same as in rtl/ioaddr.sv

\ LED
$5000 constant io-ledg
$5002 constant io-ledr

\ HEX display
$5010 constant io-hex0
$5012 constant io-hex1
$5014 constant io-hex2
$5016 constant io-hex3

\ keys and switches
$5020 constant io-key 
$5022 constant io-sw  

\ USB endpoints and control registers
$6000 constant io-endpi0-control
$6002 constant io-endpi0-data

$6004 constant io-endpi1-control
$6006 constant io-endpi1-data

$6040 constant io-endpo0-control
$6042 constant io-endpo0-data

$6100 constant io-usb-address
$6102 constant io-usb-token
$6104 constant io-usb-status
