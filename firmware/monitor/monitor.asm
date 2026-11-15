        ORG 0000h

; ==========================================
; I/O PORTS
; ==========================================

UART_PORT:          EQU 00h
CONTROL_PORT:       EQU 10h
LCD_PORT:           EQU 18h
LEDS_PORT:          EQU 20h
SWITCHES_PORT:      EQU 28h

; ==========================================
; RAM VARIABLES
;
; F000-F07F: command buffer
; F080-F081: initial address for DUMP
; F082-F083: end address (temporarily), then byte count
; F084-F085: load address
; F086:      byte counter per line
; F087-F088: byte counter for LOADBIN
;
; LOAD does not allow writes at F000h or above.
; ==========================================

COMMAND_BUFFER:         EQU 0F000h
DUMP_ADDRESS:           EQU 0F080h
DUMP_BYTE_COUNT:        EQU 0F082h
LOAD_ADDRESS:           EQU 0F084h
DUMP_LINE_BYTE_COUNT:   EQU 0F086h
LOADBIN_BYTE_COUNT:     EQU 0F087h


; ==========================================
; STARTUP
; ==========================================

START:
        LD SP,0FFFFh

        ; ----------------------------------
        ; Initialize LCD
        ; ----------------------------------

        CALL LCD_INIT

        LD A,080h
        CALL LCD_CMD

        ; The first LCD line has 16 characters.
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
        ; LED test
        ; ----------------------------------

        CALL LED_TEST

        ; ----------------------------------
        ; Display switches on LEDs
        ; ----------------------------------

        CALL SWITCHES_TO_LEDS

        ; ----------------------------------
        ; Initialize UART: 115200, 8N1
        ; Clock: 1.8432 MHz
        ; ----------------------------------

        LD A,080h
        OUT (UART_PORT+3),A

        LD A,001h
        OUT (UART_PORT+0),A       ; DLL = 1

        XOR A
        OUT (UART_PORT+1),A       ; DLM = 0

        LD A,003h
        OUT (UART_PORT+3),A       ; 8N1

        XOR A
        OUT (UART_PORT+1),A       ; IER = 0

        ; ----------------------------------
        ; Startup message
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
        ; ROM CRC TEST
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
        ; RAM TEST
        ; ==================================

        JP RAM_TEST


; ==========================================
; LED TEST
;
; Sweep from right to left and back.
; Turns off all LEDs when finished.
; ==========================================

LED_TEST:
        ; Right -> left
        LD A,080h

LED_TEST_RIGHT:
        OUT (LEDS_PORT),A
        CALL LED_TEST_DELAY

        SRL A
        JR NZ,LED_TEST_RIGHT

        ; Left -> right
        LD A,002h

LED_TEST_LEFT:
        OUT (LEDS_PORT),A
        CALL LED_TEST_DELAY

        SLA A
        JR NZ,LED_TEST_LEFT

        ; Turn off all LEDs
        XOR A
        OUT (LEDS_PORT),A
        RET


LED_TEST_DELAY:
        LD B,001h

LED_TEST_DELAY_OUTER:
        LD C,0C8h

LED_TEST_DELAY_MIDDLE:
        LD D,0FFh

LED_TEST_DELAY_INNER:
        DEC D
        JR NZ,LED_TEST_DELAY_INNER

        DEC C
        JR NZ,LED_TEST_DELAY_MIDDLE

        DJNZ LED_TEST_DELAY_OUTER
        RET


; ==========================================
; DISPLAY SWITCHES ON LEDs
;
; Reads the 8 switches and displays the
; corresponding byte on the LEDs.
; ==========================================

SWITCHES_TO_LEDS:
        IN A,(SWITCHES_PORT)
        OUT (LEDS_PORT),A
        RET


; ==========================================
; CRC-16/CCITT-FALSE
;
; Range: 0000h - 7FFDh
; Stored CRC:
;   7FFEh = high byte
;   7FFFh = low byte
;
; Polynomial: 1021h
; Initial:    FFFFh
;
; Output:
;   DE = calculated CRC
;   A  = 00h if correct
;   A  = 01h if incorrect
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

        ; Compare the calculated CRC with ROM

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
; RAM TEST
;
; Range: 8000h - FFFFh
;
; The test overwrites all RAM,
; including the stack.
; Do not use CALL/RET during the test.
; ==========================================

