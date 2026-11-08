# Z80 Retro Computer — Master Project Context

## Assistant guidelines
- Concrete, direct, technically precise.
- Prioritize fabricated PCB; avoid unnecessary redesign.
- Mark facts CONFIRMED, ideas PROPOSED, unresolved PENDING.
- Do not invent pins/nets/polarity or assume source details. Inspect KiCad/ASM.
- User has no scope/logic analyzer; use multimeter, continuity, LEDs, switches.
- Separate signal name, physical pin, polarity, activation condition.
- Prefer equations and truth tables; don't repeat disproved diagnoses.

## PCB / project
Z80A computer; 2-layer KiCad 10 PCB fabricated/populated. Freerouting 2.2.4 fixed SES issue from 2.2.3. DRC before fabrication: zero violations/unconnected. Focus on tests and firmware.

## CPU
SGS/ST Z8400AB1 Z80A DIP40.
- RESET pin26 active-low; BUSREQ25 active-low; WAIT24 active-low; BUSACK23; WR22; RD21; IORQ20; MREQ19; HALT18 active-low; INT16 active-low; NMI17 edge; CLK6; +5 pin11; GND29.
- A0–A10 pins30–40; A11 pin1, A12 pin2, A13 pin3, A14 pin4, A15 pin5. RESET is pin26; pin35 is A5.
- BUSREQ/WAIT/INT/NMI held inactive HIGH with 10k pullups.
- NOP 00h takes 4 T-states; HALT 76h. Z80 refresh can cause apparent odd address LED patterns around 80h.
- Reset circuit RC/button/2×74HC14: RESET low normally, high during button; RESET_INV high normal, low during reset. Z80 RESET26 and 74HC273 MR active-low get RESET_INV. WD8250 MR35 and 82C55 reset active-high get RESET. Reset ≥3 full clock cycles.

## Bring-up milestone (2026-09-10)
Reset, ROM fetch, execution, HALT, ROM/RAM select, ROM reads confirmed. 74HC138 outputs tested. Slow/manual LED bus patterns were misleading; don't redesign bus based on them.

## Memory
- 28C256 ROM 32KiB; 24512AK SRAM 64KiB×8. SRAM A0–A15 originally direct to Z80.
- Standard mode: ROM 0000h–7FFFh; SRAM 8000h–FFFFh.
- RAMONLY: SRAM 0000h–FFFFh.
- 7FFFh is ROM in standard mode; set SP in RAM (e.g. FFFFh) before CALL/RET.
- Old monitor uses F000h–FFFFh for buffer/vars/stack, software reservation only.
- Proposed new RAMONLY software map: monitor 0000h–0FFFh (4KiB), user 1000h–FFFFh (60KiB). Not implemented. Verify resident size includes routines, vars, buffer and stack. User reports current code ~1691 bytes excluding ROM fill/CRC; not final resident size.

## Memory decoder (confirmed)
Inputs A15, effective ROMENABLE, MREQ. ROM_CS/RAM_CS active-low.
74HC04: A15 pin1→pin2 nA15; ROMENABLE pin5→pin6 nROMENABLE; MREQ pin11→pin10 nMREQ. Pin3 ← 74HC08 pin6; pin4 ROM_CS; pin8/pin9 recorded from 74HC08 pin8.
74HC08: pin1 ROMENABLE; pin2 nA15; pin3 ROMENABLE AND nA15; pin4 ← pin3; pin5 nMREQ; pin6 ROM path AND; pin9 ← 74HC32 pin3; pin10 nMREQ; pin8 RAM path AND.
74HC32: pin1 A15; pin2 nROMENABLE; pin3=A15 OR nROMENABLE.
Equations:
ROM_CS = NOT[(ROMENABLE AND nA15) AND nMREQ]
RAM_CS = NOT[(A15 OR nROMENABLE) AND nMREQ]
MREQ=0: ROMENABLE/A15: 0/0→ROMoff RAMon; 0/1→ROMoff RAMon; 1/0→ROMon RAMoff; 1/1→ROMoff RAMon.
Decoder considered correct. Don't conflate SRAM A15 address with RAM_CS decoder.

## ROM latch
74HC273 MR active-low; Q0/pin2 associated with ROM control. Reset clears Q outputs; inverter makes effective ROMENABLE high after reset. Q0 physical vs ROMENABLE effective must be distinguished. LCD_RS Q1/pin5.

