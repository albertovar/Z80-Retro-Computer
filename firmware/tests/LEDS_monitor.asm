        ORG 0000h

LEDS:   EQU 20h

START:
        ; DERECHA -> IZQUIERDA
        LD A,80h

RIGHT:
        OUT (LEDS),A
        CALL DELAY

        SRL A
        JR NZ,RIGHT

        ; IZQUIERDA -> DERECHA
        LD A,02h

LEFT:
        OUT (LEDS),A
        CALL DELAY

        SLA A
        JR NZ,LEFT

        ; Apagar todos los LED
        XOR A
        OUT (LEDS),A

        HALT


DELAY:
        LD B,2
D1:
        LD C,244
D2:
        LD D,255
D3:
        DEC D
        JR NZ,D3
        DEC C
        JR NZ,D2
        DJNZ D1
        RET