        ORG 0000h

; ==========================================
; PUERTOS DE E/S
; ==========================================

UART:               EQU 00h
CONTROL:            EQU 10h
LCD_PORT:           EQU 18h
LEDS:               EQU 20h

; ==========================================
; VARIABLES EN RAM
;
; F000-F07F: buffer de comandos
; F080-F081: direccion inicial para DUMP
; F082-F083: fin (temporalmente) y luego cantidad de bytes
; F084-F085: direccion de carga
; F086:      contador de bytes por linea
; F087-F088: contador de bytes para LOADBIN
;
; LOAD no permite escribir en F000h o mas.
; ==========================================

CMD_BUFFER:         EQU 0F000h
DUMP_ADDR:          EQU 0F080h
DUMP_COUNT:         EQU 0F082h
LOAD_ADDR:          EQU 0F084h
DUMP_LINE_COUNT:    EQU 0F086h
LOADBIN_COUNT:      EQU 0F087h


; ==========================================
; INICIO
; ==========================================

START:
        LD SP,0FFFFh

        ; ----------------------------------
        ; Inicializar LCD
        ; ----------------------------------

        CALL LCD_INIT

        LD A,080h
        CALL LCD_CMD

        ; La primera linea del LCD tiene 16 caracteres.
        LD HL,TITLE_TEXT
        CALL LCD_PRINT

        LD A,0C0h
        CALL LCD_CMD

        LD HL,MONITOR_PREFIX
        CALL LCD_PRINT
        LD HL,VERSION_TEXT
        CALL LCD_PRINT

        LD A,00Ch
        CALL LCD_CMD

        ; ----------------------------------
        ; Inicializar UART: 115200, 8N1
        ; Reloj: 1.8432 MHz
        ; ----------------------------------

        LD A,080h
        OUT (UART+3),A

        LD A,001h
        OUT (UART+0),A       ; DLL = 1

        XOR A
        OUT (UART+1),A       ; DLM = 0

        LD A,003h
        OUT (UART+3),A       ; 8N1

        XOR A
        OUT (UART+1),A       ; IER = 0

        ; ----------------------------------
        ; Mensaje de inicializacion
        ; ----------------------------------

        LD HL,START_TEXT
        CALL SERIAL_PRINT
        LD HL,MONITOR_PREFIX
        CALL SERIAL_PRINT
        LD HL,VERSION_TEXT
        CALL SERIAL_PRINT
        LD HL,CRLF_TEXT
        CALL SERIAL_PRINT

        ; ==================================
        ; TEST CRC DE ROM
        ; ==================================

        CALL CHECK_ROM_CRC

        JR NZ,ROM_CRC_BAD

        LD HL,ROM_OK_TEXT
        CALL SERIAL_PRINT

        JR PRINT_ROM_CRC

ROM_CRC_BAD:
        LD HL,ROM_ERROR_TEXT
        CALL SERIAL_PRINT

PRINT_ROM_CRC:
        LD A,D
        CALL PRINT_HEX8

        LD A,E
        CALL PRINT_HEX8

        LD HL,CRLF_TEXT
        CALL SERIAL_PRINT

        ; ==================================
        ; TEST DE RAM
        ; ==================================

        JP RAM_TEST


; ==========================================
; CRC-16/CCITT-FALSE
;
; Rango: 0000h - 7FFDh
; CRC almacenado:
;   7FFEh = byte alto
;   7FFFh = byte bajo
;
; Polinomio: 1021h
; Inicial:   FFFFh
;
; Salida:
;   DE = CRC calculado
;   A  = 00h si correcto
;   A  = 01h si incorrecto
; ==========================================

CHECK_ROM_CRC:
        LD DE,0FFFFh
        LD HL,0000h

CRC_BYTE:
        LD A,(HL)
        XOR D
        LD D,A

        LD B,08h

CRC_BIT:
        BIT 7,D
        JR Z,CRC_SHIFT_ONLY

        SLA E
        RL D

        LD A,D
        XOR 010h
        LD D,A

        LD A,E
        XOR 021h
        LD E,A

        JR CRC_NEXT_BIT

CRC_SHIFT_ONLY:
        SLA E
        RL D

