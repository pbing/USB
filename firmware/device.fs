\ USB stack for device
\
\ Endpoints
\ ---------
\   0: control-in     0: control-out
\   1: interrupt-in   1: not implemented

URAM
variable token-pid
variable token-address
variable token-endpoint
variable token-crc

variable bmRequestType
Variable bRequest
variable wValue
variable wIndex
variable wLength

variable data-crc
variable data-pid

ROM

: set-pid ( pid -- )   txbuf-c! ;
: get-pid ( -- pid )   rxbuf-c@ ;

: set-zlp ( -- )   d# 0 txbuf-! ;
: get-zlp ( -- )   rxbuf-@ data-crc ! ;

: token-setup? ( -- f )   token-pid @ %setup = ;
: token-out?   ( -- f )   token-pid @ %out   = ;
: token-in?    ( -- f )   token-pid @ %in    = ;
: token-ack?   ( -- f )   token-pid @ %ack   = ;
: token-nak?   ( -- f )   token-pid @ %nak   = ;

: host-to-device?    ( -- f )   bmRequestType @ %host-to-device    = ;
: host-to-interface? ( -- f )   bmRequestType @ %host-to-interface = ;
: host-to-endpoint?  ( -- f )   bmRequestType @ %host-to-endpoint  = ;
: device-to-host?    ( -- f )   bmRequestType @ %device-to-host    = ;
: interface-to-host? ( -- f )   bmRequestType @ %interface-to-host = ;
: endpoint-to-host?  ( -- f )   bmRequestType @ %endpoint-to-host  = ;

: get-status?        ( -- f )   bRequest @  %get-status        = ;
: clear-feature?     ( -- f )   bRequest @  %clear-feature     = ;
: set-feature?       ( -- f )   bRequest @  %set-feature       = ;
: set-address?       ( -- f )   bRequest @  %set-address       = ;
: get-descriptor?    ( -- f )   bRequest @  %get-descriptor    = ;
: set-descriptor?    ( -- f )   bRequest @  %set-descriptor    = ;
: get-configuration? ( -- f )   bRequest @  %get-configuration = ;
: set-configuration? ( -- f )   bRequest @  %set-configuration = ;
: get-interface?     ( -- f )   bRequest @  %get-interface     = ;
: set-interface?     ( -- f )   bRequest @  %set-interface     = ;

\ ======================================================================
\ CRC-16 calculation
\ ======================================================================

: set-crc ( -- )  data-crc @ invert txbuf-! ;
: get-crc ( -- )  rxbuf-@  drop ;

\ initialize CRC
: /crc ( -- )   h# ffff data-crc ! ;

\ CRC-16 calculation step per bit
: (+crc) ( data crc -- data' crc' )
    2dup xor d# 1 and if        
        swap d# 1 rshift  swap d# 1 rshift  h# a001 xor
    else
        swap d# 1 rshift swap d# 1 rshift
    then ;

\ CRC-16 calculation step of one byte
: +crc ( data -- )
    data-crc @
    (+crc) (+crc) (+crc) (+crc) (+crc) (+crc) (+crc) (+crc)
    data-crc !  drop ;
    
\ ======================================================================
\ IN token processing
\ ======================================================================
URAM
variable epi0-address
variable epi0-length
variable epi0-pid
variable epi0-wbuff \ two byte output buffer

ROM
\ endpoint 0
: do-epi0 ( -- )
    epi0-pid @  set-pid
    /crc
    epi0-length @  d# 8 u> if
        epi0-address @  d# 8 d# 0 do  dup c@  dup txbuf-c! +crc  1+  loop  epi0-address !
        d# -8 epi0-length +!
    else
        epi0-length @ if
            epi0-address @  epi0-length @ d# 0 do  dup c@  dup txbuf-c! +crc  1+  loop  drop
            d# 0 epi0-length !
        then
    then
    set-crc
    epi0-pid @ %data0 = if  %data1  else  %data0  then  epi0-pid !
    txbuf-wait-empty
    get-pid ( ACK) drop ;

URAM
variable epi1-pid
variable >mouse-xy
variable mouse-ticker

