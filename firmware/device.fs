\ Implements the Chapter 9 enumeration commands of the Universal Bus
\ Specification Revision 2.0 for the J1 processor.

module[ device"

include io-addr.fs
include usb-defs.fs
include descriptors.fs

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

: usb-init  ( -- )
    powered-state usb-state !
    h# 0 usb-pending-address !  h# 0 io-usb-control !
;

: usb-reset ( -- )
    default-state usb-state !
    h# 0 usb-pending-address !  h# 0 io-usb-control !
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
: endp-c@ ( u -- 8b  )   2* cells io-endpo0-control +
    h# 2 over !          \ assign 1'b1 to io-endpo*-control.rdreq
    cell+ @ ;            \ read data from io-endpo*-data
: endp-@  ( u -- 16b )   dup endp-c@  swap endp-c@  lohi-pack ;

\ Write to endpoint fifo
: endp-c! ( 8b u --  )   2* cells io-endpi0-data +
    ! ;                  \ write data to io-endpi*-data
: endp-!  ( 16b u -- )   >r  hilo  r@ endp-c!  r> endp-c! ;

: clear-endp0 ( --     )   d# 0 clear-endp ;
: endp0-c@    ( -- 8b  )   d# 0 endp-c@ ;
: endp0-@     ( -- 16b )   d# 0 endp-@ ;
: endp0-c!    ( 8b --  )   d# 0 endp-c! ;
: endp0-!     ( 16b -- )   d# 0 endp-! ;

\ Discard CRC16 after every DATA0 or DATA1 from host.
: discard-crc ( -- )   endp0-@ 2drop ;

: handshake-stall ( -- )   h# 2 io-endpi0-control ! ;

\ zero-length-package from host
: zlp ( -- )   discard-crc ;

\ write IN transfer data to host
: 0-length-packet ( -- )
    h# 4 io-endpi0-control ! \ io-endpi0.zlp = 1'b1
    begin  io-usb-control @  d# 7 rshift  h# 2 = ( ACK)  until ;

: 1-length-packet ( n -- )        endp0-c! ;
: 2-length-packet ( n1 n2 -- )    endp0-! ;
: data-packets    ( addr u -- )   0do  count  endp0-c!  loop  drop  ;

    
\ return the descriptor index
: descriptor-index ( -- index )   wValue @ lobyte ;

include token-in.fs
include token-out.fs
include token-setup.fs


\ FIXME
: token@ ( -- n ) d# 0 ;
: token-done? ( -- f ) d# 0 ;
: usb-error? ( -- f ) d# 0 ;
: USBError ;

: token-done ( -- )
    token@
    dup %in  = if  token-in   exit  then
    dup %out = if  token-out  exit  then
    %setup   = if  token-setup      then ;

: service-usb ( -- )
    token-done? if  token-done  then
    usb-error?  if  USBError   then ;
]module