CRC_NEXT_BIT:
        DJNZ CRC_BIT

        INC HL

        LD A,H
        CP 07Fh
        JR NZ,CRC_BYTE

        LD A,L
        CP 0FEh
        JR NZ,CRC_BYTE

        ; Comparar CRC calculado con ROM

        LD A,(HL)
        CP D
        JR NZ,CRC_BAD

        INC HL

        LD A,(HL)
        CP E
        JR NZ,CRC_BAD

        XOR A
        RET

CRC_BAD:
        LD A,001h
        OR A
        RET


; ==========================================
; TEST DE RAM
;
; Rango: 8000h - FFFFh
;
; La prueba sobrescribe toda la RAM,
; incluida la pila.
; No utilizar CALL/RET durante la prueba.
; ==========================================

RAM_TEST:
        ; Escribir FFh en toda la RAM

        LD HL,08000h

RAM_WRITE_FF:
        LD (HL),0FFh
        INC HL

        LD A,H
        OR L
        JR NZ,RAM_WRITE_FF

        ; Comprobar FFh

        LD HL,08000h

RAM_CHECK_FF:
        LD A,(HL)
        CP 0FFh
        JR NZ,RAM_ERROR

        INC HL

        LD A,H
        OR L
        JR NZ,RAM_CHECK_FF

        ; Escribir 00h en toda la RAM

        LD HL,08000h

RAM_WRITE_00:
        LD (HL),00h
        INC HL

        LD A,H
        OR L
        JR NZ,RAM_WRITE_00

        ; Comprobar 00h

        LD HL,08000h

RAM_CHECK_00:
        LD A,(HL)
        OR A
        JR NZ,RAM_ERROR

        INC HL

        LD A,H
        OR L
        JR NZ,RAM_CHECK_00

        ; Restaurar pila después de la prueba

        LD SP,0FFFFh

        LD HL,RAM_OK_TEXT
        CALL SERIAL_PRINT

        JP MONITOR_LOOP

RAM_ERROR:
        LD SP,0FFFFh

        LD HL,RAM_ERROR_TEXT
        CALL SERIAL_PRINT

        JP MONITOR_LOOP


; ==========================================
; BUCLE PRINCIPAL DEL MONITOR
; ==========================================

MONITOR_LOOP:
        LD HL,PROMPT_TEXT
        CALL SERIAL_PRINT

        CALL READ_LINE

        LD HL,CMD_BUFFER
        CALL SKIP_SPACES

        LD A,(HL)
        OR A
        JP Z,MONITOR_LOOP

        ; ----------------------------------
        ; Buscar comando help
        ; ----------------------------------

        LD HL,CMD_BUFFER
        LD DE,CMD_HELP_WORD
        CALL MATCH_WORD
        JP C,CMD_HELP

        ; ----------------------------------
        ; Buscar comando loadbin
        ; ----------------------------------

        LD HL,CMD_BUFFER
        LD DE,CMD_LOADBIN_WORD
        CALL MATCH_WORD
        JP C,CMD_LOADBIN

        ; ----------------------------------
        ; Buscar comando load
        ; ----------------------------------

        LD HL,CMD_BUFFER
        LD DE,CMD_LOAD_WORD
        CALL MATCH_WORD
        JP C,CMD_LOAD

        ; ----------------------------------
        ; Buscar comando dump
        ; ----------------------------------

        LD HL,CMD_BUFFER
        LD DE,CMD_DUMP_WORD
        CALL MATCH_WORD
        JP C,CMD_DUMP

        ; ----------------------------------
        ; Buscar comando go
        ; ----------------------------------

        LD HL,CMD_BUFFER
        LD DE,CMD_GO_WORD
        CALL MATCH_WORD
        JP C,CMD_GO

        ; Comando desconocido

        LD HL,UNKNOWN_TEXT
        CALL SERIAL_PRINT

        JP MONITOR_LOOP


; ==========================================
; COMANDO: help
; Mostrar los comandos disponibles.
; ==========================================

CMD_HELP:
        LD HL,HELP_TEXT
        CALL SERIAL_PRINT
        JP MONITOR_LOOP


; ==========================================
; COMANDO: go AAAA
;
; Ejecutar desde la direccion indicada.
; Ejemplo: go 8000
; ==========================================

