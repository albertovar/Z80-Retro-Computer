# Z80 Retro Computer — Master Project Context

This document is the consolidated project context and technical reference for future development and troubleshooting. **All repository documentation must be written in English**, even when discussions with the assistant are in Spanish.

## Assistant guidelines
- Provide concrete, direct, technically precise instructions.
- Prioritize the fabricated PCB; avoid unnecessary redesign.
- Clearly label facts as **CONFIRMED**, ideas as **PROPOSED**, and unresolved items as **PENDING**.
- Do not invent pins, nets, polarity, or source details. Inspect the actual schematic and ASM when needed.
- The user has no oscilloscope or logic analyzer; use multimeter, continuity, LEDs, and switches.
- Separate signal name, physical pin, polarity, and activation condition.
- Prefer equations and truth tables. Do not repeat disproved diagnoses.

## Project and PCB
- Z80A-based retro computer on a fabricated and populated 2-layer PCB, designed in KiCad 10.
- Freerouting 2.2.4 fixed an SES parsing issue in 2.2.3.
- DRC before fabrication: zero violations and zero unconnected items.
- Focus on testing, bring-up, and firmware rather than redesign.

## CPU and reset
CPU: SGS/ST Z8400AB1 Z80A, DIP-40.
- RESET pin 26, active-low; BUSREQ pin 25, WAIT pin 24, BUSACK pin 23, WR pin 22, RD pin 21, IORQ pin 20, MREQ pin 19, HALT pin 18, INT pin 16, NMI pin 17, CLK pin 6, +5 V pin 11, GND pin 29.
- A0–A10: pins 30–40; A11 pin 1, A12 pin 2, A13 pin 3, A14 pin 4, A15 pin 5. RESET is pin 26; pin 35 is A5.
- BUSREQ, WAIT, INT and NMI are normally held inactive HIGH with 10k pull-ups.
- NOP (00h) takes 4 T-states. HALT opcode is 76h. Z80 refresh behavior can cause misleading address LED patterns around 80h.
- Reset circuit uses RC, pushbutton and two 74HC14 inverters. RESET is LOW normally and HIGH while reset is asserted; RESET_INV is HIGH normally and LOW during reset.
- Z80 RESET pin 26 and 74HC273 active-low MR receive RESET_INV. WD8250 active-high MR pin 35 and 82C55 active-high reset receive RESET.
- Z80 reset must be asserted for at least three complete clock cycles.

## Confirmed bring-up milestone (2026-09-10)
Reset, ROM fetch, execution, HALT, ROM/RAM selection, ROM reads and 74HC138 outputs were tested. Apparent random address/data LED patterns during slow/manual clocking were misleading. Do not redesign the bus or decoder based on those observations.

## Memory architecture
- ROM: 28C256, 32 KiB.
- SRAM: 24512AK, 64 KiB × 8; SRAM A0–A15 were originally connected directly to Z80 address lines.
- **Standard mode:** ROM at 0000h–7FFFh; SRAM at 8000h–FFFFh.
- **RAMONLY mode:** SRAM at 0000h–FFFFh.
- 7FFFh is ROM in standard mode. Set SP to valid RAM (e.g. FFFFh) before CALL/RET.
- Existing monitor software reserves F000h–FFFFh for buffer, variables and stack; this is not hardware-protected.
- **PROPOSED, not implemented:** RAMONLY monitor at 0000h–0FFFh (4 KiB), user RAM at 1000h–FFFFh (60 KiB). Confirm resident code, routines, variables, buffer and stack all fit. User previously reported about 1691 bytes of monitor code excluding ROM padding and CRC; this is not a verified resident-image size.

## Memory decoder — confirmed
Inputs: A15, effective ROMENABLE, MREQ. ROM_CS and RAM_CS are active-low.

Logic:
```
ROM_CS = NOT[(ROMENABLE AND NOT A15) AND NOT MREQ]
RAM_CS = NOT[(A15 OR NOT ROMENABLE) AND NOT MREQ]
```
Equivalent named signals:
- nA15 = NOT A15
- nROMENABLE = NOT ROMENABLE
- nMREQ = NOT MREQ
- ROM_CS = NOT[(ROMENABLE AND nA15) AND nMREQ]
- RAM_CS = NOT[(A15 OR nROMENABLE) AND nMREQ]

Recorded connections:
- 74HC04: A15 pin 1 → pin 2 (nA15); ROMENABLE pin 5 → pin 6 (nROMENABLE); MREQ pin 11 → pin 10 (nMREQ). Pin 3 receives 74HC08 pin 6; pin 4 is ROM_CS. Pins 8/9 are associated with the 74HC08 pin 8 RAM path as recorded in the schematic notes.
- 74HC08: pin 1 ROMENABLE; pin 2 nA15; pin 3 = ROMENABLE AND nA15; pin 4 receives pin 3; pin 5 nMREQ; pin 6 ROM path AND result; pin 9 receives 74HC32 pin 3; pin 10 nMREQ; pin 8 RAM path AND result.
- 74HC32: pin 1 A15; pin 2 nROMENABLE; pin 3 = A15 OR nROMENABLE.

