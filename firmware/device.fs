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
variable usb-address

variable bmRequestType
Variable bRequest
variable wValue
variable wIndex
variable wLength

: usb-init  ( -- )
    powered-state usb-state !
    h# 0 usb-pending-address !  h# 0 usb-address !
;

: usb-reset ( -- )
    default-state usb-state !
    h# 0 usb-pending-address !  h# 0 usb-address !
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

\ Read from endpoint fifo
: endp-c@ ( u -- 8b  )   2* cells io-endpo0-control +
    begin  dup @  h# 1 and  while repeat \ wait for io-endpo*.empty == 1'b0
    h# 2 over !                          \ assign 1'b1 to io-endpo*-control.rdreq
    cell+ @ ;                            \ read data from io-endpo*-data
: endp-@  ( u -- 16b )   dup endp-c@  swap endp-c@  lohi-pack ;

\ Write to endpoint fifo
: endp-c! ( 8b u --  )   2* cells io-endpi0-control +
    begin  dup @  h# 1 and  while repeat \ wait for io-endpi*-control.full == 1'b0
    cell+ ! ;                            \ write data to io-endpi*-data
: endp-!  ( 16b u -- )   >r  hilo  r@ endp-c!  r> endp-c! ;

: endp0-c@ ( -- 8b  )   d# 0 endp-c@ ;
: endp0-@  ( -- 16b )   d# 0 endp-@ ;
: endp0-c! ( 8b --  )   d# 0 endp-c! ;
: endp0-!  ( 16b -- )   d# 0 endp-! ;

: receive-request ( -- )
    h# 100 io-ledr !
    endp0-c@ bmRequestType !  endp0-c@ bRequest !
    endp0-@ wValue !  endp0-@ wIndex !  endp0-@ wLength !
    endp0-@ ( crc16) 2drop ;

\ returning handshakes
: handshake-stall ( -- )   h# 2 io-endpi0-control ! ;

\ FIXME
: 0-length-packet ( -- )          ;
: 1-length-packet ( n -- )         endp0-c! ;
: 2-length-packet ( n1 n2 -- )     endp0-!  ;
: data-packets    ( addr u -- )    0do  count  endp0-c!  loop  drop ;

\ return the descriptor index
: descriptor-index ( -- index )   wValue @ lobyte ;

\ ======================================================================
\ CLEAR FEATURE
\ ======================================================================
\ not implemented

\ ======================================================================
\ GET CONFIGURATION
\ ======================================================================

: token-setup/get-configuration/device-to-host ( -- )
    h# 11 io-ledr !
    address-state?  if                                                      h# 0 1-length-packet  exit then
    config-state?   if configuration-descriptor h# 5 + ( bConfigurationValue) c@ 1-length-packet       then ;

: token-setup/get-configuration ( -- )
    h# 10 io-ledr !
    device-to-host?  if  token-setup/get-configuration/device-to-host  exit then
    handshake-stall ;

\ ======================================================================
\ GET DESCRIPTOR
\ ======================================================================

: token-setup/get-descriptor/device-to-host ( -- )
    h# 21 io-ledr !
    device?         descriptor-index    0=   and  if  h# 210 io-ledr ! device-descriptor   dup c@ wLength @ min  data-packets  exit then
    configuration?  descriptor-index    0=   and  if  h# 211 io-ledr ! configuration-descriptor  dup h# 2 +  @ ( wTotalLength) wLength @ min  data-packets  exit then
    string?         descriptor-index    0=   and  if  h# 212 io-ledr ! string-descriptor0  dup c@ wLength @ min  data-packets  exit then
    string?         descriptor-index h# 1 =  and  if  h# 213 io-ledr ! string-descriptor1  dup c@ wLength @ min  data-packets  exit then
    string?         descriptor-index h# 2 =  and  if  h# 214 io-ledr ! string-descriptor2  dup c@ wLength @ min  data-packets  exit then
    handshake-stall ;

