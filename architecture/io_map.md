# I/O Map

| Port | Peripheral | 74HC138 |
|---|---|---|
| 00h–07h | WD8250 UART | Y0 |
| 08h–0Fh | 82C55 | Y1 |
| 10h–17h | CONTROL/74HC273 | Y2 |
| 18h–1Fh | LCD | Y3 |
| 20h–27h | LEDs | Y4 |
| 28h–2Fh | switches/74HC244 | Y5 |
| 30h–37h | expansion A | Y6 |
| 38h–3Fh | expansion B | Y7 |

74HC138 has two active-low and one active-high enable. IORQ active-low; outputs active-low. Check physical polarity before hardware change.

## Switch enable (validated)
`/OE = SWITCH_CS OR RD` using 74HC32. The 74HC244 is enabled only when SWITCH_CS=0 and RD=0.

Test:
```asm
SWITCHES: EQU 28h
LEDS: EQU 20h
START:
    IN A,(SWITCHES)
    OUT (LEDS),A
    HALT
```
