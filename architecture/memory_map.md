# Memory Map

## Standard mode (confirmed)
| Range | Device |
|---|---|
| 0000h–7FFFh | 28C256 ROM |
| 8000h–FFFFh | SRAM (32KiB visible) |

7FFFh is ROM, not RAM. Stack in RAM before CALL/RET (e.g. SP=FFFFh).

## RAMONLY (confirmed)
| Range | Device |
|---|---|
| 0000h–FFFFh | SRAM (64KiB) |

## Proposed resident map (not implemented)
| Range | Purpose |
|---|---|
| 0000h–0FFFh | Monitor, variables, input buffer, private stack (4KiB) |
| 1000h–FFFFh | User RAM (60KiB) |

Confirm assembled resident size includes code, UART routines, vars, buffer and stack. Historical F000h–FFFFh monitor reservation is software-only.

## Transition notes
ROM reads are low logical addresses; current RAM_CS selects upper logical addresses when ROM is enabled. SRAM A15 aliasing is a proposal. Copy and ROM disable must account for SRAM CS, physical address mapping and next PC fetch. Design a valid trampoline; do not assume transition safe.
