        ORG 0000h

; ============================================================
; PUERTOS
; ============================================================

CONTROL:    EQU 10h
LCD_PORT:   EQU 18h
LEDS:       EQU 20h


; ============================================================
; INICIO
; ============================================================

START:

        ; Pila en RAM
        LD SP,0FFFFh

        ; Inicializar LCD
        CALL LCD_INIT


; ============================================================
; PANTALLA INICIAL
; ============================================================

        ; Línea 1
        XOR A
        OUT (CONTROL),A

        LD A,80h
        OUT (LCD_PORT),A
        CALL DELAY_SHORT

        LD A,02h
        OUT (CONTROL),A

        LD HL,TITLE_TEXT
        CALL LCD_PRINT


        ; Línea 2
        XOR A
        OUT (CONTROL),A

        LD A,0C0h
        OUT (LCD_PORT),A
        CALL DELAY_SHORT

        LD A,02h
        OUT (CONTROL),A

        LD HL,ROM_TEST_TEXT
        CALL LCD_PRINT


; ============================================================
; COMPROBAR CRC DE LA ROM
; ============================================================

        CALL CHECK_ROM_CRC

        JR NZ,ROM_ERROR


; ============================================================
; ROM CORRECTA
; ============================================================

        ; Test completo de RAM.
        ;
        ; SHOW_RAM_TEST termina con JP SHOW_FINAL_OK.
        ; No vuelve mediante RET porque el test escribe FFFFh,
        ; destruyendo la dirección almacenada en la pila.

        CALL SHOW_RAM_TEST


; ============================================================
; ERROR DE ROM
; ============================================================

ROM_ERROR:

        CALL SHOW_ROM_ERROR

        ; Todos los LEDs encendidos
        LD A,0FFh
        OUT (LEDS),A

        HALT


; ============================================================
; INICIALIZACIÓN LCD
; ============================================================

LCD_INIT:

        ; RS = 0 -> comandos
        XOR A
        OUT (CONTROL),A

        ; Function Set
        LD A,38h
        OUT (LCD_PORT),A
        CALL DELAY_LONG

        LD A,38h
        OUT (LCD_PORT),A
        CALL DELAY_SHORT

        LD A,38h
        OUT (LCD_PORT),A
        CALL DELAY_SHORT

        ; Display OFF
        LD A,08h
        OUT (LCD_PORT),A
        CALL DELAY_SHORT

        ; Clear Display
        LD A,01h
        OUT (LCD_PORT),A
        CALL DELAY_LONG

        ; Entry Mode
        LD A,06h
        OUT (LCD_PORT),A
        CALL DELAY_SHORT

        ; Display ON
        LD A,0Ch
        OUT (LCD_PORT),A
        CALL DELAY_SHORT

        RET


; ============================================================
; IMPRIMIR TEXTO
;
; HL -> texto terminado en 00h
; ============================================================

LCD_PRINT:

LCD_PRINT_LOOP:

        LD A,(HL)
        OR A
        RET Z

        ; RS = 1 -> datos
        LD A,02h
        OUT (CONTROL),A

        ; Recuperar carácter
        LD A,(HL)
        OUT (LCD_PORT),A

        CALL DELAY_SHORT

        INC HL

        JR LCD_PRINT_LOOP


; ============================================================
; COMPROBAR CRC DE LA ROM
;
; CRC-16/CCITT-FALSE
;
; Calcula sobre:
;       0000h - 7FFDh
;
; CRC almacenado:
;       7FFEh = byte alto
;       7FFFh = byte bajo
;
; Salida:
;       Z  = CRC correcto
;       NZ = CRC incorrecto
;
; D:E = CRC calculado
; ============================================================

CHECK_ROM_CRC:

        ; CRC inicial = FFFFh
        LD DE,0FFFFh

        ; Dirección inicial
        LD HL,0000h


CRC_BYTE:

        ; Leer byte de ROM
        LD A,(HL)

        ; XOR con byte alto del CRC
        XOR D
        LD D,A

        ; 8 bits
        LD B,08h


CRC_BIT:

        BIT 7,D
        JR Z,CRC_SHIFT_ONLY

        ; Desplazamiento
        SLA E
        RL D

        ; XOR 1021h
        LD A,D
        XOR 10h
        LD D,A

        LD A,E
        XOR 21h
        LD E,A

        JR CRC_NEXT_BIT


