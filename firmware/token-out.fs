\ OUT token processing

\ no OUT token in this application
: token-out ( -- )
    h# 100 io-ledr !
;

