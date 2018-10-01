\ Application
module[ application"

false constant DEBUG

include io-access.fs
include usb-defs.fs
include descriptors.fs
include device.fs

ROM
: main ( --)
    /mouse
    begin  do-transfer  again ;

]module