CRC_SHIFT_ONLY:

        SLA E
        RL D


CRC_NEXT_BIT:

        DJNZ CRC_BIT

        INC HL

        ; ¿HL = 7FFEh?
        LD A,H
        CP 07Fh
        JR NZ,CRC_BYTE

        LD A,L
        CP 0FEh
        JR NZ,CRC_BYTE


        ; ----------------------------------------------------
        ; Comparar CRC calculado con el almacenado
        ; ----------------------------------------------------

        ; Byte alto
        LD A,(HL)
        CP D
        JR NZ,CRC_BAD

        ; Byte bajo
        INC HL
        LD A,(HL)
        CP E
        JR NZ,CRC_BAD


        ; CRC correcto
        XOR A
        RET


CRC_BAD:

        LD A,01h
        OR A
        RET

; ============================================================
; MOSTRAR ERROR DE ROM
; ============================================================

SHOW_ROM_ERROR:

        XOR A
        OUT (CONTROL),A

        LD A,0C0h
        OUT (LCD_PORT),A
        CALL DELAY_SHORT

        LD A,02h
        OUT (CONTROL),A

        LD HL,ROM_ERROR_TEXT
        CALL LCD_PRINT

        RET


; ============================================================
; TEST COMPLETO DE RAM
;
; Comprueba:
;       8000h - FFFFh
;
; Para cada posición:
;       escribe FFh
;       lee FFh
;       escribe 00h
;       lee 00h
;
; IMPORTANTE:
;       No hace RET al terminar.
;
; La pila está inicialmente en FFFFh y el propio test modifica
; FFFFh. Por tanto, la dirección de retorno del CALL queda
; destruida.
;
; Al terminar correctamente:
;       JP SHOW_FINAL_OK
; ============================================================

SHOW_RAM_TEST:

        ; Mostrar "Testing memory.."

        XOR A
        OUT (CONTROL),A

        LD A,0C0h
        OUT (LCD_PORT),A
        CALL DELAY_SHORT

        LD A,02h
        OUT (CONTROL),A

        LD HL,RAM_TEST_TEXT
        CALL LCD_PRINT


        ; Inicio RAM
        LD HL,8000h


RAM_TEST:

        ; ----------------------------------------------------
        ; Escribir FFh
        ; ----------------------------------------------------

        LD A,0FFh
        LD (HL),A

        ; Leer FFh
        LD A,(HL)
        CP 0FFh
        JR NZ,RAM_ERROR


        ; ----------------------------------------------------
        ; Escribir 00h
        ; ----------------------------------------------------

        XOR A
        LD (HL),A

        ; Leer 00h
        LD A,(HL)
        OR A
        JR NZ,RAM_ERROR


        ; Siguiente dirección
        INC HL

        ; Si HL != 0000h, continuar
        LD A,H
        OR L
        JR NZ,RAM_TEST


        ; ----------------------------------------------------
        ; RAM COMPLETAMENTE CORRECTA
        ;
        ; No hacer RET: FFFFh ha sido utilizado como RAM y
        ; contiene basura desde el punto de vista de la pila.
        ; ----------------------------------------------------

        JP SHOW_FINAL_OK


; ============================================================
; ERROR DE RAM
;
; HL = dirección donde se detectó el error
; ============================================================

RAM_ERROR:

        ; Mostrar "RAM ERROR "

        XOR A
        OUT (CONTROL),A

        LD A,0C0h
        OUT (LCD_PORT),A
        CALL DELAY_SHORT

        LD A,02h
        OUT (CONTROL),A

        LD HL,RAM_ERROR_TEXT
        CALL LCD_PRINT


        ; ----------------------------------------------------
        ; Mostrar dirección de error
        ; ----------------------------------------------------

        LD A,H
        CALL PRINT_HEX8

        LD A,L
        CALL PRINT_HEX8


        ; Error permanente
        HALT


