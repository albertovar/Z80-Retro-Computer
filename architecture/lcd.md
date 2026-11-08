# LCD HD44780

## Confirmed
- LCD independent of 82C55.
- D0–D7 directly on Z80 bus.
- RS from 74HC273 Q1 pin5, direct/no inversion.
- E from 74HC138 Y3 through inverter (Y3 active-low, E active-high).
- R/W GND (write-only).
- Port 18h–1Fh; RS=0 commands, RS=1 data.
- LCD startup/banner intended for ROM startup, not RAM monitor.

## Historical first test
```asm
ORG 0000h
CONTROL EQU 10h
LCD_PORT EQU 18h
START:
    CALL DELAY_LONG
    XOR A
    OUT (CONTROL),A
    LD A,38h
    OUT (LCD_PORT),A
    CALL DELAY_SHORT
    LD A,38h
    OUT (LCD_PORT),A
    CALL DELAY_SHORT
    LD A,38h
    OUT (LCD_PORT),A
    CALL DELAY_SHORT
    LD A,08h
    OUT (LCD_PORT),A
    CALL DELAY_SHORT
    LD A,01h
    OUT (LCD_PORT),A
    CALL DELAY_LONG
    LD A,06h
    OUT (LCD_PORT),A
    CALL DELAY_SHORT
    LD A,0Ch
    OUT (LCD_PORT),A
    CALL DELAY_SHORT
    LD A,02h
    OUT (CONTROL),A
    LD HL,MESSAGE
PRINT:
    LD A,(HL)
    OR A
    JR Z,DONE
    OUT (LCD_PORT),A
    CALL DELAY_SHORT
    INC HL
    JR PRINT
DONE:
    HALT
MESSAGE:
    DB "Z80 mainboard",00h
DELAY_SHORT:
    LD B,20
DS1: DJNZ DS1
    RET
DELAY_LONG:
    LD B,255
DL1: LD C,255
DL2: DEC C
    JR NZ,DL2
    DJNZ DL1
    RET
```
Historical test code only; timing depends on clock.