RAM_TEST:
        ; Write FFh to all RAM

        LD HL,08000h

RAM_WRITE_FF:
        LD (HL),0FFh
        INC HL

        LD A,H
        OR L
        JR NZ,RAM_WRITE_FF

        ; Check FFh

        LD HL,08000h

RAM_CHECK_FF:
        LD A,(HL)
        CP 0FFh
        JR NZ,RAM_ERROR

        INC HL

        LD A,H
        OR L
        JR NZ,RAM_CHECK_FF

        ; Write 00h to all RAM

        LD HL,08000h

RAM_WRITE_00:
        LD (HL),00h
        INC HL

        LD A,H
        OR L
        JR NZ,RAM_WRITE_00

        ; Check 00h

        LD HL,08000h

RAM_CHECK_00:
        LD A,(HL)
        OR A
        JR NZ,RAM_ERROR

        INC HL

        LD A,H
        OR L
        JR NZ,RAM_CHECK_00

        ; Restore the stack after the test

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
; MAIN MONITOR LOOP
; ==========================================

MONITOR_LOOP:
        LD HL,PROMPT_TEXT
        CALL SERIAL_PRINT

        CALL READ_LINE

        LD HL,COMMAND_BUFFER
        CALL SKIP_SPACES

        LD A,(HL)
        OR A
        JP Z,MONITOR_LOOP

        ; ----------------------------------
        ; Look up the help command
        ; ----------------------------------

        LD HL,COMMAND_BUFFER
        LD DE,CMD_HELP_WORD
        CALL MATCH_WORD
        JP C,CMD_HELP

        ; ----------------------------------
        ; Look up the loadbin command
        ; ----------------------------------

        LD HL,COMMAND_BUFFER
        LD DE,CMD_LOADBIN_WORD
        CALL MATCH_WORD
        JP C,CMD_LOADBIN

        ; ----------------------------------
        ; Look up the load command
        ; ----------------------------------

        LD HL,COMMAND_BUFFER
        LD DE,CMD_LOAD_WORD
        CALL MATCH_WORD
        JP C,CMD_LOAD

        ; ----------------------------------
        ; Look up the dump command
        ; ----------------------------------

        LD HL,COMMAND_BUFFER
        LD DE,CMD_DUMP_WORD
        CALL MATCH_WORD
        JP C,CMD_DUMP

        ; ----------------------------------
        ; Look up the go command
        ; ----------------------------------

        LD HL,COMMAND_BUFFER
        LD DE,CMD_GO_WORD
        CALL MATCH_WORD
        JP C,CMD_GO

        ; Unknown command

        LD HL,UNKNOWN_TEXT
        CALL SERIAL_PRINT

        JP MONITOR_LOOP


; ==========================================
; COMMAND: help
; Display the available commands.
; ==========================================

CMD_HELP:
        LD HL,HELP_TEXT
        CALL SERIAL_PRINT
        JP MONITOR_LOOP


; ==========================================
; COMMAND: go AAAA
;
; Execute from the specified address.
; Example: go 8000
; ==========================================

CMD_GO:
        CALL PARSE_HEX16
        JP NC,CMD_BAD_ARGS

        CALL SKIP_SPACES

        LD A,(HL)
        OR A
        JP NZ,CMD_BAD_ARGS

        ; DE contains the target address.
        ; Place a return address on the stack so that
        ; the loaded program can return with RET.

        LD HL,GO_RETURN
        PUSH HL
        EX DE,HL
        JP (HL)

; The loaded program returns here by executing RET.
; It does not reinitialize the system or clear RAM.
GO_RETURN:
        JP MONITOR_LOOP


; ==========================================
; COMMAND: dump AAAA BBBB
;
; AAAA = initial address
; BBBB = final address (inclusive)
;
; Example: dump 8000 8100
; ==========================================