ROM
\ table of x-y directions
create mouse-xy
    -4 , -4 ,
    -4 ,  0 ,
    -4 ,  4 ,
     0 ,  4 ,
     4 ,  4 ,
     4 ,  0 ,
     4 , -4 ,
     0 , -4 ,

\ initialize mouse emulation
: /mouse ( -- )
    d# 0 >mouse-xy !
    d# 0 mouse-ticker ! ;

\ advance mouse positions
: +mouse ( -- ypos xpos )
    d# 1 mouse-ticker +!
    mouse-ticker @ d# 14 u> if
        d# 0 mouse-ticker !
        >mouse-xy @  1+  h# 7 and  >mouse-xy !
    then
    >mouse-xy @  2* cells mouse-xy + 2@ ;

\ endpoint 1
: do-epi1 ( -- )
    epi1-pid @ set-pid
    /crc
    ( buttons) h# 0 dup txbuf-c! +crc
    +mouse
    ( x) dup txbuf-c! +crc
    ( y) dup txbuf-c! +crc
    set-crc
    epi1-pid @ %data0 = if  %data1  else  %data0  then  epi1-pid !
    txbuf-wait-empty
    get-pid ( ACK) drop ;

\ ======================================================================
\ OUT token processing
\ ======================================================================
\ ----------------------------------------------------------------------
\ GET STATUS (0)
\ ----------------------------------------------------------------------
: do-get-status ( -- )
    d# 2 epi0-length !  epi0-wbuff epi0-address !
    host-to-device?     if  h# 0  epi0-wbuff !  exit  then
    host-to-interface?  if  h# 0  epi0-wbuff !  exit  then
    host-to-endpoint?   if  h# 0  epi0-wbuff !  exit  then
    %ack set-pid ;

\ ----------------------------------------------------------------------
\ CLEAR FEATURE (1)
\ ----------------------------------------------------------------------
: do-clear-feature ( -- )   %ack set-pid ;

\ ----------------------------------------------------------------------
\ SET FEATURE (3)
\ ----------------------------------------------------------------------
: do-set-feature ( -- )   %ack set-pid ;

\ ----------------------------------------------------------------------
\ SET ADDRESS (5)
\ ----------------------------------------------------------------------
: do-set-address ( -- )   %ack set-pid ;

\ ----------------------------------------------------------------------
\ GET DESCRIPTOR (6)
\ ----------------------------------------------------------------------
: descriptor-to-ep0 ( dev-descr-addr length -- )
    wLength @ min epi0-length !  epi0-address !
    %ack set-pid ;

: do-get-device-descriptor        ( -- ) device-descriptor        dup c@                        descriptor-to-ep0 ;
: do-get-configuration-descriptor ( -- ) configuration-descriptor size-configuration-descriptor descriptor-to-ep0 ;
: do-get-string-descriptor0       ( -- ) string-descriptor0       dup c@                        descriptor-to-ep0 ;
: do-get-string-descriptor1       ( -- ) string-descriptor1       dup c@                        descriptor-to-ep0 ;
: do-get-string-descriptor2       ( -- ) string-descriptor2       dup c@                        descriptor-to-ep0 ;

: do-get-string-descriptor ( -- )   wValue @  h# 00ff and ( descriptor-index)
    dup 0=      if  drop do-get-string-descriptor0  exit then
    dup d# 1 =  if  drop do-get-string-descriptor1  exit then
    dup d# 2 =  if  drop do-get-string-descriptor2  exit then
    drop  %stall set-pid ;

: do-get-hid-descriptor ( -- )   hid-descriptor dup c@ descriptor-to-ep0 ;

: do-get-report-descriptor ( -- )   report-descriptor1 size-report-descriptor1 descriptor-to-ep0 ;

: do-get-descriptor ( -- )   wValue @  d# 8 rshift ( descriptor-type)
    dup %device        =  if  drop do-get-device-descriptor        exit  then
    dup %configuration =  if  drop do-get-configuration-descriptor exit  then
    dup %string        =  if  drop do-get-string-descriptor        exit  then
    dup %hid           =  if  drop do-get-hid-descriptor           exit  then
    dup %report        =  if  drop do-get-report-descriptor        exit  then
    %stall set-pid ;

