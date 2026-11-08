# Memory Decoder

A15, effective ROMENABLE, MREQ (active-low). ROM_CS/RAM_CS active-low.

```
nA15 = NOT A15
nROMENABLE = NOT ROMENABLE
nMREQ = NOT MREQ
ROM_CS = NOT[(ROMENABLE AND nA15) AND nMREQ]
RAM_CS = NOT[(A15 OR nROMENABLE) AND nMREQ]
```

When MREQ=0:
| ROMENABLE | A15 | ROM selected | RAM selected |
|---:|---:|---|---|
| 0 | 0 | No | Yes |
| 0 | 1 | No | Yes |
| 1 | 0 | Yes | No |
| 1 | 1 | No | Yes |

Matches ROM low half with ROM enabled, SRAM high half, and SRAM full map when ROM disabled. Decoder documented as correct.

## Pin connections (recorded)
74HC04: A15 pin1→2 nA15; ROMENABLE pin5→6 nROMENABLE; MREQ pin11→10 nMREQ. Pin3 ← HC08 pin6, pin4 ROM_CS; pin8 and pin9 recorded from HC08 pin8.
74HC08: pin1 ROMENABLE, pin2 nA15, pin3 ROMENABLE AND nA15; pin4←pin3; pin5 nMREQ; pin6 ROM path AND; pin9←HC32 pin3; pin10 nMREQ; pin8 RAM path AND.
74HC32: pin1 A15, pin2 nROMENABLE, pin3=A15 OR nROMENABLE.
Consult current schematic before any pin-level change. SRAM A15 address transformation is separate from decoder A15/RAM_CS.
