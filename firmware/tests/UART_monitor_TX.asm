        ORG 0000h

UART:   EQU 00h

START:
        ; 8250 -> 115200, 8N1
        LD A,80h
        OUT (UART+3),A       ; LCR, DLAB=1

        LD A,01h
        OUT (UART+0),A       ; DLL = 1

        XOR A
        OUT (UART+1),A       ; DLM = 0

        LD A,03h
        OUT (UART+3),A       ; 8N1, DLAB=0

        ; Mensaje
        LD HL,MESSAGE

SEND:
        LD A,(HL)
        OR A
        JR Z,DONE

WAIT_TX:
        IN A,(UART+5)        ; LSR
        BIT 5,A              ; THRE
        JR Z,WAIT_TX

        LD A,(HL)
        OUT (UART+0),A       ; THR
        INC HL
        JR SEND

DONE:
        HALT

MESSAGE:
        DB "Z80 UART OK",0Dh,0Ah,00h