CMD_DUMP:
        CALL PARSE_HEX16
        JP NC,CMD_BAD_ARGS

        ; Save initial address

        PUSH HL
        EX DE,HL
        LD (DUMP_ADDRESS),HL
        EX DE,HL
        POP HL

        CALL SKIP_SPACES

        ; Read final address

        CALL PARSE_HEX16
        JP NC,CMD_BAD_ARGS

        ; Temporarily save final address

        PUSH HL
        EX DE,HL
        LD (DUMP_BYTE_COUNT),HL
        EX DE,HL
        POP HL

        CALL SKIP_SPACES

        LD A,(HL)
        OR A
        JP NZ,CMD_BAD_ARGS

        ; Calculate count = final - initial + 1

        LD HL,(DUMP_BYTE_COUNT)
        LD DE,(DUMP_ADDRESS)
        OR A
        SBC HL,DE
        JP C,CMD_BAD_ARGS       ; final lower than initial

        INC HL
        LD A,H
        OR L
        JP Z,CMD_BAD_ARGS       ; avoids the 0000h-FFFFh range (65536 bytes)

        LD (DUMP_BYTE_COUNT),HL
        JP DUMP_LOOP


; ==========================================
; MEMORY DUMP
;
; Displays up to 16 bytes per line.
; ==========================================

DUMP_LOOP:
        LD HL,(DUMP_BYTE_COUNT)

        LD A,H
        OR L
        JP Z,DUMP_DONE

        ; Calculate bytes for this line:
        ; minimum of 16 and remaining bytes.

        LD A,H
        OR A
        JR NZ,DUMP_SET_16

        LD A,L
        CP 010h
        JR NC,DUMP_SET_16

        LD (DUMP_LINE_BYTE_COUNT),A
        JR DUMP_PRINT_LINE

DUMP_SET_16:
        LD A,010h
        LD (DUMP_LINE_BYTE_COUNT),A

DUMP_PRINT_LINE:
        ; Print address

        LD HL,(DUMP_ADDRESS)

        LD A,H
        CALL PRINT_HEX8

        LD A,L
        CALL PRINT_HEX8

        LD HL,DUMP_SEPARATOR
        CALL SERIAL_PRINT

DUMP_BYTE_LOOP:
        LD A,(DUMP_LINE_BYTE_COUNT)
        OR A
        JR Z,DUMP_LINE_END

        ; Read and print byte

        LD HL,(DUMP_ADDRESS)
        LD A,(HL)
        CALL PRINT_HEX8

        LD A,020h
        CALL UART_PUTC

        ; Increment address

        LD HL,(DUMP_ADDRESS)
        INC HL
        LD (DUMP_ADDRESS),HL

        ; Decrement remaining byte count

        LD HL,(DUMP_BYTE_COUNT)
        DEC HL
        LD (DUMP_BYTE_COUNT),HL

        ; Decrement line counter

        LD A,(DUMP_LINE_BYTE_COUNT)
        DEC A
        LD (DUMP_LINE_BYTE_COUNT),A

        JR DUMP_BYTE_LOOP

DUMP_LINE_END:
        LD HL,CRLF_TEXT
        CALL SERIAL_PRINT

        JP DUMP_LOOP

DUMP_DONE:
        JP MONITOR_LOOP


; ==========================================
; COMMAND: loadbin AAAA NNNN
;
; AAAA = initial RAM address
; NNNN = number of bytes to receive
;
; After sending READY, receives exactly NNNN
; binary bytes through UART. Any value,
; including 00h, 0Ah, and 0Dh, is valid data.
;
; Allowed range: 8000h - EFFFh.
; ==========================================