CMD_GO:
        CALL PARSE_HEX16
        JP NC,CMD_BAD_ARGS

        CALL SKIP_SPACES

        LD A,(HL)
        OR A
        JP NZ,CMD_BAD_ARGS

        ; DE contiene la direccion de destino.
        ; Dejar una direccion de retorno en la pila para que
        ; el programa cargado pueda volver con RET.

        LD HL,GO_RETURN
        PUSH HL
        EX DE,HL
        JP (HL)

; El programa cargado vuelve aqui ejecutando RET.
; No reinicializa el sistema ni borra la RAM.
GO_RETURN:
        JP MONITOR_LOOP


; ==========================================
; COMANDO: dump AAAA BBBB
;
; AAAA = direccion inicial
; BBBB = direccion final (incluida)
;
; Ejemplo: dump 8000 8100
; ==========================================

CMD_DUMP:
        CALL PARSE_HEX16
        JP NC,CMD_BAD_ARGS

        ; Guardar direccion inicial

        PUSH HL
        EX DE,HL
        LD (DUMP_ADDR),HL
        EX DE,HL
        POP HL

        CALL SKIP_SPACES

        ; Leer direccion final

        CALL PARSE_HEX16
        JP NC,CMD_BAD_ARGS

        ; Guardar temporalmente la direccion final

        PUSH HL
        EX DE,HL
        LD (DUMP_COUNT),HL
        EX DE,HL
        POP HL

        CALL SKIP_SPACES

        LD A,(HL)
        OR A
        JP NZ,CMD_BAD_ARGS

        ; Calcular cantidad = final - inicial + 1

        LD HL,(DUMP_COUNT)
        LD DE,(DUMP_ADDR)
        OR A
        SBC HL,DE
        JP C,CMD_BAD_ARGS       ; final menor que inicial

        INC HL
        LD A,H
        OR L
        JP Z,CMD_BAD_ARGS       ; evita el rango 0000-FFFF (65536 bytes)

        LD (DUMP_COUNT),HL
        JP DUMP_LOOP


; ==========================================
; VOLCADO DE MEMORIA
;
; Muestra hasta 16 bytes por linea.
; ==========================================

DUMP_LOOP:
        LD HL,(DUMP_COUNT)

        LD A,H
        OR L
        JP Z,DUMP_DONE

        ; Calcular bytes de esta linea:
        ; minimo entre 16 y bytes restantes.

        LD A,H
        OR A
        JR NZ,DUMP_SET_16

        LD A,L
        CP 010h
        JR NC,DUMP_SET_16

        LD (DUMP_LINE_COUNT),A
        JR DUMP_PRINT_LINE

DUMP_SET_16:
        LD A,010h
        LD (DUMP_LINE_COUNT),A

DUMP_PRINT_LINE:
        ; Imprimir direccion

        LD HL,(DUMP_ADDR)

        LD A,H
        CALL PRINT_HEX8

        LD A,L
        CALL PRINT_HEX8

        LD HL,DUMP_SEPARATOR
        CALL SERIAL_PRINT

DUMP_BYTE_LOOP:
        LD A,(DUMP_LINE_COUNT)
        OR A
        JR Z,DUMP_LINE_END

        ; Leer e imprimir byte

        LD HL,(DUMP_ADDR)
        LD A,(HL)
        CALL PRINT_HEX8

        LD A,020h
        CALL UART_PUTC

        ; Incrementar direccion

        LD HL,(DUMP_ADDR)
        INC HL
        LD (DUMP_ADDR),HL

        ; Decrementar numero de bytes restantes

        LD HL,(DUMP_COUNT)
        DEC HL
        LD (DUMP_COUNT),HL

        ; Decrementar contador de linea

        LD A,(DUMP_LINE_COUNT)
        DEC A
        LD (DUMP_LINE_COUNT),A

        JR DUMP_BYTE_LOOP

DUMP_LINE_END:
        LD HL,CRLF_TEXT
        CALL SERIAL_PRINT

        JP DUMP_LOOP

DUMP_DONE:
        JP MONITOR_LOOP


