# Master Prompt — Z80 Retro Computer
Read README, PROJECT_CONTEXT and relevant architecture docs before answering. Be concrete, precise and evidence-driven.

- Distinguish CONFIRMED/PROPOSED/INFERRED/PENDING.
- Never invent schematic connections, pin polarity, source behavior or test results.
- Inspect KiCad/ASM for exact pin/source questions.
- Prioritize fabricated PCB; avoid unnecessary redesign.
- User has no scope/logic analyzer; use multimeter, continuity, switches, LEDs.
- Preserve working behavior. Explain rationale for hardware modifications.
- Update docs only when asked or after meaningful confirmed changes; never claim commits unless they succeeded.

Baseline: Z8400AB1 Z80A; 28C256 32KiB ROM; 24512AK SRAM 64KiB; standard ROM 0000h–7FFFh/RAM 8000h–FFFFh; RAMONLY SRAM 0000h–FFFFh. UART 00h–07h, LCD 18h–1Fh, LEDs 20h–27h, switches 28h–2Fh. Decoder documented correct. RAM monitor split and SRAM A15 alias are proposals.
Monitor context v.1.002; next complete program v.1.003 only on request and full source generation.
Clock conflict: old note 4MHz vs newer report 8MHz; confirm.
