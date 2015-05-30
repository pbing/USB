\ IN token processing

: copy-descriptor-to-ep0 ;

\ Process EP0 IN
: ep0-in ( -- )
    set-address?    if  0-length-packet  usb-pending-address @  io-usb-control !  exit then \ FIXME use io-usb-address
    get-descriptor? if  copy-descriptor-to-ep0                                         then ;

\ only EP0 is implemented
: token-in ( -- )   ep0-in ;

