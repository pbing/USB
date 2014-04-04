\ SwiftForth version
\ Implements the Chapter 9 enumeration commands of the Universal Bus
\ Specification Revision 2.0 for the J1 processor.

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
    0 usb-pending-address !  0 usb-address !
;

: usb-reset ( -- )
    default-state usb-state !
    0 usb-pending-address !  0 usb-address !
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

: receive-request ( -- )
    usb-c@ bmRequestType !  usb-c@ bRequest !
    usb-@ wValue !  usb-@ wIndex !  usb-@ wLength ! ;

\ returning handshakes
: handshake-ack   ( --)  ." ACK" ;
: handshake-nak   ( --)  ." NAK" ;
: handshake-stall ( --)  ." STALL" ;
: handshake-nyet  ( --)  ." NYET" ;

: 0-length-packet ( -- )          !usb-channel  ." 0-LENGTH-PACKET" ;
: 1-length-packet ( n -- )        !usb-channel  usb-c!  .usb-channel ;
: 2-length-packet ( n1 n2 -- )    !usb-channel  usb-!   .usb-channel ;
: data-packets    ( addr u -- )   !usb-channel  0 do  count usb-c!  loop  drop  .usb-channel ;

\ return the descriptor index
: descriptor-index ( -- index )   wValue @ lobyte ;

\ ======================================================================
\ CLEAR FEATURE
\ ======================================================================
\ not implemented

\ ======================================================================
\ GET CONFIGURATION
\ ======================================================================

: token-setup.get-configuration.device-to-host ( -- )
    ." device-to-host "
    address-state?  if                                                      0 1-length-packet  exit then
    config-state?   if configuration-descriptor 5 + ( bConfigurationValue) c@ 1-length-packet       then ;

: token-setup.get-configuration ( -- )
    ." get-configuration."
    device-to-host?  if  token-setup.get-configuration.device-to-host  exit then
    handshake-stall ;

\ ======================================================================
\ GET DESCRIPTOR
\ ======================================================================

: token-setup.get-descriptor.device-to-host ( -- )
    ." device-to-host( " wValue @ lohi . . ." ) "
    device?         descriptor-index 0=   and  if  device-descriptor   dup c@ wLength @ min  data-packets  exit then
    configuration?  descriptor-index 0=   and  if  configuration-descriptor  dup 2+ w@ ( wTotalLength) wLength @ min  data-packets  exit then
    string?         descriptor-index 0=   and  if  string-descriptor0  dup c@ wLength @ min  data-packets  exit then
    string?         descriptor-index 1 =  and  if  string-descriptor1  dup c@ wLength @ min  data-packets  exit then
    string?         descriptor-index 2 =  and  if  string-descriptor2  dup c@ wLength @ min  data-packets  exit then
    handshake-stall ;

: token-setup.get-descriptor ( -- )
    ." get-descriptor."
    device-to-host?  if  token-setup.get-descriptor.device-to-host  exit then
    handshake-stall ;

\ ======================================================================
\ GET INTERFACE
\ ======================================================================

: token-setup.get-interface.interface-to-host ( -- )
    ." interface-to-host "
    config-state?  wIndex @ 0=  and  if  0 1-length-packet  exit then
    handshake-stall ;

: token-setup.get-interface ( -- )
    ." get-interface."
    interface-to-host?  if  token-setup.get-interface.interface-to-host  exit then
    handshake-stall ;

\ ======================================================================
\ GET STATUS
\ ======================================================================

: token-setup.get-status.device-to-host ( -- )
    ." device-to-host "
    1 ( self-powered) 2-length-packet ;

: token-setup.get-status.interface/endpoint-to-host ( -- )
    address-state? invert  descriptor-index 0=  or  if  h# 0 2-length-packet  exit then
    handshake-stall ;

: token-setup.get-status ( -- )
    ." get-status."
    device-to-host?                          if  token-setup.get-status.device-to-host              exit then
    interface-to-host? endpoint-to-host? or  if  token-setup.get-status.interface/endpoint-to-host  exit then
    handshake-stall ;
    
\ ======================================================================
\ SET ADDRESS
\ ======================================================================

\ wValue=0 is not an error
: token-setup.set-address.host-to-device ( -- )
    ." host-to-device( " wValue ? ." ) "
    config-state? invert  if  wValue @   usb-pending-address !  0-length-packet  exit  then
    handshake-stall ;
    
: token-setup.set-address ( -- )
    ." set-address."
    host-to-device?  if  token-setup.set-address.host-to-device  exit then
    handshake-stall ;

\ ======================================================================
\ SET CONFIGURATION
\ ======================================================================

: valid-configuration?  ( n -- f )
    dup 0=  swap configuration-descriptor 5 + ( bConfigurationValue) c@ =  or ;

\ 0                  : enter address-state
\ bConfigurationValue: enter config state
\ else request error
: token-setup.set-configuration.host-to-device ( -- )
    ." host-to-device( " wValue @ lobyte . ." ) "
    wValue @ lobyte
    dup valid-configuration? invert  if  drop handshake-stall  exit then
    0= if  address-state usb-state !  else  config-state  usb-state !  then
    0-length-packet  ( configure device...) ;

: token-setup.set-configuration ( -- )
    ." set-configuration "
    host-to-device?  if  token-setup.set-configuration.host-to-device  exit then
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
    cr ." token-setup(wValue=" wValue ?  ." wLength=" wLength ?  ." )."
  \ clear-feature?      if  token-setup.clear-feature      exit then
    get-configuration?  if  token-setup.get-configuration  exit then
    get-descriptor?     if  token-setup.get-descriptor     exit then
    get-interface?      if  token-setup.get-interface      exit then
    get-status?         if  token-setup.get-status         exit then
    set-address?        if  token-setup.set-address        exit then
    set-configuration?  if  token-setup.set-configuration  exit then
  \ set-descriptor?     if  token-setup.set-descriptor     exit then
  \ set-feature?        if  token-setup.set-feature        exit then
  \ set-interface?      if  token-setup.set-interface      exit then
  \ synch-frame?        if  token-setup.synch-frame        exit then
    \ HID processing....
    handshake-stall ;


: device-response ( -- )
    !usb-channel
    receive-request
    token-setup ;