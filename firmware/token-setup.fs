\ SETUP token processing

\ ======================================================================
\ CLEAR FEATURE
\ ======================================================================
\ not implemented

\ ======================================================================
\ GET CONFIGURATION
\ ======================================================================

: token-setup/get-configuration/device-to-host ( -- )
    address-state?  if                                                      h# 0 1-length-packet ( data)  exit then
    config-state?   if configuration-descriptor h# 5 + ( bConfigurationValue) c@ 1-length-packet ( data)      then ;

: token-setup/get-configuration ( -- )
    device-to-host?  if  token-setup/get-configuration/device-to-host  exit then
    handshake-stall ;

\ ======================================================================
\ GET DESCRIPTOR
\ ======================================================================


: token-setup/get-descriptor/device-to-host ( -- )
   h# 302 io-ledr !
    device?         descriptor-index    0=   and  if  device-descriptor   dup c@  wLength @ min  data-packets ( data)   exit then
    configuration?  descriptor-index    0=   and  if  configuration-descriptor  dup h# 2 +  @ ( wTotalLength)  wLength @ min  data-packets ( data)   exit then
    string?         descriptor-index    0=   and  if  string-descriptor0  dup c@  wLength @ min  data-packets ( data)   exit then
    string?         descriptor-index h# 1 =  and  if  string-descriptor1  dup c@  wLength @ min  data-packets ( data)   exit then
    string?         descriptor-index h# 2 =  and  if  string-descriptor2  dup c@  wLength @ min  data-packets ( data)   exit then
    handshake-stall ;

: token-setup/get-descriptor ( -- )
    device-to-host?  if  token-setup/get-descriptor/device-to-host  exit then
    handshake-stall ;

\ ======================================================================
\ GET INTERFACE
\ ======================================================================

: token-setup/get-interface/interface-to-host ( -- )
    config-state?  wIndex @ 0=  and  if  h# 0 1-length-packet ( data)  exit then
    handshake-stall ;

: token-setup/get-interface ( -- )
    interface-to-host?  if  token-setup/get-interface/interface-to-host  exit then
    handshake-stall ;

\ ======================================================================
\ GET STATUS
\ ======================================================================

: token-setup/get-status/device-to-host ( -- )
    h# 1 ( self-powered) 2-length-packet zlp ;

: token-setup/get-status/interface/endpoint-to-host ( -- )
    address-state? invert  descriptor-index 0=  or  if  h# 0 2-length-packet ( data)  exit then
    handshake-stall ;

: token-setup/get-status ( -- )
    device-to-host?                          if  token-setup/get-status/device-to-host              exit then
    interface-to-host? endpoint-to-host? or  if  token-setup/get-status/interface/endpoint-to-host  exit then
    handshake-stall ;
    
\ ======================================================================
\ SET ADDRESS
\ ======================================================================

\ wValue = 0 is not an error
: token-setup/set-address/host-to-device ( -- )
    h# 304 io-ledr !
    config-state? invert  if  wValue @   usb-pending-address !  exit then
    handshake-stall ;
    
: token-setup/set-address ( -- )
    h# 303 io-ledr !
    host-to-device?  if  token-setup/set-address/host-to-device  exit then
    handshake-stall ;

\ ======================================================================
\ SET CONFIGURATION
\ ======================================================================

\ Configuration value n must be zero or match the configuration value
\ from the configuration descriptor.
: valid-configuration?  ( n -- f )
    dup 0=  swap configuration-descriptor h# 5 + ( bConfigurationValue) c@ =  or ;

\ 0                  : enter address-state
\ bConfigurationValue: enter config state
\ else request error
: token-setup/set-configuration/host-to-device ( -- )
    wValue @ lobyte
    dup valid-configuration? invert  if  drop handshake-stall  exit then
    0= if  address-state usb-state !  else  config-state  usb-state !  then
    zlp ( data) 0-length-packet ( status)
    ( configure device ...) ;

: token-setup/set-configuration ( -- )
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

: @request ( -- )
    h# 301 io-ledr !
    endp0-c@ bmRequestType !
    endp0-c@ bRequest !
    endp0-@  wValue !
    endp0-@  wIndex !
    endp0-@  wLength !
    discard-crc ; \ from SETUP/DATA0

: token-setup ( -- )
    h# 300 io-ledr !
    @request
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
