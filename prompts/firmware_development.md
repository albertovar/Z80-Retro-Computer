# Prompt — Z80 Firmware
Inspect latest ASM and docs; confirm z80asm dialect, ORG, memory map, stack, I/O, clock, buffers and code boundaries. Preserve working behavior. Consider CALL/RET stack, flags, register preservation and wraparound.

For proposed RAM monitor: 0000h–0FFFh reserved; user memory 1000h–FFFFh. Verify code+routines+vars+buffer+stack fit. Protect monitor from load/loadbin. UART remains initialized by ROM stage. LCD startup/CRC/UART init are ROM-only. Analyze ROM copy mapping and trampoline based on actual schematic. Do not assume fetch after ROM disable is safe.

For a complete monitor program, provide complete source unless asked for patch; centralize VERSION_TEXT. v.1.002 current; next full version v.1.003. Include build/CRC/test instructions. Never claim assembled/tested unless actually done.
