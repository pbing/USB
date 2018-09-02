\ 4-digit HEX display

ROM
create hex-display-table
  $3f , $06 , $5b , $4f , $66 , $6d , $7d , $07 , \ 0 1 2 3 4 5 6 7
  $7f , $6f , $77 , $7c , $39 , $5e , $79 , $71 , \ 8 9 A b C d E F

\ convert number n to digit and display it at addr
: hex-display-digit! ( n addr -- ) >r cells hex-display-table + @ r> ! ;

\ use SW[0:3] in order to select different outputs
: hex-select ( -- )
  io-sw @ h# 1 and if
    \ SW[0]
    h# 0 io-hex0 hex-display-digit!
    h# 1 io-hex1 hex-display-digit!
    h# 2 io-hex2 hex-display-digit!
    h# 3 io-hex3 hex-display-digit!
  else  io-sw @ h# 2 and if
    \ SW[1]
    h# 4 io-hex0 hex-display-digit!
    h# 5 io-hex1 hex-display-digit!
    h# 6 io-hex2 hex-display-digit!
    h# 7 io-hex3 hex-display-digit!
  else  io-sw @ h# 4 and if
    \ SW[2]
    h# 8 io-hex0 hex-display-digit!
    h# 9 io-hex1 hex-display-digit!
    h# a io-hex2 hex-display-digit!
    h# b io-hex3 hex-display-digit!
  else  io-sw @ h# 8 and if
    \ SW[3]
    h# c io-hex0 hex-display-digit!
    h# d io-hex1 hex-display-digit!
    h# e io-hex2 hex-display-digit!
    h# f io-hex3 hex-display-digit!
  else
    \ SW[0:3] off
    h# 40 dup io-hex0 ! dup io-hex1 ! dup io-hex2 ! io-hex3 !
  then then then then ;
