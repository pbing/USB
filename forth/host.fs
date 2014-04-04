\ Host Emulator
\ written in SwiftForth

: hibyte ( 16b -- hi )   8 rshift ;
: lobyte ( 16b -- lo )   $ff and ;
warning off \ redefine SwiftForth's words for 8/16 bit
: hilo ( 16b -- hi lo )   dup hibyte  swap lobyte ;
: lohi ( 16b -- lo hi )   dup lobyte  swap hibyte ;
: lohi-pack ( lo hi -- 16b )   8 lshift  swap or ; 
warning on

\ Emulate the USB transfer with a FIFO.
\ We can re-use it for host and device.
create usb-channel 1024 cells allot

variable >usb-channel

: !usb-channel ( -- )   usb-channel >usb-channel ! ;
!usb-channel

\ return number of entries
: #usb-channel ( -- u )   >usb-channel @  usb-channel -  cell/ ;

\ USB write
: usb-c! ( 8b  -- )   >usb-channel @ !  1 cells >usb-channel +! ;
: usb-!  ( 16b -- )   hilo  usb-c!  usb-c! ;

\ USB read
: usb-c@ ( -- 8b  )   >usb-channel @ @  1 cells >usb-channel +! ;
: usb-@  ( -- 16b )   usb-c@ usb-c@  8 lshift  or ;

\ debugging
: .usb-channel ( -- )
    base @ >r  hex
    usb-channel  #usb-channel 0  do  @+ s>d  <# # # #>  type space  loop  drop
    r> base ! ;

: create-device-request ( bmRequestType bRequest -- )
    create  swap , ,
  does> ( wValue wIndex wLength -- )
    !usb-channel
    @+ usb-c!  @ usb-c!
    rot usb-!  swap usb-! usb-! ;

\ Standard Device Requests
host-to-device     clear-feature      create-device-request host:clear-feature-device
host-to-interface  clear-feature      create-device-request host:clear-feature-interface
host-to-endpoint   clear-feature      create-device-request host:clear-feature-endpoint
device-to-host     get-configuration  create-device-request host:get-configuration
device-to-host     get-descriptor     create-device-request host:get-descriptor
interface-to-host  get-interface      create-device-request host:get-interface
device-to-host     get-status         create-device-request host:get-status-device
interface-to-host  get-status         create-device-request host:get-status-interface
endpoint-to-host   get-status         create-device-request host:get-status-endpoint
host-to-device     set-address        create-device-request host:set-address
host-to-device     set-configuration  create-device-request host:set-configuration
host-to-device     set-descriptor     create-device-request host:set-descriptor
host-to-device     set-feature        create-device-request host:set-feature-device
host-to-interface  set-feature        create-device-request host:set-feature-interface
host-to-endpoint   set-feature        create-device-request host:set-feature-endpoint
host-to-interface  set-interface      create-device-request host:set-interface
endpoint-to-host   synch-frame        create-device-request host:synch-frame