\ ----------------------------------------------------------------------
\ SET DESCRIPTOR (7)
\ ----------------------------------------------------------------------
: do-set-descriptor ( -- )   %ack set-pid ;

\ ----------------------------------------------------------------------
\ GET CONFIGURATION (8)
\ ----------------------------------------------------------------------
: do-get-configuration ( -- )
    d# 1 epi0-length !  epi0-wbuff epi0-address !
    configuration-descriptor h# 5 + c@ ( bConfigurationValue) epi0-wbuff c!
    %ack set-pid ;

\ ----------------------------------------------------------------------
\ SET CONFIGURATION (9)
\ ----------------------------------------------------------------------
: do-set-configuration ( -- )
    %data0 epi1-pid !  \ IN response at endpoint 1 starts always with DATA0
    %ack set-pid ;

\ ----------------------------------------------------------------------
\ GET INTERFACE (10)
\ ----------------------------------------------------------------------
\ not implemented

\ ----------------------------------------------------------------------
\ SET INTERFACE (11)
\ ----------------------------------------------------------------------
: do-set-interface ( -- )   %ack set-pid ;

\ ----------------------------------------------------------------------
\ SYNCH FRAME (12)
\ ----------------------------------------------------------------------
\ not implemented

\ endpoint 0
\ default OUT response is zero-length package
: do-epo0 ( -- )
    get-pid ( DATA1) drop
    get-crc
    %ack set-pid ;

\ ======================================================================
\ SETUP token processing
\ ======================================================================

: do-setup ( -- )
    get-pid ( DATA0) data-pid ! \ don't care
    rxbuf-c@ bmRequestType !
    rxbuf-c@ bRequest !
    rxbuf-@  wValue !
    rxbuf-@  wIndex !
    rxbuf-@  wLength !
    rxbuf-@  data-crc !

    %data1 epi0-pid !  \ IN response starts always with DATA1
    d# 0 epi0-length ! \ default IN response is zero-length package

    get-status?         if  do-get-status         exit  then
    clear-feature?      if  do-clear-feature      exit  then
    set-feature?        if  do-set-feature        exit  then
    set-address?        if  do-set-address        exit  then
    get-descriptor?     if  do-get-descriptor     exit  then
    set-descriptor?     if  do-set-descriptor     exit  then
    get-configuration?  if  do-get-configuration  exit  then
    set-configuration?  if  do-set-configuration  exit  then
    set-interface?      if  do-set-interface      exit  then
    %ack set-pid ; \ always ACK

\ ======================================================================
\ main loop
\ ======================================================================

\ get token from input buffer
: get-token ( pid -- )
    rxbuf-c@ token-pid !
    rxbuf-@ dup h# 7f and  token-address !
    dup d# 7 rshift  h# 0f and  token-endpoint !
    d# 11 rshift  token-crc ! ;

\ process endpoint 0
: do-ep0 ( -- )
    token-setup?  if do-setup  exit  then
    token-out?    if do-epo0   exit  then
    token-in?     if do-epi0   exit  then ;

\ process endpoint 1
: do-ep1 ( -- )
    token-in?  if  do-epi1  exit  then ;

: do-transfer ( -- )
    get-token
    token-endpoint @  0=      if  do-ep0  exit  then
    token-endpoint @  d# 1 =  if  do-ep1  exit  then ;

DEBUG [IF]
    : .token ( -- )
        ." token-pid=0x" token-pid @ h.
        ." token-address=" token-address ?
        ." token-endpoint=" token-endpoint ?
        ." token-crc=0x" token-crc @ h. ;

    : .request ( -- )
        ." bmRequestType=0x" bmRequestType @ h.
        ." bRequest=0x" bRequest @ h.
        ." wValue=0x" wValue @ h.
        ." wIndex=" wIndex ?
        ." wLength=" wLength ?
        ." data-crc=0x" data-crc @ h. ;
[THEN]
