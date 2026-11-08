# Boot Sequence / ROM→RAM Proposal

## Confirmed
Reset, ROM fetch, execution and HALT; ROM/RAM selection; LCD, UART, switches and LEDs have been tested.

## Startup labels
TITLE_TEXT: “-Z80 mainboard-”
MONITOR_PREFIX: “Monitor  ”
START_TEXT: CR/LF + “Z80 mainboard - AlberTovar@gmail.com - 2026” + CR/LF
VERSION_TEXT: “v.1.002” (single definition reused).

## Proposed, not implemented
ROM stage: LCD init/banner → UART init 115200 8N1 → CRC → serial report → copy resident monitor if CRC passes → safe ROM-disable transfer. On CRC failure remain in ROM error state.
RAM monitor: commands, UART routines (reuse UART setup), vars/buffer/private stack in 0000h–0FFFh; user area 1000h–FFFFh. Exclude LCD startup, CRC calculation and UART init.

## Transition constraints
- ROM reads low logical addresses.
- SRAM chip select in standard mode is for logical upper half.
- Proposed SRAM A15_SRAM = A15_Z80 AND RAMONLY is unconfirmed and separate from RAM_CS.
- Copy mapping must account for source ROM low addresses and SRAM writes through selected upper addresses.
- Z80 fetches next instruction after latch write; SRAM must contain valid bytes at current PC or use a trampoline.
- Inspect actual schematic and latest ASM before coding; calculate copy size and resident layout.