For MREQ=0:
| ROMENABLE | A15 | ROM | RAM |
|---|---|---|---|
| 0 | 0 | OFF | ON |
| 0 | 1 | OFF | ON |
| 1 | 0 | ON | OFF |
| 1 | 1 | OFF | ON |

The decoder is considered correct for the intended architecture. Do not conflate the SRAM address A15 modification proposal with RAM_CS selection logic.

## ROM control latch
- 74HC273 MR is active-low.
- Q0/pin 2 is associated with ROM control. Reset clears latch outputs; inversion before the decoder means effective ROMENABLE is HIGH after reset.
- Keep physical Q0 distinct from effective ROMENABLE.
- Q1/pin 5 drives LCD_RS.

## I/O map
| Address range | Device | Decoder |
|---|---|---|
| 00h–07h | WD8250 UART | Y0 |
| 08h–0Fh | 82C55 PPI | Y1 |
| 10h–17h | 74HC273 CONTROL latch | Y2 |
| 18h–1Fh | HD44780 LCD | Y3 |
| 20h–27h | LEDs | Y4 |
| 28h–2Fh | Switches / 74HC244 | Y5 |
| 30h–37h | Expansion A | Y6 |
| 38h–3Fh | Expansion B | Y7 |

74HC138 has two active-low enables and one active-high enable. IORQ is active-low. Verify actual pin polarity before changing wiring.

## WD8250 UART
- UART I/O range 00h–07h, Y0.
- Clock: 1.8432 MHz; 115200 baud, 8N1, divisor 1.
- LSR offset 5; DR bit 0; THRE bit 5.
- BAUDOUT pin 15 → RCLK pin 9.
- MR pin 35 is active-high and receives RESET.
- D0–D7 connect to data bus; A0–A2 to Z80 A0–A2.
- /DISTR pin 21 is associated with /RD; /DOSTR pin 18 with /WR; ADS must be appropriate when address/select are stable.
- RX/TX tested.
- Terminal command: `screen /dev/ttyUSB0 115200`; exit with Ctrl+A, K, Y.
- In the proposed RAM-resident monitor, reuse the configured UART without reinitializing it unless explicitly requested.

## LCD
- HD44780-compatible LCD is independent of the 82C55.
- D0–D7 connect to Z80 data bus.
- RS connects directly to 74HC273 Q1/pin 5 (no inversion).
- E is driven from 74HC138 Y3 through an inverter (active-low decoder output to active-high LCD E).
- R/W is tied to GND (write-only).
- I/O range 18h–1Fh; RS=0 selects commands, RS=1 data.
- LCD initialization and boot banner are intended for ROM startup in the proposed architecture.
- See `architecture/lcd.md` for the historical LCD initialization/test program.

## Switches and LEDs
- Switches use 74HC244 at 28h–2Fh/Y5.
- `/OE = SWITCH_CS OR RD` through a 74HC32. Since both inputs are active-low, 74HC244 is enabled only when SWITCH_CS=0 and RD=0.
- RD was previously left floating and then corrected.
- Validated test:
```asm
        IN A,(28h)
        OUT (20h),A
        HALT
```
- LEDs are on port 20h–27h through a 74HC273. Both switch and LED paths have been validated.

## 82C55 PPI
- I/O range 08h–0Fh/Y1.
- Reset is active-high.
- Do not invent port assignments or behavior not confirmed by the schematic/source.

## EEPROM programming history
- T48/Minipro successfully wrote, read and verified the AT28C256.
- Historical manual programming used 4.7k pull-downs, switches to VCC and manual /WE pulses; setting a bit to 1 previously resulted in FF.
- Revisit only if the issue recurs. Check CE/OE/WE, address/data stability, polarity, actual levels and pull-downs; do not assume delay is the cause.

## KiCad and PCB notes
- KiCad 10.0.4 on macOS.
- Freerouting 2.2.4 fixed SES parsing issues seen in 2.2.3.
- Ground zone: draw filled zone on copper layer, assign GND, refill with B.
- F.Mask/B.Mask are solder-mask openings, not copper; include them in Gerber output.
- If GND seems disconnected, inspect layer, clearance, thermal connection, net and refill status.
- Do not invent menu names for duplicate-track removal.

## Monitor text and versioning
Current ASM definitions:
- TITLE_TEXT: `-Z80 mainboard-`
- MONITOR_PREFIX: `Monitor  `
- START_TEXT contains CR/LF and `Z80 mainboard - AlberTovar@gmail.com - 2026`
- VERSION_TEXT: `v.1.002`
- Define the version string only once and reuse it.
- Next complete monitor version should be v.1.003. Do not increment for planning or partial edits; increment only when producing a complete new monitor program.