; ==========================================
; COMANDO: loadbin AAAA NNNN
;
; AAAA = direccion inicial de RAM
; NNNN = numero de bytes que se recibiran
;
; Tras enviar READY, recibe exactamente NNNN
; bytes binarios por UART. Cualquier valor,
; incluidos 00h, 0Ah y 0Dh, es un dato valido.
;
; Rango permitido: 8000h - EFFFh.
; ==========================================

CMD_LOADBIN:
        ; Leer direccion inicial

        CALL PARSE_HEX16
        JP NC,CMD_BAD_ARGS

        ; Direccion inicial >= 8000h y < F000h

        LD A,D
        CP 080h
        JP C,LOAD_RANGE_ERROR
        CP 0F0h
        JP NC,LOAD_RANGE_ERROR

        ; Guardar direccion inicial

        PUSH HL
        EX DE,HL
        LD (LOAD_ADDR),HL
        EX DE,HL
        POP HL

        CALL SKIP_SPACES

        ; Leer numero de bytes

        CALL PARSE_HEX16
        JP NC,CMD_BAD_ARGS

        ; Longitud cero no permitida

        LD A,D
        OR E
        JP Z,CMD_BAD_ARGS

        ; Guardar longitud

        PUSH HL
        EX DE,HL
        LD (LOADBIN_COUNT),HL
        EX DE,HL
        POP HL

        CALL SKIP_SPACES

        ; No admitir argumentos adicionales

        LD A,(HL)
        OR A
        JP NZ,CMD_BAD_ARGS

        ; Comprobar que direccion + longitud
        ; no sobrepasa F000h. F000h exclusivo
        ; es valido como limite final.

        LD HL,(LOAD_ADDR)
        LD DE,(LOADBIN_COUNT)
        ADD HL,DE
        JP C,LOAD_RANGE_ERROR

        LD A,H
        CP 0F0h
        JR C,LOADBIN_RANGE_OK
        JP NZ,LOAD_RANGE_ERROR

        LD A,L
        OR A
        JP NZ,LOAD_RANGE_ERROR

LOADBIN_RANGE_OK:
        ; Avisar al emisor antes de recibir datos.

        LD HL,LOADBIN_READY_TEXT
        CALL SERIAL_PRINT

        LD HL,(LOAD_ADDR)
        LD BC,(LOADBIN_COUNT)

LOADBIN_RECEIVE:
        CALL UART_GETC
        LD (HL),A
        INC HL

        DEC BC
        LD A,B
        OR C
        JR NZ,LOADBIN_RECEIVE

        LD HL,LOADBIN_DONE_TEXT
        CALL SERIAL_PRINT
        JP MONITOR_LOOP


; ==========================================
; COMANDO: load AAAA
;
; Ejemplo:
;   load 8000
;   3E 41 D3 20 76
;   .
;
; Carga bytes hexadecimales en RAM.
; El punto termina la carga.
;
; Rango permitido de destino:
;   8000h - EFFFh
; ==========================================

CMD_LOAD:
        CALL PARSE_HEX16
        JP NC,CMD_BAD_ARGS

        ; La RAM comienza en 8000h

        LD A,D
        CP 080h
        JP C,LOAD_RANGE_ERROR

        ; Reservamos F000h en adelante
        ; para el buffer y las variables.

        CP 0F0h
        JP NC,LOAD_RANGE_ERROR

        ; Guardar direccion de destino

        PUSH HL
        EX DE,HL
        LD (LOAD_ADDR),HL
        EX DE,HL
        POP HL

        CALL SKIP_SPACES

        LD A,(HL)
        OR A
        JP NZ,CMD_BAD_ARGS

        LD HL,LOAD_READY_TEXT
        CALL SERIAL_PRINT

LOAD_LINE:
        LD HL,LOAD_LINE_PROMPT
        CALL SERIAL_PRINT

        CALL READ_LINE

        LD HL,CMD_BUFFER
        CALL SKIP_SPACES

        ; ¿Es una linea con solamente un punto?

        LD A,(HL)
        CP 02Eh
        JP NZ,LOAD_PARSE_BYTES

        INC HL
        CALL SKIP_SPACES

        LD A,(HL)
        OR A
        JP Z,LOAD_COMPLETE

        JP LOAD_BAD_DATA


