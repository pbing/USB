\ USB definitions

\ PID
$1 constant %out
$9 constant %in
$d constant %setup

\ request types
$00 constant host-to-device
$01 constant host-to-interface
$02 constant host-to-endpoint
$80 constant device-to-host
$81 constant interface-to-host
$82 constant endpoint-to-host

\ standard code requests
 0 constant get-status
 1 constant clear-feature
 3 constant set-feature
 5 constant set-address
 6 constant get-descriptor
 7 constant set-descriptor
 8 constant get-configuration
 9 constant set-configuration
10 constant get-interface
11 constant set-interface
12 constant synch-frame

\ descriptor types
1  constant %device
2  constant %configuration
3  constant %string
4  constant %interface
5  constant %endpoint
6  constant %device-qualifier
7  constant %other-speed-configuration
8  constant %interface-power
33 constant %hid
34 constant %report
35 constant %physical

\ standard feature selectors
0 constant endpoint-halt
1 constant device-remote-wakeup
2 constant test-mode