        ORG 0000h

SWITCHES: EQU 28h
LEDS:     EQU 20h

START:
        IN A,(SWITCHES)     ; Lee los 8 switches mediante el 74HC244
        OUT (LEDS),A        ; Muestra el byte leído en los 8 LEDs
        RET