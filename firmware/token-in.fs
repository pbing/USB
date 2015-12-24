\ IN token processing

\ Process EP0 IN
: ep0-in ( -- )
    set-address?    if  0-length-packet  usb-pending-address @  io-usb-address !  exit then
    get-descriptor? if  copy-data-to-ep0                                               then ;

\ only EP0 is implemented
: token-in ( -- )
    h# 200 io-ledr !
    ep0-in ;