; ==========================================
; PROCESAR LINEA DE BYTES HEXADECIMALES
; ==========================================

LOAD_PARSE_BYTES:
        CALL SKIP_SPACES

        LD A,(HL)
        OR A
        JP Z,LOAD_LINE

        ; Primer digito hexadecimal

        CALL HEX_TO_NIBBLE
        JP NC,LOAD_BAD_DATA

        LD C,A
        INC HL

        ; Segundo digito hexadecimal

        LD A,(HL)
        CALL HEX_TO_NIBBLE
        JP NC,LOAD_BAD_DATA

        LD B,A

        ; Combinar los dos nibbles

        LD A,C

        RLCA
        RLCA
        RLCA
        RLCA

        OR B
        LD C,A

        INC HL

        ; Despues del byte debe haber:
        ; espacio o fin de linea.

        LD A,(HL)
        OR A
        JR Z,LOAD_STORE_BYTE

        CP 020h
        JP NZ,LOAD_BAD_DATA

LOAD_STORE_BYTE:
        ; No escribir en F000h o superior.

        LD A,(LOAD_ADDR+1)
        CP 0F0h
        JP NC,LOAD_RANGE_ERROR

        ; Guardar byte en la direccion actual.

        LD A,C

        PUSH HL

        LD HL,(LOAD_ADDR)
        LD (HL),A

        INC HL
        LD (LOAD_ADDR),HL

        POP HL

        JP LOAD_PARSE_BYTES


LOAD_COMPLETE:
        LD HL,LOAD_DONE_TEXT
        CALL SERIAL_PRINT

        JP MONITOR_LOOP

LOAD_BAD_DATA:
        LD HL,LOAD_ERROR_TEXT
        CALL SERIAL_PRINT

        JP MONITOR_LOOP

LOAD_RANGE_ERROR:
        LD HL,LOAD_RANGE_TEXT
        CALL SERIAL_PRINT

        JP MONITOR_LOOP


; ==========================================
; ERROR DE SINTAXIS
; ==========================================

CMD_BAD_ARGS:
        LD HL,SYNTAX_ERROR_TEXT
        CALL SERIAL_PRINT

        JP MONITOR_LOOP


; ==========================================
; COMPARAR COMANDO
;
; Entrada:
;   HL = buffer de entrada
;   DE = palabra a comparar
;
; Salida:
;   Carry = 1 si coincide
;   HL apunta a los argumentos,
;   despues de saltar espacios.
; ==========================================

MATCH_WORD:
MATCH_WORD_LOOP:
        LD A,(DE)
        OR A
        JR Z,MATCH_WORD_END

        LD C,A
        LD A,(HL)
        CP C
        JR NZ,MATCH_WORD_NO

        INC HL
        INC DE

        JR MATCH_WORD_LOOP

MATCH_WORD_END:
        LD A,(HL)
        OR A
        JR Z,MATCH_WORD_YES

        CP 020h
        JR NZ,MATCH_WORD_NO

MATCH_SKIP_SPACES:
        LD A,(HL)
        CP 020h
        JR NZ,MATCH_WORD_YES

        INC HL
        JR MATCH_SKIP_SPACES

MATCH_WORD_YES:
        SCF
        RET

MATCH_WORD_NO:
        OR A
        RET


; ==========================================
; LEER LINEA DEL TERMINAL
;
; Termina con CR.
; Ignora LF.
; Admite retroceso mediante Backspace.
;
; Maximo: 127 caracteres.
; ==========================================

READ_LINE:
        LD HL,CMD_BUFFER
        LD B,07Fh

READ_CHAR:
        CALL UART_GETC

        CP 00Dh
        JR Z,READ_DONE

        CP 00Ah
        JR Z,READ_CHAR

        CP 008h
        JR Z,READ_BACKSPACE

        CP 07Fh
        JR Z,READ_BACKSPACE

        ; Conservar el caracter mientras comprobamos el buffer.
        PUSH AF
        LD A,B
        OR A
        JR Z,READ_BUFFER_FULL
        POP AF

        ; Eco y almacenamiento del caracter recibido.
        CALL UART_PUTC
        LD (HL),A
        INC HL
        DEC B
        JR READ_CHAR