CMD_LOADBIN:
        ; Read initial address

        CALL PARSE_HEX16
        JP NC,CMD_BAD_ARGS

        ; Initial address >= 8000h and < F000h

        LD A,D
        CP 080h
        JP C,LOAD_RANGE_ERROR
        CP 0F0h
        JP NC,LOAD_RANGE_ERROR

        ; Save initial address

        PUSH HL
        EX DE,HL
        LD (LOAD_ADDRESS),HL
        EX DE,HL
        POP HL

        CALL SKIP_SPACES

        ; Read byte count

        CALL PARSE_HEX16
        JP NC,CMD_BAD_ARGS

        ; Zero length is not allowed

        LD A,D
        OR E
        JP Z,CMD_BAD_ARGS

        ; Save length

        PUSH HL
        EX DE,HL
        LD (LOADBIN_BYTE_COUNT),HL
        EX DE,HL
        POP HL

        CALL SKIP_SPACES

        ; Do not allow additional arguments

        LD A,(HL)
        OR A
        JP NZ,CMD_BAD_ARGS

        ; Check that address + length does not
        ; exceed F000h. Exclusive F000h is
        ; valid as the final limit.

        LD HL,(LOAD_ADDRESS)
        LD DE,(LOADBIN_BYTE_COUNT)
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
        ; Notify the sender before receiving data.

        LD HL,LOADBIN_READY_TEXT
        CALL SERIAL_PRINT

        LD HL,(LOAD_ADDRESS)
        LD BC,(LOADBIN_BYTE_COUNT)

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
; COMMAND: load AAAA
;
; Example:
;   load 8000
;   3E 41 D3 20 76
;   .
;
; Loads hexadecimal bytes into RAM.
; A period ends the load.
;
; Allowed destination range:
;   8000h - EFFFh
; ==========================================

CMD_LOAD:
        CALL PARSE_HEX16
        JP NC,CMD_BAD_ARGS

        ; RAM starts at 8000h

        LD A,D
        CP 080h
        JP C,LOAD_RANGE_ERROR

        ; Reserve F000h and above
        ; for the buffer and variables.

        CP 0F0h
        JP NC,LOAD_RANGE_ERROR

        ; Save destination address

        PUSH HL
        EX DE,HL
        LD (LOAD_ADDRESS),HL
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

        LD HL,COMMAND_BUFFER
        CALL SKIP_SPACES

        ; Is this a line containing only a period?

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
; PROCESS A LINE OF HEXADECIMAL BYTES
; ==========================================

LOAD_PARSE_BYTES:
        CALL SKIP_SPACES

        LD A,(HL)
        OR A
        JP Z,LOAD_LINE

        ; First hexadecimal digit

        CALL HEX_TO_NIBBLE
        JP NC,LOAD_BAD_DATA

        LD C,A
        INC HL

        ; Second hexadecimal digit

        LD A,(HL)
        CALL HEX_TO_NIBBLE
        JP NC,LOAD_BAD_DATA

        LD B,A

        ; Combine the two nibbles

        LD A,C

        RLCA
        RLCA
        RLCA
        RLCA

        OR B
        LD C,A

        INC HL

        ; The byte must be followed by:
        ; a space or end of line.

        LD A,(HL)
        OR A
        JR Z,LOAD_STORE_BYTE

        CP 020h
        JP NZ,LOAD_BAD_DATA

LOAD_STORE_BYTE:
        ; Do not write at F000h or above.

        LD A,(LOAD_ADDRESS+1)
        CP 0F0h
        JP NC,LOAD_RANGE_ERROR

        ; Store byte at the current address.

        LD A,C

        PUSH HL

        LD HL,(LOAD_ADDRESS)
        LD (HL),A

        INC HL
        LD (LOAD_ADDRESS),HL

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
; SYNTAX ERROR
; ==========================================

CMD_BAD_ARGS:
        LD HL,SYNTAX_ERROR_TEXT
        CALL SERIAL_PRINT

        JP MONITOR_LOOP


; ==========================================
; MATCH COMMAND
;
; Input:
;   HL = input buffer
;   DE = word to compare
;
; Output:
;   Carry = 1 if it matches
;   HL points to the arguments,
;   after skipping spaces.
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
; READ LINE FROM TERMINAL
;
; Ends with CR.
; Ignores LF.
; Supports deletion with Backspace.
;
; Maximum: 127 characters.
; ==========================================

READ_LINE:
        LD HL,COMMAND_BUFFER
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

        ; Preserve the character while checking the buffer.
        PUSH AF
        LD A,B
        OR A
        JR Z,READ_BUFFER_FULL
        POP AF

        ; Echo and store the received character.
        CALL UART_PUTC
        LD (HL),A
        INC HL
        DEC B
        JR READ_CHAR

READ_BUFFER_FULL:
        POP AF
        JR READ_CHAR

READ_BACKSPACE:
        ; Do not move before the start of the buffer.
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
; READ A CHARACTER FROM UART
; Output: A = received character
; ==========================================

