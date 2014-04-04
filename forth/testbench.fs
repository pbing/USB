\ Testbench
forth definitions

include usb-defs.fs
include host.fs
include descriptors.fs
include device.fs

decimal

: tb-001 ( -- )
    %device 8 lshift  0 8 host:get-descriptor
    device-response
;


\ USB Complete The Devolpers Guide, 4th edition, p.91
: tb-002 ( -- )
    5 0 0 host:set-address
    device-response

    0 %device lohi-pack  0 18 host:get-descriptor
    device-response

    0 %configuration lohi-pack  0 9 host:get-descriptor
    device-response

    0 %configuration lohi-pack  0 34 host:get-descriptor
    device-response

    0 %string lohi-pack  0 4 host:get-descriptor
    device-response

    2 %string lohi-pack 0 92 host:get-descriptor
    device-response

    0 0 2 host:get-status-device
    device-response

    1 0 0 host:set-configuration
    device-response
;
