\ OUT token processing

ROM
\ no OUT token in this application
: token-out ( -- )
    h# 100 io-ledr !
;

