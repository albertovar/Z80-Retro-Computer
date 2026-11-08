        ORG 0000h

CONTROL:  EQU 10h
LCD_PORT: EQU 18h


; ========================================
; INICIO
; ========================================

START:

        ; Esperar después de encender el LCD
        CALL DELAY_POWERON

        ; RS = 0 -> comandos
        XOR A
        OUT (CONTROL),A


        ; Inicialización HD44780
        LD A,38h
        OUT (LCD_PORT),A
        CALL DELAY_INIT1

        LD A,38h
        OUT (LCD_PORT),A
        CALL DELAY_INIT2

        LD A,38h
        OUT (LCD_PORT),A
        CALL DELAY_SHORT


        ; Function Set
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

        ; Entry Mode Set
        LD A,06h
        OUT (LCD_PORT),A
        CALL DELAY_SHORT

        ; Display still not showing text
        ; RS = 1 -> datos
        LD A,02h
        OUT (CONTROL),A

        ; Primera línea
        LD HL,MESSAGE1

PRINT1:
        LD A,(HL)
        OR A
        JR Z,LINE2

        OUT (LCD_PORT),A
        CALL DELAY_SHORT

        INC HL
        JR PRINT1

        ; Segunda línea
LINE2:

        ; RS = 0 -> comando
        XOR A
        OUT (CONTROL),A

        ; DDRAM = C0h
        LD A,0C0h
        OUT (LCD_PORT),A
        CALL DELAY_SHORT

        ; RS = 1 -> datos
        LD A,02h
        OUT (CONTROL),A

        LD HL,MESSAGE2

PRINT2:
        LD A,(HL)
        OR A
        JR Z,SHOW_DISPLAY

        OUT (LCD_PORT),A
        CALL DELAY_SHORT

        INC HL
        JR PRINT2

        ; Show text

SHOW_DISPLAY:

        ; RS = 0 -> comando
        XOR A
        OUT (CONTROL),A

        ; Display ON
        ; Cursor OFF
        ; Blink OFF
        LD A,0Ch
        OUT (LCD_PORT),A
        CALL DELAY_SHORT


DONE:
        HALT


; ========================================
; MENSAJES
; ========================================

MESSAGE1:
        DB "-Z80  mainboard-",00h

MESSAGE2:
        DB "AlberTovar  1.00",00h


; ========================================
; DELAYS
; ========================================

; ----------------------------------------
; Power ON
; ≈ 15 ms @ 8 MHz
; ----------------------------------------

DELAY_POWERON:
        LD B,28

DP1:
        LD C,255

DP2:
        DEC C
        JR NZ,DP2

        DJNZ DP1
        RET


; ----------------------------------------
; Inicialización
; >4.1 ms
; ----------------------------------------

DELAY_INIT1:
        LD B,8

DI1:
        LD C,255

DI2:
        DEC C
        JR NZ,DI2

        DJNZ DI1
        RET


; ----------------------------------------
; Inicialización
; >100 µs
; ----------------------------------------

DELAY_INIT2:
        LD B,61

DI100:
        DJNZ DI100

        RET


; ----------------------------------------
; Operación normal LCD
; ≈ 37 µs
; ----------------------------------------

DELAY_SHORT:
        LD B,22

DS1:
        DJNZ DS1

        RET


; ----------------------------------------
; CLEAR DISPLAY
; ≈ 1.6 ms
; ----------------------------------------

DELAY_LONG:
        LD B,3

DL1:
        LD C,255

DL2:
        DEC C
        JR NZ,DL2

        DJNZ DL1

        RET