; ============================================================
; PANTALLA FINAL
;
; ROM_OK, CRC FFFF
; RAM_OK  (V.1.00)
;
; El CRC se lee directamente de la ROM:
;       7FFEh = byte alto
;       7FFFh = byte bajo
;
; No se vuelve a calcular.
;
; Esta rutina es TERMINAL y termina en HALT.
; ============================================================

SHOW_FINAL_OK:

        ; ----------------------------------------------------
        ; DISPLAY OFF
        ; ----------------------------------------------------

        XOR A
        OUT (CONTROL),A

        LD A,08h
        OUT (LCD_PORT),A
        CALL DELAY_SHORT


        ; ----------------------------------------------------
        ; CLEAR DISPLAY
        ; ----------------------------------------------------

        LD A,01h
        OUT (LCD_PORT),A
        CALL DELAY_LONG


        ; ----------------------------------------------------
        ; LÍNEA 1
        ;
        ; ROM_OK, CRC 581A
        ; ----------------------------------------------------

        LD A,80h
        OUT (LCD_PORT),A
        CALL DELAY_SHORT

        LD A,02h
        OUT (CONTROL),A

        LD HL,FINAL_ROM_TEXT
        CALL LCD_PRINT


        ; ----------------------------------------------------
        ; Leer CRC directamente de la ROM
        ; ----------------------------------------------------

        LD A,(07FFEh)
        CALL PRINT_HEX8

        LD A,(07FFFh)
        CALL PRINT_HEX8

        LD A,')'
        OUT (LCD_PORT),A
        CALL DELAY_SHORT


        ; ----------------------------------------------------
        ; LÍNEA 2
        ;
        ; RAM_OK  (V.1.00)
        ; ----------------------------------------------------

        XOR A
        OUT (CONTROL),A

        LD A,0C0h
        OUT (LCD_PORT),A
        CALL DELAY_SHORT

        LD A,02h
        OUT (CONTROL),A

        LD HL,FINAL_RAM_TEXT
        CALL LCD_PRINT


        ; ----------------------------------------------------
        ; DISPLAY ON
        ; ----------------------------------------------------

        XOR A
        OUT (CONTROL),A

        LD A,0Ch
        OUT (LCD_PORT),A
        CALL DELAY_SHORT


        ; ----------------------------------------------------
        ; FIN DEL MONITOR
        ; ----------------------------------------------------

        HALT


; ============================================================
; IMPRIMIR BYTE EN HEXADECIMAL
;
; Entrada:
;       A = byte
;
; Ejemplo:
;       5Ah -> "5A"
; ============================================================

PRINT_HEX8:

        ; Guardar byte original
        LD B,A

        ; ----------------------------------------------------
        ; Nibble alto
        ; ----------------------------------------------------

        RRCA
        RRCA
        RRCA
        RRCA
        AND 0Fh

        CALL PRINT_HEX_DIGIT


        ; ----------------------------------------------------
        ; Nibble bajo
        ; ----------------------------------------------------

        LD A,B
        AND 0Fh

        CALL PRINT_HEX_DIGIT

        RET


; ============================================================
; IMPRIMIR UN DÍGITO HEX
;
; Entrada:
;       A = 0..15
; ============================================================

PRINT_HEX_DIGIT:

        CP 0Ah
        JR C,HEX_NUMBER

        ADD A,07h


HEX_NUMBER:

        ADD A,30h

        ; Guardar carácter
        LD C,A

        ; RS = 1
        LD A,02h
        OUT (CONTROL),A

        ; Enviar carácter
        LD A,C
        OUT (LCD_PORT),A

        CALL DELAY_SHORT

        RET


; ============================================================
; RETARDO CORTO
; ============================================================

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


; ============================================================
; RETARDO LARGO
; ============================================================

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


; ============================================================
; TEXTOS
; ============================================================

TITLE_TEXT:
        DB "-Z80  mainboard-",00h

ROM_TEST_TEXT:
        DB "Testing ROM...",00h

ROM_ERROR_TEXT:
        DB "ROM ERROR",00h

RAM_TEST_TEXT:
        DB "Testing RAM...",00h

RAM_ERROR_TEXT:
        DB "RAM ERROR ",00h

FINAL_ROM_TEXT:
        DB "ROM OK  CRC:",00h

FINAL_RAM_TEXT:
        DB "RAM OK  Ver:1.00",00h