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
$6000 constant io-txbuf-data
$6002 constant io-txbuf-control

$6004 constant io-rxbuf-data
$6006 constant io-rxbuf-control

: txbuf-wait-empty ( -- )   begin  io-txbuf-control @  h# 1 and  until ;
: txbuf-c! ( 8b -- )   io-txbuf-data ! ;
: txbuf-! ( 16b -- )   hilo txbuf-c! txbuf-c! ;

: rxbuf-c@ ( -- 8b )   begin  io-rxbuf-control @  h# 1 and  while repeat  io-rxbuf-data @ ;
: rxbuf-@ ( -- 16b )   rxbuf-c@ rxbuf-c@  lohi-pack ;

\ Receive ACK and return true.
\ If timeout return false.
: ack? ( -- f)
    d# 200 \ timeout counter (16..18 bit times)
    begin  io-rxbuf-control @  h# 1 and  while
            1-  dup 0=  if  exit  then
    repeat  drop
    io-rxbuf-data @  %ack = ;
