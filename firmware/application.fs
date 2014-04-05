\ Application
module[ application"

include device.fs
include hex-display.fs
include led.fs

: wait      ( u -- ) 0do loop ;
: wait-1000 ( u -- ) 0do d# 1000 wait loop ;

: main ( --)
  d# 1
  begin
    hex-select
    led-walk
    d# 100 wait-1000
  again ;

]module
