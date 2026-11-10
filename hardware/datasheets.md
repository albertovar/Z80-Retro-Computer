# Component Datasheets and References

This page collects datasheets and technical references for the main components listed in the project hardware BOM (`hardware/schematic/CPU.csv`).

| Component | Datasheet / reference |
|---|---|
| Z80A CPU (Z8400) | [SGS-Thomson Z8400 Z80 CPU datasheet (PDF, November 1988)](https://www.bitsavers.org/components/sgs/_dataBooks/1990_SGS_Z80_Microprocessor_Family_Handbook.pdf) — includes the Z8400 CPU specifications and Z80A characteristics. |
| AT28C256 EEPROM | [Microchip AT28C256 datasheet (PDF)](http://ww1.microchip.com/downloads/en/DeviceDoc/doc0006.pdf) |
| W24512AK SRAM | [Winbond W24512A datasheet](https://www.alldatasheet.com/datasheet-pdf/pdf/47634/WINBOND/W24512A.html) |
| WD8250 UART | Datasheet link pending; the exact manufacturer/variant reference has not yet been recorded in the BOM. |
| 82C55A PPI | [82C55A datasheet (PDF)](http://jap.hu/electronic/8255.pdf) |
| 74HC14 | [TI SN74HC14 datasheet](https://www.ti.com/lit/gpn/sn74HC14) |
| 74HC138 | [TI SN74HC138 datasheet (PDF)](https://www.ti.com/lit/ds/symlink/sn74hc138.pdf) |
| 74HC273 | [Nexperia 74HC/HCT273 datasheet (PDF)](https://assets.nexperia.com/documents/data-sheet/74HC_HCT273.pdf) |
| 74HC04 | [Nexperia 74HC/HCT04 datasheet (PDF)](https://assets.nexperia.com/documents/data-sheet/74HC_HCT04.pdf) |
| 74HC08 | [TI SN74HC08 datasheet (PDF)](https://www.ti.com/lit/ds/symlink/sn74hc08.pdf) |
| 74HC32 | [TI SN74HC32 datasheet](https://www.ti.com/lit/gpn/sn74HC32) |
| 74HC02 | [TI SN74HC02 datasheet](https://www.ti.com/lit/gpn/sn74HC02) |
| 74HC244 | [Nexperia 74HC/HCT244 datasheet (PDF)](https://assets.nexperia.com/documents/data-sheet/74HC_HCT244.pdf) |
| WC1602A LCD module | [Wincom WC1602A datasheet (PDF)](http://www.wincomlcd.com/pdf/WC1602A-SFYLYHTC06.pdf) |

The BOM also includes passive components (resistors, capacitors and resistor networks), connectors, a DIP switch and 1.8432 MHz / 4 MHz crystals. Their exact manufacturer part numbers are not specified in the current BOM, so individual datasheet links are not listed.

## Z80 instruction set

- [Z80 instructions set](https://k1.spdns.de/Develop/Hardware/Infomix/ICs%20computer/Microprocessor/Z80/Z80%20Software%20%2B%20Info/Z80.Instruction%20set.pdf) — instruction reference and opcode information.
- [Z80.info](https://www.z80.info/) — online Z80 instruction-set reference and opcode tables.