UART_GETC:
UART_WAIT_RX:
        IN A,(UART_PORT+5)
        BIT 0,A
        JR Z,UART_WAIT_RX

        IN A,(UART_PORT+0)
        RET


; ==========================================
; PARSE 16-BIT HEXADECIMAL NUMBER
;
; Input:
;   HL points to four hexadecimal digits.
;
; Output:
;   DE = converted value
;   HL advances by four characters
;   Carry = 1 if valid
; ==========================================

PARSE_HEX16:
        LD DE,0000h
        LD B,004h

PARSE_HEX16_LOOP:
        LD A,(HL)
        CALL HEX_TO_NIBBLE
        JR NC,PARSE_HEX16_BAD

        LD C,A

        ; Shift DE left by four bits.

        SLA E
        RL D

        SLA E
        RL D

        SLA E
        RL D

        SLA E
        RL D

        ; Add the new nibble.

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
; CONVERT HEXADECIMAL CHARACTER
;
; Input: A = ASCII character
; Output: A = value 0..15
;         Carry = 1 if valid
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

        ; Lowercase letters a-f

        SUB 057h
        SCF
        RET

HEX_UPPER:
        ; Uppercase letters A-F

        SUB 037h
        SCF
        RET

HEX_NUMERIC:
        ; Digits 0-9

        SUB 030h
        SCF
        RET

HEX_INVALID:
        OR A
        RET


; ==========================================
; SKIP SPACES
;
; Input: HL points to the text.
; Output: HL points to the next character
;         that is not a space.
; ==========================================

SKIP_SPACES:
        LD A,(HL)
        CP 020h
        RET NZ

        INC HL
        JR SKIP_SPACES


; ==========================================
; HD44780 LCD INITIALIZATION
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

        ; Display off

        LD A,008h
        CALL LCD_CMD

        ; Clear display

        LD A,001h
        CALL LCD_CMD
        CALL DELAY_LONG

        ; Entry mode

        LD A,006h
        CALL LCD_CMD

        RET


; ==========================================
; SEND LCD COMMAND
; Input: A = command
; ==========================================

LCD_CMD:
        LD B,A

        XOR A
        OUT (CONTROL_PORT),A

        LD A,B
        OUT (LCD_PORT),A

        CALL DELAY_SHORT
        RET


; ==========================================
; SEND LCD DATA
; Input: A = character
; ==========================================

LCD_DATA:
        LD B,A

        LD A,002h
        OUT (CONTROL_PORT),A

        LD A,B
        OUT (LCD_PORT),A

        CALL DELAY_SHORT
        RET


; ==========================================
; PRINT STRING ON LCD
; Input: HL = address
; Terminator: 00h
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
; PRINT STRING THROUGH UART
; Input: HL = address
; Terminator: 00h
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
; TRANSMIT CHARACTER THROUGH UART
; Input: A = character
; ==========================================

UART_PUTC:
        LD C,A

UART_WAIT_TX:
        IN A,(UART_PORT+5)
        BIT 5,A
        JR Z,UART_WAIT_TX

        LD A,C
        OUT (UART_PORT+0),A

        RET


; ==========================================
; PRINT BYTE AS TWO HEX DIGITS
; Input: A = byte
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
; PRINT HEXADECIMAL DIGIT
; Input: A = 0..15
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
; LCD DELAYS
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
; LCD TEXT
; ==========================================

TITLE_TEXT:
        DB "-Z80 mainboard-",00h

MONITOR_PREFIX:
        DB "Monitor  ",00h

; Version
VERSION_TEXT:
        DB "v.1.003",00h

; ==========================================
; SERIAL TEXT
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
        DB "Available commands  :",0Dh,0Ah
        DB "  help              - Show this help",0Dh,0Ah
        DB "  load AAAA         - Load hex bytes from AAAA address RAM (interactive)",0Dh,0Ah
        DB "  loadbin AAAA NNNN - Receive NNNN binary bytes",0Dh,0Ah
        DB "  dump AAAA BBBB    - Dump memory range from AAAA to BBBB",0Dh,0Ah
        DB "  go AAAA           - Execute at address AAAA",0Dh,0Ah,00h

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
