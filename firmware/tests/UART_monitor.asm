        ORG 0000h

UART:       EQU 00h
CONTROL:    EQU 10h
LCD_PORT:   EQU 18h

START:
        LD SP,0FFFFh

        ; --------------------------------
        ; Inicializar LCD HD44780
        ; --------------------------------
        CALL LCD_INIT

        ; Escribir primera linea
        LD A,080h
        CALL LCD_CMD

        LD HL,TITLE_TEXT
        CALL LCD_PRINT

        ; Escribir segunda linea
        LD A,0C0h
        CALL LCD_CMD

        LD HL,UART_TEXT
        CALL LCD_PRINT

        ; Encender display cuando todo este escrito
        LD A,00Ch
        CALL LCD_CMD

        ; --------------------------------
        ; Inicializar UART: 115200, 8N1
        ; Reloj: 1.8432 MHz
        ; --------------------------------
        LD A,080h
        OUT (UART+3),A       ; DLAB = 1

        LD A,001h
        OUT (UART+0),A       ; DLL = 1

        XOR A
        OUT (UART+1),A       ; DLM = 0

        LD A,003h
        OUT (UART+3),A       ; 8N1, DLAB = 0

        XOR A
        OUT (UART+1),A       ; IER = 0

        ; --------------------------------
        ; Mensaje inicial por puerto serie
        ; --------------------------------
        LD HL,MESSAGE

SEND_MESSAGE:
        LD A,(HL)
        OR A
        JR Z,RECEIVE_LOOP

WAIT_TX:
        IN A,(UART+5)        ; LSR
        BIT 5,A              ; THRE
        JR Z,WAIT_TX

        LD A,(HL)
        OUT (UART+0),A       ; THR
        INC HL
        JR SEND_MESSAGE

        ; --------------------------------
        ; Eco serie permanente
        ; --------------------------------
RECEIVE_LOOP:
        IN A,(UART+5)        ; LSR
        BIT 0,A              ; DR
        JR Z,RECEIVE_LOOP

        IN A,(UART+0)        ; Leer caracter
        LD C,A               ; Guardarlo

WAIT_ECHO_TX:
        IN A,(UART+5)
        BIT 5,A              ; THRE
        JR Z,WAIT_ECHO_TX

        LD A,C
        OUT (UART+0),A       ; Devolver caracter

        JR RECEIVE_LOOP

        ; --------------------------------
        ; Inicializacion del LCD
        ; --------------------------------
LCD_INIT:
        CALL DELAY_LONG

        LD A,038h
        CALL LCD_CMD
        CALL DELAY_LONG

        LD A,038h
        CALL LCD_CMD
        CALL DELAY_LONG

        LD A,038h
        CALL LCD_CMD
        CALL DELAY_LONG

        ; Display apagado
        LD A,008h
        CALL LCD_CMD

        ; Borrar pantalla
        LD A,001h
        CALL LCD_CMD
        CALL DELAY_LONG

        ; Incrementar direccion, sin desplazar
        LD A,006h
        CALL LCD_CMD

        RET

        ; --------------------------------
        ; Enviar comando al LCD
        ; Entrada: A = comando
        ; --------------------------------
LCD_CMD:
        LD B,A

        XOR A
        OUT (CONTROL),A      ; RS = 0

        LD A,B
        OUT (LCD_PORT),A

        CALL DELAY_SHORT
        RET

        ; --------------------------------
        ; Enviar dato al LCD
        ; Entrada: A = caracter
        ; --------------------------------
LCD_DATA:
        LD B,A

        LD A,002h
        OUT (CONTROL),A      ; RS = 1

        LD A,B
        OUT (LCD_PORT),A

        CALL DELAY_SHORT
        RET

        ; --------------------------------
        ; Imprimir cadena terminada en 00h
        ; Entrada: HL = direccion
        ; --------------------------------
LCD_PRINT:
LCD_PRINT_LOOP:
        LD A,(HL)
        OR A
        RET Z

        CALL LCD_DATA
        INC HL
        JR LCD_PRINT_LOOP

        ; --------------------------------
        ; Retardos
        ; --------------------------------
DELAY_SHORT:
        PUSH BC
        LD BC,0100h

DELAY_SHORT_LOOP:
        DEC BC
        LD A,B
        OR C
        JR NZ,DELAY_SHORT_LOOP

        POP BC
        RET

DELAY_LONG:
        PUSH BC
        LD BC,0FFFFh

DELAY_LONG_LOOP:
        DEC BC
        LD A,B
        OR C
        JR NZ,DELAY_LONG_LOOP

        POP BC
        RET

        ; --------------------------------
        ; Textos
        ; --------------------------------
TITLE_TEXT:
        DB "-Z80  maniboard-",00h

UART_TEXT:
        DB "UART mon. 112500",00h

MESSAGE:
        DB "Z80 UART READY",0Dh,0Ah,00h