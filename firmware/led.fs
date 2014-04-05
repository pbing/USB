\ Walking one through both LED arrays

\ rotate 1 bit circular
: rotate ( u1 -- u2) dup 0< if d# 15 rshift else d# 1 lshift then ;

\ bit [7:0] LEDR, bit [15:6] LEDR
: led! ( u -- )
  dup io-ledg !  d# 6 rshift io-ledr ! ;

\ diplay LED arrays and rotate
: led-walk ( u1 -- u2 )
  dup led!  rotate ;