READ_BUFFER_FULL:
        POP AF
        JR READ_CHAR

READ_BACKSPACE:
        ; No retroceder antes del inicio del buffer.
        LD A,L
        OR A
        JR Z,READ_CHAR

        DEC HL
        INC B

        LD A,008h
        CALL UART_PUTC

        LD A,020h
        CALL UART_PUTC

        LD A,008h
        CALL UART_PUTC

        JR READ_CHAR

READ_DONE:
        LD (HL),00h

        LD A,00Dh
        CALL UART_PUTC

        LD A,00Ah
        CALL UART_PUTC

        RET

; ==========================================
; LEER UN CARACTER DE LA UART
; Salida: A = caracter recibido
; ==========================================

UART_GETC:
UART_WAIT_RX:
        IN A,(UART+5)
        BIT 0,A
        JR Z,UART_WAIT_RX

        IN A,(UART+0)
        RET


; ==========================================
; PARSEAR NUMERO HEXADECIMAL DE 16 BITS
;
; Entrada:
;   HL apunta a cuatro digitos hex.
;
; Salida:
;   DE = valor convertido
;   HL avanza cuatro caracteres
;   Carry = 1 si valido
; ==========================================

PARSE_HEX16:
        LD DE,0000h
        LD B,004h

PARSE_HEX16_LOOP:
        LD A,(HL)
        CALL HEX_TO_NIBBLE
        JR NC,PARSE_HEX16_BAD

        LD C,A

        ; Desplazar DE cuatro bits a la izquierda.

        SLA E
        RL D

        SLA E
        RL D

        SLA E
        RL D

        SLA E
        RL D

        ; Incorporar el nuevo nibble.

        LD A,E
        OR C
        LD E,A

        INC HL
        DJNZ PARSE_HEX16_LOOP

        SCF
        RET

PARSE_HEX16_BAD:
        OR A
        RET


; ==========================================
; CONVERTIR CARACTER HEXADECIMAL
;
; Entrada: A = caracter ASCII
; Salida:  A = valor 0..15
;          Carry = 1 si valido
; ==========================================

HEX_TO_NIBBLE:
        CP 030h
        JR C,HEX_INVALID

        CP 03Ah
        JR C,HEX_NUMERIC

        CP 041h
        JR C,HEX_INVALID

        CP 047h
        JR C,HEX_UPPER

        CP 061h
        JR C,HEX_INVALID

        CP 067h
        JR NC,HEX_INVALID

        ; Letras minusculas a-f

        SUB 057h
        SCF
        RET

HEX_UPPER:
        ; Letras mayusculas A-F

        SUB 037h
        SCF
        RET

HEX_NUMERIC:
        ; Digitos 0-9

        SUB 030h
        SCF
        RET

HEX_INVALID:
        OR A
        RET


; ==========================================
; SALTAR ESPACIOS
;
; Entrada: HL apunta al texto.
; Salida: HL apunta al siguiente caracter
;         distinto de espacio.
; ==========================================

SKIP_SPACES:
        LD A,(HL)
        CP 020h
        RET NZ

        INC HL
        JR SKIP_SPACES


; ==========================================
; INICIALIZACION DEL LCD HD44780
; ==========================================

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

        ; Modo de entrada

        LD A,006h
        CALL LCD_CMD

        RET


; ==========================================
; ENVIAR COMANDO AL LCD
; Entrada: A = comando
; ==========================================

LCD_CMD:
        LD B,A

        XOR A
        OUT (CONTROL),A

        LD A,B
        OUT (LCD_PORT),A

        CALL DELAY_SHORT
        RET


; ==========================================
; ENVIAR DATO AL LCD
; Entrada: A = caracter
; ==========================================

LCD_DATA:
        LD B,A

        LD A,002h
        OUT (CONTROL),A

        LD A,B
        OUT (LCD_PORT),A

        CALL DELAY_SHORT
        RET


; ==========================================
; IMPRIMIR CADENA EN LCD
; Entrada: HL = direccion
; Terminador: 00h
; ==========================================

LCD_PRINT:
LCD_PRINT_LOOP:
        LD A,(HL)
        OR A
        RET Z

        CALL LCD_DATA
        INC HL

        JR LCD_PRINT_LOOP