: token-setup/get-descriptor ( -- )
    h# 20 io-ledr !
    device-to-host?  if  token-setup/get-descriptor/device-to-host  exit then
    handshake-stall ;

\ ======================================================================
\ GET INTERFACE
\ ======================================================================

: token-setup/get-interface/interface-to-host ( -- )
    h# 31 io-ledr !
    config-state?  wIndex @ 0=  and  if  h# 0 1-length-packet  exit then
    handshake-stall ;

: token-setup/get-interface ( -- )
    h# 30 io-ledr !
    interface-to-host?  if  token-setup/get-interface/interface-to-host  exit then
    handshake-stall ;

\ ======================================================================
\ GET STATUS
\ ======================================================================

: token-setup/get-status/device-to-host ( -- )
    h# 42 io-ledr !
    h# 1 ( self-powered) 2-length-packet ;

: token-setup/get-status/interface/endpoint-to-host ( -- )
    h# 41 io-ledr !
    address-state? invert  descriptor-index 0=  or  if  h# 0 2-length-packet  exit then
    handshake-stall ;

: token-setup/get-status ( -- )
    h# 40 io-ledr !
    device-to-host?                          if  token-setup/get-status/device-to-host              exit then
    interface-to-host? endpoint-to-host? or  if  token-setup/get-status/interface/endpoint-to-host  exit then
    handshake-stall ;
    
\ ======================================================================
\ SET ADDRESS
\ ======================================================================

\ wValue=0 is not an error
: token-setup/set-address/host-to-device ( -- )
    h# 51 io-ledr !
    config-state? invert  if  wValue @   usb-pending-address !  0-length-packet  exit  then
    handshake-stall ;
    
: token-setup/set-address ( -- )
    h# 50 io-ledr !
    host-to-device?  if  token-setup/set-address/host-to-device  exit then
    handshake-stall ;

\ ======================================================================
\ SET CONFIGURATION
\ ======================================================================

: valid-configuration?  ( n -- f )
    h# 62 io-ledr !
    dup 0=  swap configuration-descriptor h# 5 + ( bConfigurationValue) c@ =  or ;

\ 0                  : enter address-state
\ bConfigurationValue: enter config state
\ else request error
: token-setup/set-configuration/host-to-device ( -- )
    h# 61 io-ledr !
    wValue @ lobyte
    dup valid-configuration? invert  if  drop handshake-stall  exit then
    0= if  address-state usb-state !  else  config-state  usb-state !  then
    0-length-packet  ( configure device...) ;

: token-setup/set-configuration ( -- )
    h# 60 io-ledr !
    host-to-device?  if  token-setup/set-configuration/host-to-device  exit then
    handshake-stall ;

\ ======================================================================
\ SET DESCRIPTOR
\ ======================================================================
\ not implemented

\ ======================================================================
\ SET FEATURE
\ ======================================================================
\ not implemented

\ ======================================================================
\ SET INTERFACE
\ ======================================================================
\ not implemented

\ ======================================================================
\ SYNCH FRAME
\ ======================================================================
\ not implemented

\ ======================================================================

: token-setup ( -- )
  \ clear-feature?      if  token-setup/clear-feature      exit then
    get-configuration?  if  token-setup/get-configuration  exit then
    get-descriptor?     if  token-setup/get-descriptor     exit then
    get-interface?      if  token-setup/get-interface      exit then
    get-status?         if  token-setup/get-status         exit then
    set-address?        if  token-setup/set-address        exit then
    set-configuration?  if  token-setup/set-configuration  exit then
  \ set-descriptor?     if  token-setup/set-descriptor     exit then
  \ set-feature?        if  token-setup/set-feature        exit then
  \ set-interface?      if  token-setup/set-interface      exit then
  \ synch-frame?        if  token-setup/synch-frame        exit then
    \ HID processing....
    handshake-stall ;


: device-response ( -- )
\    !usb-channel
    receive-request
    token-setup ;

]module
