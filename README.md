# Z80 Retro Computer

Documentación del ordenador Z80A sobre PCB de dos capas ya fabricada.

**Estado:** CPU reset/fetch ROM/ejecución/HALT, selección ROM/RAM, LCD, UART, switches y LEDs validados. Monitor RAM residente y transición ROM→RAM aún propuestos.

## Arquitectura
- CPU SGS/ST Z8400AB1 Z80A.
- EEPROM 28C256 32 KiB; SRAM 24512AK 64 KiB × 8.
- Modo estándar: ROM 0000h–7FFFh; SRAM 8000h–FFFFh.
- RAMONLY: SRAM 0000h–FFFFh.
- ROM_CS y RAM_CS activas en bajo. Decoder actual documentado como correcto.
- Control ROM por 74HC273; Q0 asociado a control ROM, inversión para ROMENABLE efectivo.
- I/O decode por 74HC138.

| Puerto | Periférico | Decoder |
|---|---|---|
| 00h–07h | WD8250 UART | Y0 |
| 08h–0Fh | 82C55 PPI | Y1 |
| 10h–17h | 74HC273 CONTROL | Y2 |
| 18h–1Fh | HD44780 LCD | Y3 |
| 20h–27h | LEDs | Y4 |
| 28h–2Fh | Switches/74HC244 | Y5 |
| 30h–37h | Expansión A | Y6 |
| 38h–3Fh | Expansión B | Y7 |

### Periféricos
- WD8250: clock 1.8432 MHz, 115200 baud, 8N1, divisor 1; RX/TX probado.
- LCD: D0–D7 en bus Z80; RS desde Q1/pin5 del 74HC273; E desde Y3 por inversor; R/W a GND.
- Switches: 74HC244, `/OE = SWITCH_CS OR RD` con 74HC32; probado.
- LEDs: puerto 20h, latch 74HC273; probado.
- 82C55 reset activo alto.

### Boot/monitor
ROM startup previsto: LCD/banner, UART init, CRC y copia de monitor. Propuesta RAMONLY: monitor 0000h–0FFFh, usuario 1000h–FFFFh. **No implementado/validado.** SRAM A15 gating, copy algorithm y ROM-disable trampoline requieren revisión de esquema/ASM.

### CRC ROM
CRC-16/CCITT-FALSE, init FFFFh, poly 1021h, MSB-first; bytes 0000h–7FFDh; CRC en 7FFEh–7FFFh. Imagen ROM 32768 bytes padded.

## Estado validado
Reset, ROM fetch, ejecución, HALT, ROM/RAM decode, LCD, UART, switches y LEDs. Diagnóstico: multímetro, continuidad, switches y LEDs; no hay osciloscopio/analizador lógico.

## Documentación
- [Contexto maestro](PROJECT_CONTEXT.md)
- [Mapa memoria](architecture/memory_map.md)
- [Decoder](architecture/memory_decoder.md)
- [Mapa I/O](architecture/io_map.md)
- [Boot](architecture/boot_sequence.md)
- [UART](architecture/uart.md)
- [LCD](architecture/lcd.md)
- [Hardware](hardware/hardware_notes.md)
- [Prompts](prompts/README.md)
- [Changelog](CHANGELOG.md)

CONFIRMADO = validado; PROPUESTO = no implementado; PENDIENTE = falta revisar/test. Evitar cambios innecesarios en PCB fabricada.
