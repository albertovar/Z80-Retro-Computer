# Z80 Retro Computer

Documentation for a Z80A-based computer built on a fabricated two-layer PCB.

**Status:** CPU reset/ROM fetch/execution/HALT, ROM/RAM selection, LCD, UART, switches and LEDs have been validated. The RAM-resident monitor and ROM-to-RAM transition are still proposals.

## Architecture
- CPU: SGS/ST Z8400AB1 Z80A.
- EEPROM: 28C256, 32 KiB; SRAM: 24512AK, 64 KiB × 8.
- Standard mode: ROM at 0000h–7FFFh; SRAM at 8000h–FFFFh.
- RAMONLY mode: SRAM at 0000h–FFFFh.
- ROM_CS and RAM_CS are active-low. The current decoder is documented as correct.
- ROM control via 74HC273; Q0 is associated with ROM control, with inversion to obtain effective ROMENABLE.
- I/O decoding via 74HC138.

### Memory map

The Z80 has a 64 KiB address space. The board supports two memory configurations:

#### Standard mode (ROM enabled)

| Z80 address range | Size | Device | Description |
|---|---:|---|---|
| `0000h–7FFFh` | 32 KiB | AT28C256 EEPROM | ROM at the bottom of memory; execution after reset starts here. |
| `8000h–FFFFh` | 32 KiB | SRAM | RAM in the upper half; first RAM address is `8000h`. |

The monitor reserves `F000h–FFFFh` for its buffer, variables and stack. This is a firmware convention, not a hardware reservation.

#### RAMONLY mode (ROM disabled)

| Z80 address range | Size | Device | Description |
|---|---:|---|---|
| `0000h–FFFFh` | 64 KiB | SRAM | SRAM occupies the entire address space; ROM is not visible. |

A proposed RAMONLY software layout is monitor at `0000h–0FFFh` and user RAM at `1000h–FFFFh`. **This layout and the ROM-to-RAM transition are not implemented or validated.**

| Feature | Standard mode | RAMONLY mode |
|---|---|---|
| `0000h–7FFFh` | ROM | SRAM |
| `8000h–FFFFh` | SRAM | SRAM |
| Reset vector `0000h` | ROM | SRAM (must contain valid startup code) |
| RAM available in hardware map | 32 KiB | 64 KiB |

| Port range | Peripheral | Decoder output |
|---|---|---|
| 00h–07h | WD8250 UART | Y0 |
| 08h–0Fh | 82C55 PPI | Y1 |
| 10h–17h | 74HC273 CONTROL latch | Y2 |
| 18h–1Fh | HD44780 LCD | Y3 |
| 20h–27h | LEDs | Y4 |
| 28h–2Fh | Switches / 74HC244 | Y5 |
| 30h–37h | Expansion A | Y6 |
| 38h–3Fh | Expansion B | Y7 |

### Peripherals
- WD8250: 1.8432 MHz clock, 115200 baud, 8N1, divisor 1; RX/TX tested.
- LCD: D0–D7 on the Z80 data bus; RS from Q1/pin 5 of the 74HC273; E from Y3 through an inverter; R/W tied to GND.
- Switches: 74HC244; `/OE = SWITCH_CS OR RD` using a 74HC32; tested.
- LEDs: port 20h, 74HC273 latch; tested.
- 82C55 reset is active-high.

### Boot and monitor
The planned ROM startup performs LCD/banner display, UART initialization, CRC verification and monitor copying. Proposed RAMONLY layout: monitor at 0000h–0FFFh and user RAM at 1000h–FFFFh. **Not implemented or validated yet.** SRAM A15 gating, the copy algorithm and the ROM-disable trampoline require schematic and ASM review.

### ROM CRC
CRC-16/CCITT-FALSE, initial value FFFFh, polynomial 1021h, MSB-first; covers bytes 0000h–7FFDh; CRC stored at 7FFEh–7FFFh. ROM image is padded to 32768 bytes.

## Validated status
Reset, ROM fetch, execution, HALT, ROM/RAM decoding, LCD, UART, switches and LEDs. Available troubleshooting tools: multimeter, continuity checks, switches and LEDs; no oscilloscope or logic analyzer.

## Documentation
- [Master project context](PROJECT_CONTEXT.md)
- [Memory map](architecture/memory_map.md)
- [Memory decoder](architecture/memory_decoder.md)
- [I/O map](architecture/io_map.md)
- [Boot sequence](architecture/boot_sequence.md)
- [UART](architecture/uart.md)
- [LCD](architecture/lcd.md)
- [Hardware notes](hardware/hardware_notes.md)
- [Prompts](prompts/README.md)
- [Changelog](CHANGELOG.md)

**Status labels:** CONFIRMED = validated; PROPOSED = not implemented; PENDING = requires review or testing. Avoid unnecessary changes to the fabricated PCB.
