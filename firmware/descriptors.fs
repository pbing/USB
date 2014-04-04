\ Descriptors

create report-descriptor1
    $05 c, $01 c, \ usage page (generic desktop)
    $09 c, $02 c, \ usage mouse
    $a1 c, $01 c, \ collection (application)
    $09 c, $01 c, \ usage (pointer)
    $a1 c, $00 c, \ collection (physical)

    $05 c, $09 c, \ usage page (buttons)
    $19 c, $01 c, \ usage minimum (1)
    $29 c, $03 c, \ usage maximum (3)
    $15 c, $00 c, \ logical minimum (0)
    $25 c, $01 c, \ logical maximum (1)
    $95 c, $03 c, \ report count (3)
    $75 c, $01 c, \ report size (1 bit)
    $81 c, $02 c, \ input (variable, 3 bits)
    $95 c, $01 c, \ report count (1)
    $75 c, $05 c, \ report size (5 bits)
    $81 c, $01 c, \ input (constant, 5 bit padding)

    $05 c, $01 c, \ usage page (generic desktop)
    $09 c, $30 c, \ usage X
    $09 c, $31 c, \ usage Y
    $15 c, $81 c, \ logical minimum -127
    $25 c, $7F c, \ logical maximum 127
    $75 c, $08 c, \ report size (8 bits)
    $95 c, $03 c, \ report count (3)
    $81 c, $06 c, \ input (relative+variable, 2 position bytes X & Y)
    $c0 c, $c0 c, \ end collection (physical), end collection (application)

d# 50 constant size-report-descriptor1

create device-descriptor
    18      c, \ bLength
    %device c, \ bDescriptorType
    $0110    , \ bcdUSB
    $00     c, \ bDeviceClass
    $00     c, \ bDeviceSubClass
    $00     c, \ bDeviceProtocol
    $08     c, \ bMaxPacketSize0
    $04d8    , \ idVendor
    $0001    , \ idProduct
    $0200    , \ bcdDevice
    $01     c, \ iManufacturer
    $02     c, \ iProduct
    $00     c, \ iSerialNumber
    $01     c, \ bNumConfigurations

create configuration-descriptor
    9              c, \ bLength
    %configuration c, \ bDescriptorType
    34              , \ wTotalLength (9+9+9+7)
    $01            c, \ bNumInterfaces
    $01            c, \ bConfigurationValue
    $00            c, \ iConfiguration
    $A0            c, \ bmAttributes
    50             c, \ bMaxPower
\ interface-descriptor
    9              c, \ bLength
    %interface     c, \ bDescriptorType
    $00            c, \ bInterfaceNumber
    $00            c, \ bAlternateSetting
    $01            c, \ bNumEndpoints
    $03            c, \ bInterfaceClass (Human interface device)
    $01            c, \ bInterfaceSubClass (Boot interface)
    $02            c, \ bInterfaceProtocol (Mouse)
    $00            c, \ iInterface
\ hid-descriptor
    9              c, \ bLength
    %hid           c, \ bDescriptorType
    $0100           , \ bcdHID
    $00            c, \ bCountryCode
    $01            c, \ bNumDescriptors
    %report        c, \ bDescriptorType
    size-report-descriptor1  , \ wDescriptorLength
\ endpoint-descriptor1
    7              c, \ bLength
    %endpoint      c, \ bDescriptorType
    $81            c, \ bEndPointAddress (IN1)
    $03            c, \ bmAttributes (Interrupt)
    4               , \ wMaxPacketSize
    10             c, \ bInterval
align

: hid-descriptor ( -- addr )   configuration-descriptor  d# 9 +  d# 9 + ;

\ LANGID
create string-descriptor0
    4       c, \ bLength
    %string c, \ bDescriptorType
    $409     , \ wLANGID[0]

\ iManufacturer
create string-descriptor1
    54      c, \ bLength
    %string c, \ bDescriptorType
    'M       , \ bString
    'i       ,
    'c       ,
     'r       ,
     'o       ,
     'c       ,
     'h       ,
     'i       ,
     'p       ,
     bl       ,
     'T       ,
     'e       ,
     'c       ,
     'h       ,
     'n       ,
     'o       ,
     'l       ,
     'o       ,
     'g       ,
     'y       ,
     $2c      ,
     bl       ,
     'I       ,
     'n       ,
     'c       ,
     '.       ,

\ iProduct
create string-descriptor2
    92      c,
    %string c,
    'P       ,
    'i       ,
    'c       ,
    '1       ,
    '6       ,
    'C       ,
    '7       ,
    '4       ,
    '5       ,
    '/       ,
    '7       ,
    '6       ,
    '5       ,
    bl       ,
    'U       ,
    'S       ,
    'B       ,
    bl       ,
    'S       ,
    'u       ,
    'p       ,
    'p       ,
    'o       ,
    'r       ,
    't       ,
    bl       ,
    'F       ,
    'i       ,
    'r       ,
    'm       ,
    'w       ,
    'a       ,
    'r       ,
    'e       ,
    $2c      ,
    bl       ,
    'V       ,
    'e       ,
    'r       ,
    '.       ,
    bl       ,
    '2       ,
    '.       ,
    '0       ,
    '0       ,
