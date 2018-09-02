\ Implements the Chapter 9 enumeration commands of the Universal Bus
\ Specification Revision 2.0 for the J1 processor.

module[ device"

include io-addr.fs
include usb-defs.fs
include descriptors.fs

URAM
variable usb-state
0 constant powered-state
1 constant default-state
2 constant address-state
3 constant config-state

variable usb-pending-address

variable bmRequestType
Variable bRequest
variable wValue
variable wIndex
variable wLength

variable endp0-start
variable endp0-end
8 constant endp0-max-length

ROM
: usb-init  ( -- )
    powered-state usb-state !
    h# 0 usb-pending-address !  h# 0 io-usb-address !
;

: usb-reset ( -- )
    default-state usb-state !
    h# 0 usb-pending-address !  h# 0 io-usb-address !
;

: powered-state? ( -- f )  usb-state @ powered-state = ;
: default-state? ( -- f )  usb-state @ default-state = ;
: address-state? ( -- f )  usb-state @ address-state = ;
: config-state?  ( -- f )  usb-state @ config-state  = ;

: host-to-device?    ( -- f )   bmRequestType @  host-to-device    = ;
: host-to-interface? ( -- f )   bmRequestType @  host-to-interface = ;
: host-to-endpoint?  ( -- f )   bmRequestType @  host-to-endpoint  = ;
: device-to-host?    ( -- f )   bmRequestType @  device-to-host    = ;
: interface-to-host? ( -- f )   bmRequestType @  interface-to-host = ;
: endpoint-to-host?  ( -- f )   bmRequestType @  endpoint-to-host  = ;

: get-status?        ( -- f )   bRequest @  get-status        = ;
: clear-feature?     ( -- f )   bRequest @  clear-feature     = ;
: set-feature?       ( -- f )   bRequest @  set-feature       = ;
: set-address?       ( -- f )   bRequest @  set-address       = ;
: get-descriptor?    ( -- f )   bRequest @  get-descriptor    = ;
: set-descriptor?    ( -- f )   bRequest @  set-descriptor    = ;
: get-configuration? ( -- f )   bRequest @  get-configuration = ;
: set-configuration? ( -- f )   bRequest @  set-configuration = ;
: get-interface?     ( -- f )   bRequest @  get-interface     = ;
: set-interface?     ( -- f )   bRequest @  set-interface     = ;

: device?            ( -- f )   wValue @ hibyte  %device = ;
: configuration?     ( -- f )   wValue @ hibyte  %configuration = ;
: string?            ( -- f )   wValue @ hibyte  %string = ;

\ clear CRC (and possible garbage) from FIFO
: clear-endp  ( u -- )   2* cells io-endpo0-control +
    begin
	h# 2 over !      \ assign 1'b1 to io-endpo*-control.rdreq
	dup@  h# 1 and   \ wait for io-endpo*-control.empty == 1'b1
    until
    drop ;

\ Read from endpoint fifo
: endp-c@ ( u -- 8b  )   2* cells io-endpo0-data +  @ ;
: endp-@  ( u -- 16b )   dup endp-c@  swap endp-c@  lohi-pack ;

\ Write to endpoint fifo
: endp-c! ( 8b u --  )   2* cells io-endpi0-data +  ! ;
: endp-!  ( 16b u -- )   >r  hilo  r@ endp-c!  r> endp-c! ;

: clear-endp0 ( --     )   d# 0 clear-endp ;
: endp0-c@    ( -- 8b  )   d# 0 endp-c@ ;
: endp0-@     ( -- 16b )   d# 0 endp-@ ;
: endp0-c!    ( 8b --  )   d# 0 endp-c! ;
: endp0-!     ( 16b -- )   d# 0 endp-! ;

\ Discard CRC16 after every DATA0 or DATA1 from host.
: discard-crc ( -- )   endp0-@ 2drop ;

: handshake-stall ( -- )   h# 4 io-endpi0-control ! ;

\ zero-length-package from host
: zlp ( -- )   discard-crc ;

: acknowledge-packet0 ( -- )   h# 2 io-endpi0-control ! ;  \ io-endpi0.zlp = 1'b1 (FIXME also other endpoints)

: short-packet? ( -- f )   endp0-end @  endp0-start @  endp0-max-length +  u> invert ;

\ write IN transfer data to host
: copy-data-to-ep0 ( -- )
    endp0-start @
    begin  dup endp0-end @ u<  while  dup c@ endp0-c!  1+  repeat  drop
    acknowledge-packet0
    short-packet? if  d# -1 bRequest !  then \ Are we sending a short packet?
    ( DATA0/1 toggle... )
;
    
: 0-length-packet ( -- )          acknowledge-packet0 ;       \ (FIXME also other endpoints)
: 1-length-packet ( n -- )        endp0-c! acknowledge-packet0 ;
: 2-length-packet ( n1 n2 -- )    endp0-!  acknowledge-packet0 ;
: data-packets    ( addr u -- )   over + endp0-end !  endp0-start !  copy-data-to-ep0 ;

\ return the descriptor index
: descriptor-index ( -- index )   wValue @ lobyte ;

include token-in.fs
include token-out.fs
include token-setup.fs

\ check flags
: token-done?  ( -- f )   io-usb-status @  h#  1 and ;
: stall?       ( -- f )   io-usb-status @  h#  2 and ;
: usb-reset?   ( -- f )   io-usb-status @  h#  4 and ;
: error-pid?   ( -- f )   io-usb-status @  h#  8 and ;
: error-crc5?  ( -- f )   io-usb-status @  h# 10 and ;
: error-crc16? ( -- f )   io-usb-status @  h# 20 and ;
: error-bto?   ( -- f )   io-usb-status @  h# 40 and ;

\ clear flags
: /token-done  ( -- )   h#  1 io-usb-status ! ;
: /stall       ( -- )   h#  2 io-usb-status ! ;
: /usb-reset   ( -- )   h#  4 io-usb-status ! ;
: /error-pid   ( -- )   h#  8 io-usb-status ! ;
: /error-crc5  ( -- )   h# 10 io-usb-status ! ;
: /error-crc16 ( -- )   h# 20 io-usb-status ! ;
: /error-bto   ( -- )   h# 40 io-usb-status ! ;

: usb-error? ( -- f ) io-usb-status @  h# 78 and ;

\ for now just clear the flags
: /usb-error ( -- )
    h# 3 io-ledr !
    /error-pid
    /error-crc5
    /error-crc16
    /error-bto ;

: token@ ( -- n )   io-usb-token @  d# 4 rshift ;

: token-done ( -- )
    h# 2 io-ledr !
    /token-done
    token@
    dup h# 1 = if  token-out  exit  then
    dup h# 2 = if  token-in   exit  then
        h# 3 = if  token-setup      then ;

: service-usb ( -- )
    h# 1 io-ledr !
    token-done? if  token-done  then
    usb-error?  if  /usb-error  then ;
]module