## I/O
00–07 UART Y0; 08–0F 82C55 Y1; 10–17 control latch Y2; 18–1F LCD Y3; 20–27 LEDs Y4; 28–2F switches Y5; 30–37 expansion A Y6; 38–3F expansion B Y7. 74HC138 two active-low enables, one active-high; IORQ active-low.

## UART WD8250
Clock 1.8432MHz; 115200 8N1, divisor 1; LSR offset5, DR bit0, THRE bit5. BAUDOUT pin15→RCLK pin9. MR pin35 active-high→RESET. D0–D7 bus; A0–A2 Z80 A0–A2. /DISTR21 related to /RD; /DOSTR18 related to /WR; ADS25 stable. UART RX/TX validated. Terminal: screen /dev/ttyUSB0 115200; exit Ctrl+A K Y. Proposed RAM monitor reuses configuration without reinit.

## LCD
Independent of 82C55. D0–D7 Z80 bus; RS directly Q1 pin5; E from Y3 through inverter; R/W GND; range 18h–1Fh; RS0 commands/RS1 data. LCD startup/banner ROM-only in proposed split. Historical init/test is in architecture/lcd.md.

## Switches/LEDs
Switches via 74HC244 at 28h–2Fh/Y5. /OE = SWITCH_CS OR RD via 74HC32; enabled when both active-low signals are low. RD was once floating and corrected. Validated test: IN A,(28h); OUT (20h),A; HALT. LEDs port20h–27h via 74HC273. Both validated.

## PPI
82C55 range 08h–0Fh; reset active-high. Do not invent port usage.

## EEPROM history
T48/Minipro successfully wrote/read/verified 28C256. Historical manual write with 4.7k pull-downs, switches to VCC and /WE pulse had symptom 1→FF. Only revisit if recurring; check CE/OE/WE, stable address/data, polarity, actual levels and pull-downs, not delay alone.

## KiCad / PCB
KiCad 10.0.4 macOS. Freerouting 2.2.4 fixed SES parsing issue. Ground zone: copper layer/net GND, refill B. F.Mask/B.Mask are solder-mask openings, not copper, include in Gerbers. Check layer, clearance, thermal, net and refill if GND connection appears missing. Avoid inventing duplicate-track menu names.

## Startup text/version
TITLE_TEXT “-Z80 mainboard-”; MONITOR_PREFIX “Monitor  ”; START_TEXT includes CR/LF and “Z80 mainboard - AlberTovar@gmail.com - 2026”; VERSION_TEXT “v.1.002”. Version label defined once. Next complete program version v.1.003 only when a complete monitor is requested/produced; don't bump for discussion.

## ROM/resident split proposal (not implemented)
ROM stage: LCD/banner; UART init; CRC; serial CRC report; copy resident monitor only if CRC OK; safe ROM disable transition. CRC failure stays in ROM error state.
Resident stage: command interpreter and handlers (help/load/loadbin/dump/go as confirmed by ASM); UART routines using existing configuration; vars/buffer/private stack at 0000h–0FFFh; load commands protect this region; user RAM 1000h–FFFFh. Exclude LCD boot text, CRC calculation, UART initialization.
Do not write full revised monitor until user asks. Inspect ASM, size, variables/buffer/stack, copy boundaries and transition first.

## CRC
CRC-16/CCITT-FALSE: init FFFFh, polynomial 1021h, MSB first, over 0000h–7FFDh; stored 7FFEh–7FFFh MSB first. ROM file padded to 32768 bytes.

## SRAM A15 proposal / critical transition
Proposal: A15_SRAM = A15_Z80 AND RAMONLY. RAMONLY=0 during ROM stage forces SRAM physical A15 low; RAMONLY=1 passes A15. Not implemented/verified. SRAM chip select still uses original Z80 A15. Current RAM_CS only selects SRAM for logical upper addresses while ROM is enabled. Copy logic must read ROM low and write SRAM through selected high logical addresses with correct physical alias. Z80 fetches next PC after ROM latch change; bytes there must be valid or use trampoline. Verify exact schematic/latch polarity/source ASM before wiring/coding.

## Open items
- Clock discrepancy: older project context says 4MHz; later user mentioned 8MHz. Confirm actual current frequency.
- Inspect current ASM and resident image size.
- Validate proposed A15 circuitry and ROM/RAM transition.
- Confirm current command set from latest source.