## Proposed ROM startup / RAM-resident monitor split (not implemented)
ROM startup:
1. Initialize LCD and display identification/version.
2. Initialize WD8250 for 115200, 8N1.
3. Calculate CRC.
4. Report CRC result over serial.
5. Copy resident monitor to SRAM only if CRC passes.
6. Perform a safe ROM-to-RAM transition.
7. On CRC failure, remain in a safe ROM-side error state.

RAM-resident monitor:
- Command interpreter and handlers (help/load/loadbin/dump/go as confirmed in the actual ASM).
- UART routines using the already initialized WD8250.
- Variables, command buffer and private stack in 0000h–0FFFh.
- Protect 0000h–0FFFh from user writes and permit user area 1000h–FFFFh according to command range semantics.
- Exclude ROM-only LCD startup/banner, CRC calculation/reporting and UART initialization.
- Do not produce the complete revised monitor until the user asks. First inspect current ASM, establish exact section boundaries, resident size, variables/buffer/stack, copy range and transition.

## CRC
CRC-16/CCITT-FALSE:
- Initial value FFFFh.
- Polynomial 1021h.
- MSB-first.
- Calculated over 0000h–7FFDh.
- Stored at 7FFEh–7FFFh, MSB first.
- ROM image is padded/fill-sized to 32768 bytes.

## SRAM A15 and ROM/RAM transition — proposal only
- **PROPOSED, not implemented:** `A15_SRAM = A15_Z80 AND RAMONLY`.
- RAMONLY=0 during ROM startup/copy would force SRAM physical A15 low; RAMONLY=1 would pass Z80 A15.
- SRAM chip select must continue to use original Z80 A15 unless the schematic explicitly changes it.
- With ROM enabled, SRAM is selected at logical 8000h–FFFFh. Copying ROM data to SRAM physical lower 32 KiB would require correct address aliasing and write conditions.
- A15 manipulation alone does not guarantee the transition works.
- The Z80 fetches the next instruction after the ROM-control write. Ensure the corresponding SRAM address contains valid continuation code or use a carefully designed trampoline.
- Verify exact schematic, latch polarity, SRAM pin and source ASM before wiring or coding.


## TODO / pending work
1. **Validate the 82C55 PPI hardware and software.** It has not been tested yet because it was not a priority. Verify basic read/write operation and document the actual port configuration and behavior.
2. **Validate the ROM-to-RAM switch at address 0000h.** Test whether the spare AND gate intended for the SRAM A15 path, with Z80 A15 and ROM_ENABLE as its inputs, can implement the required ROM-to-RAM switching so execution can begin at SRAM address 0000h. This is a proposal only; verify signal polarity, actual schematic wiring, SRAM address mapping, and the transition before considering it confirmed.
3. **Adapt a CP/M clone to this Z80 Retro Computer.** Select a suitable clone/version and determine the required memory layout, BIOS/BDOS/CCP integration, UART console support, and boot path once the memory-switching design is validated.

## Open items / uncertainties
- Clock discrepancy: earlier notes say 4 MHz; later discussion mentioned 8 MHz. Confirm the actual current clock before relying on it.
- Inspect current ASM and determine actual resident monitor size.
- Validate SRAM A15 proposal and ROM/RAM transition.
- Confirm command set from the latest source.

## Firmware utility scripts
- Utilities live in `firmware/utils/`: `make_rom.py` and `sendbin.py`.
- `make_rom.py` takes the assembled binary (e.g. `monitor.bin`), pads it with `00h` through 7FFDh, computes CRC-16/CCITT-FALSE over 0000h–7FFDh, stores the CRC MSB-first at 7FFEh–7FFFh, and writes a 32 KiB output image (e.g. `monitor_CRC.bin`). The monitor uses this CRC to check ROM integrity. **Program the generated `*_CRC.bin` image into the ROM**, not the original assembler output. Example: `python3 make_rom.py monitor.bin monitor_CRC.bin`.
- `sendbin.py` transfers a binary to the monitor over UART (115200 baud) using the monitor's `loadbin` command and waits for READY and `loadbin complete`.
- Example: `python3 firmware/utils/sendbin.py /dev/ttyUSB0 8000 SWITCHES_monitor.bin`. The address argument is parsed as hexadecimal.
- In standard memory mode, ROM is mapped at 0000h–7FFFh and SRAM at 8000h–FFFFh; thus the first RAM address is **8000h**.
- The current `sendbin.py` restricts the load address to 8000h–EFFFh and prevents transfers crossing F000h, preserving the monitor's reserved F000h–FFFFh area.
- Requires Python 3 and `pyserial`.
