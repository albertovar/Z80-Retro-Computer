        ORG 0000h

UART:   EQU 00h
LEDS:   EQU 20h

START:
        ; Configurar UART: divisor = 1
        LD A,80h
        OUT (UART+3),A       ; LCR: activar DLAB

        LD A,01h
        OUT (UART+0),A       ; DLL = 1

        XOR A
        OUT (UART+1),A       ; DLM = 0

        ; Configurar 8 bits, sin paridad, 1 stop
        LD A,03h
        OUT (UART+3),A       ; LCR: 8N1

        ; Desactivar interrupciones
        XOR A
        OUT (UART+1),A       ; IER = 0

WAIT_RX:
        IN A,(UART+5)        ; Leer LSR
        BIT 0,A              ; ¿Hay un carácter recibido?
        JR Z,WAIT_RX

        ; Leer el carácter recibido
        IN A,(UART+0)        ; RBR
        OUT (LEDS),A         ; Mostrarlo en los LED

        HALT