\ 4-digit HEX display

create hex-display-table
  h# 3f , h# 06 , h# 5b , h# 4f , h# 66 , h# 6d , h# 7d , h# 07 , \ 0 1 2 3 4 5 6 7
  h# 7f , h# 6f , h# 77 , h# 7c , h# 39 , h# 5e , h# 79 , h# 71 , \ 8 9 A b C d E F

\ convert number n to digit and display it at addr
: hex-display-digit! ( n addr -- ) >r cells hex-display-table + @ r> ! ;

\ use SW[0:3] in order to select different outputs
: hex-select ( -- )
  io_sw @ h# 1 and if
    \ SW[0]
    h# 0 io_hex0 hex-display-digit!
    h# 1 io_hex1 hex-display-digit!
    h# 2 io_hex2 hex-display-digit!
    h# 3 io_hex3 hex-display-digit!
  else  io_sw @ h# 2 and if
    \ SW[1]
    h# 4 io_hex0 hex-display-digit!
    h# 5 io_hex1 hex-display-digit!
    h# 6 io_hex2 hex-display-digit!
    h# 7 io_hex3 hex-display-digit!
  else  io_sw @ h# 4 and if
    \ SW[2]
    h# 8 io_hex0 hex-display-digit!
    h# 9 io_hex1 hex-display-digit!
    h# a io_hex2 hex-display-digit!
    h# b io_hex3 hex-display-digit!
  else  io_sw @ h# 8 and if
    \ SW[3]
    h# c io_hex0 hex-display-digit!
    h# d io_hex1 hex-display-digit!
    h# e io_hex2 hex-display-digit!
    h# f io_hex3 hex-display-digit!
  else
    \ SW[0:3] off
    h# 40 dup io_hex0 ! dup io_hex1 ! dup io_hex2 ! io_hex3 !
  then then then then ;