; ==========================================
; IMPRIMIR CADENA POR UART
; Entrada: HL = direccion
; Terminador: 00h
; ==========================================

SERIAL_PRINT:
SERIAL_PRINT_LOOP:
        LD A,(HL)
        OR A
        RET Z

        CALL UART_PUTC

        INC HL
        JR SERIAL_PRINT_LOOP


; ==========================================
; TRANSMITIR CARACTER POR UART
; Entrada: A = caracter
; ==========================================

UART_PUTC:
        LD C,A

UART_WAIT_TX:
        IN A,(UART+5)
        BIT 5,A
        JR Z,UART_WAIT_TX

        LD A,C
        OUT (UART+0),A

        RET


; ==========================================
; IMPRIMIR BYTE COMO DOS DIGITOS HEX
; Entrada: A = byte
; ==========================================

PRINT_HEX8:
        LD B,A

        RRCA
        RRCA
        RRCA
        RRCA

        AND 00Fh
        CALL PRINT_HEX_DIGIT

        LD A,B
        AND 00Fh
        CALL PRINT_HEX_DIGIT

        RET


; ==========================================
; IMPRIMIR DIGITO HEXADECIMAL
; Entrada: A = 0..15
; ==========================================

PRINT_HEX_DIGIT:
        CP 00Ah
        JR C,HEX_DIGIT_NUM

        ADD A,007h

HEX_DIGIT_NUM:
        ADD A,030h

        CALL UART_PUTC
        RET


; ==========================================
; RETARDOS LCD
; ==========================================

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


; ==========================================
; TEXTOS LCD
; ==========================================

TITLE_TEXT:
        DB "-Z80 mainboard-",00h

MONITOR_PREFIX:
        DB "Monitor  ",00h

; Version
VERSION_TEXT:
        DB "v.1.002",00h


; ==========================================
; TEXTOS SERIE
; ==========================================

START_TEXT:
        DB 0Dh,0Ah
        DB "Z80 mainboard - AlberTovar@gmail.com - 2026"
        DB 0Dh,0Ah,00h

ROM_OK_TEXT:
        DB "ROM OK  CRC:",00h

ROM_ERROR_TEXT:
        DB "ROM ERROR CRC:",00h

RAM_OK_TEXT:
        DB "RAM OK",0Dh,0Ah,00h

RAM_ERROR_TEXT:
        DB "RAM ERROR",0Dh,0Ah,00h

CRLF_TEXT:
        DB 0Dh,0Ah,00h

PROMPT_TEXT:
        DB "Z80> ",00h

UNKNOWN_TEXT:
        DB "unknown command",0Dh,0Ah,00h

HELP_TEXT:
        DB "Commands:",0Dh,0Ah
        DB "  help            - show this help",0Dh,0Ah
        DB "  load AAAA       - load hex bytes into RAM",0Dh,0Ah
        DB "  loadbin AAAA NNNN - receive NNNN binary bytes",0Dh,0Ah
        DB "  dump AAAA BBBB  - dump memory range",0Dh,0Ah
        DB "  go AAAA         - execute at address",0Dh,0Ah,00h

SYNTAX_ERROR_TEXT:
        DB "syntax error",0Dh,0Ah,00h

CMD_HELP_WORD:
        DB "help",00h

CMD_LOADBIN_WORD:
        DB "loadbin",00h

CMD_LOAD_WORD:
        DB "load",00h

CMD_DUMP_WORD:
        DB "dump",00h

CMD_GO_WORD:
        DB "go",00h

DUMP_SEPARATOR:
        DB ": ",00h

LOAD_READY_TEXT:
        DB "Enter hex bytes; '.' ends",0Dh,0Ah,00h

LOADBIN_READY_TEXT:
        DB "READY",0Dh,0Ah,00h

LOADBIN_DONE_TEXT:
        DB "loadbin complete",0Dh,0Ah,00h

LOAD_LINE_PROMPT:
        DB ": ",00h

LOAD_DONE_TEXT:
        DB "load complete",0Dh,0Ah,00h

LOAD_ERROR_TEXT:
        DB "load data error",0Dh,0Ah,00h

LOAD_RANGE_TEXT:
        DB "load range error",0Dh,0Ah,00h