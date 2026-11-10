# Z80 Retro Computer — Project Instructions

## General

- This is a homebrew computer based on the Zilog Z80A processor.
- Preserve the existing hardware architecture unless explicitly asked to change it.
- Inspect existing files before proposing or implementing modifications.
- Do not invent hardware capabilities or assume unverified functionality.

## Hardware

- CPU: SGS/ST Z8400AB1 Z80A&#x20;
- ROM: AT28C256, 32 KiB.
- SRAM: W24512AK, 64 KiB.
- Standard memory mode:
  - ROM: 0000h–7FFFh.
  - SRAM: 8000h–FFFFh.
- RAM_ONLY mode and ROM-to-RAM transition are not yet validated.

## Firmware

- Target processor: Z80.
- Assembly language: Z80 ASM.
- Preserve compatibility with the existing assembler workflow.
- Check memory addresses, register usage and stack placement carefully.
- Do not overwrite reserved memory areas.
- Preserve existing firmware behavior unless a change is requested.

## Documentation

- All repository documentation must be written in English.
- Use hexadecimal addresses with the h suffix, e.g. 8000h.
- Clearly distinguish:
  - CONFIRMED: tested and working.
  - PROPOSED: not implemented.
  - PENDING: awaiting validation.
- Do not describe proposed functionality as implemented.

## Python utilities

- Preserve compatibility with Python 3.
- Check existing command-line arguments and behavior before modifying utilities.
- Do not change serial communication protocols without explicit approval.

## Git

- Inspect the working tree before making changes.
- Never overwrite unrelated user modifications.
- Summarize modified files and explain the changes.
- Do not commit or push without explicit permission.

## Project Documentation and Context

Before working on the project, consult the relevant documentation.

### Mandatory project context
- `MASTER_PROJECT_CONTEXT.md`: consolidated technical context, hardware details, design decisions, validation status and pending work.
- `PROJECT_CONTEXT.md`: supplementary project context. Check for differences with the master document.
- `CHANGELOG.md`: project history and documentation changes.

### Hardware and architecture
- `architecture/memory_map.md`: memory organization.
- `architecture/memory_decoder.md`: ROM/RAM decoding logic and equations.
- `architecture/io_map.md`: I/O address allocation.
- `architecture/boot_sequence.md`: startup sequence and ROM-to-RAM transition.
- `architecture/uart.md`: WD8250 UART configuration.
- `architecture/lcd.md`: LCD interface and historical test code.
- `hardware/hardware_notes.md`: PCB, reset circuit and hardware troubleshooting.
- `hardware/datasheets.md`: component datasheets and technical references.

### Firmware
- `firmware/monitor/README.md`: monitor build and programming workflow.
- `firmware/tests/README.md`: hardware and firmware test status.
- `firmware/utils/`: Python utilities for ROM image generation and UART binary transfer.

### Documentation rules
- Read the relevant documentation before modifying hardware or firmware.
- Update the corresponding documentation whenever a confirmed design decision or test result changes.
- Keep hardware facts, firmware implementation and proposed functionality clearly separated.
- Do not treat historical test code as the current firmware implementation.
- When documents disagree, identify the discrepancy instead of silently choosing one version.
- Prefer the actual KiCad schematic and current ASM source over historical notes when verifying physical connections or firmware behavior.