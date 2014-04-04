\ Descriptors

\ append 16bit values to memory
: w, ( 16b -- )   $100 /mod  swap c,  c, ;

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

here report-descriptor1 - constant size-report-descriptor1


create device-descriptor
    18      c, \ bLength
    %device c, \ bDescriptorType
    $0110   w, \ bcdUSB
    $00     c, \ bDeviceClass
    $00     c, \ bDeviceSubClass
    $00     c, \ bDeviceProtocol
    $08     c, \ bMaxPacketSize0
    $04d8   w, \ idVendor
    $0001   w, \ idProduct
    $0200   w, \ bcdDevice
    $01     c, \ iManufacturer
    $02     c, \ iProduct
    $00     c, \ iSerialNumber
    $01     c, \ bNumConfigurations

create configuration-descriptor
    9              c, \ bLength
    %configuration c, \ bDescriptorType
    34             w, \ wTotalLength (9+9+9+7)
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
    $0100          w, \ bcdHID
    $00            c, \ bCountryCode
    $01            c, \ bNumDescriptors
    %report        c, \ bDescriptorType
    size-report-descriptor1 w, \ wDescriptorLength
\ endpoint-descriptor1
    7              c, \ bLength
    %endpoint      c, \ bDescriptorType
    $81            c, \ bEndPointAddress (IN1)
    $03            c, \ bmAttributes (Interrupt)
    4              w, \ wMaxPacketSize
    10             c, \ bInterval (10 ms)

: hid-descriptor ( -- addr )   configuration-descriptor  9 +  9 + ;

\ LANGID
create string-descriptor0
    4       c, \ bLength
    %string c, \ bDescriptorType
    $409    w, \ wLANGID[0]

\ iManufacturer
create string-descriptor1
    0       c, \ bLength
    %string c, \ bDescriptorType
    char M  w, \ bString
    char i  w,
    char c  w,
    char r  w,
    char o  w,
    char c  w,
    char h  w,
    char i  w,
    char p  w,
    bl      w,
    char T  w,
    char e  w,
    char c  w,
    char h  w,
    char n  w,
    char o  w,
    char l  w,
    char o  w,
    char g  w,
    char y  w,
    char ,  w,
    bl      w,
    char I  w,
    char n  w,
    char c  w,
    char .  w,
here string-descriptor1 -  string-descriptor1 c!

\ iProduct
create string-descriptor2
    0       c,
    %string c,
    char P  w,
    char i  w,
    char c  w,
    char 1  w,
    char 6  w,
    char C  w,
    char 7  w,
    char 4  w,
    char 5  w,
    char /  w,
    char 7  w,
    char 6  w,
    char 5  w,
    bl      w,
    char U  w,
    char S  w,
    char B  w,
    bl      w,
    char S  w,
    char u  w,
    char p  w,
    char p  w,
    char o  w,
    char r  w,
    char t  w,
    bl      w,
    char F  w,
    char i  w,
    char r  w,
    char m  w,
    char w  w,
    char a  w,
    char r  w,
    char e  w,
    char ,  w,
    bl      w,
    char V  w,
    char e  w,
    char r  w,
    char .  w,
    bl      w,
    char 2  w,
    char .  w,
    char 0  w,
    char 0  w,
here string-descriptor2 -  string-descriptor2 c!
