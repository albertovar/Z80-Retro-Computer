# Component Datasheets and References

This page collects datasheets and technical references for the main components listed in the project hardware BOM (`hardware/schematic/CPU.csv`).

| Component | Datasheet / reference |
|---|---|
| Z80A CPU (Z8400) | [Zilog Z8400/Z84C00 Z80 CPU Product Specification (PDF)](https://www.zilog.com/docs/z80/z8400.pdf) |
| AT28C256 EEPROM | [Microchip AT28C256 datasheet (PDF)](http://ww1.microchip.com/downloads/en/DeviceDoc/doc0006.pdf) |
| W24512AK SRAM | [Winbond W24512A datasheet](https://www.alldatasheet.com/datasheet-pdf/pdf/47634/WINBOND/W24512A.html) |
| WD8250 UART | Datasheet link pending; the exact manufacturer/variant reference has not yet been recorded in the BOM. |
| 82C55A PPI | [82C55A datasheet (PDF)](http://jap.hu/electronic/8255.pdf) |
| 74HC14 | [TI SN74HC14 datasheet](https://www.ti.com/lit/gpn/sn74HC14) |
| 74HC138 | [TI SN74HC138 datasheet (PDF)](https://www.ti.com/lit/ds/symlink/sn74hc138.pdf) |
| 74HC273 | [Nexperia 74HC/HCT273 datasheet (PDF)](https://assets.nexperia.com/documents/data-sheet/74HC_HCT273.pdf) |
| 74HC04 | [Nexperia 74HC/HCT04 datasheet (PDF)](https://assets.nexperia.com/documents/data-sheet/74HC_HCT04.pdf) |
| 74HC08 | [TI SN74HC08 datasheet (PDF)](https://www.ti.com/lit/ds/symlink/sn74hc08.pdf) |
| 74HC32 | [TI SN74HC32 datasheet](https://www.ti.com/lit/gpn/sn74hc32) |
| 74HC02 | [TI SN74HC02 datasheet](https://www.ti.com/lit/gpn/sn74hc02) |
| 74HC244 | [Nexperia 74HC/HCT244 datasheet (PDF)](https://assets.nexperia.com/documents/data-sheet/74HC_HCT244.pdf) |
| L7805 voltage regulator | [ST L7805 datasheet (PDF)](https://www.st.com/resource/en/datasheet/l7805.pdf) |
| WC1602A LCD module | [Wincom WC1602A datasheet (PDF)](http://www.wincomlcd.com/pdf/WC1602A-SFYLYHTC06.pdf) |
| LED bar | [Broadcom LED bar datasheet (PDF)](https://docs.broadcom.com/docs/AV02-1798EN) |
| Reset pushbutton | [APEM/MEC Multimec switch series datasheet (PDF)](https://www.apem.com/medias/download/MEC_switches_serie_MULTIMEC5E.pdf) |

The BOM also includes passive components (resistors, capacitors and resistor networks), connectors, a DIP switch and 1.8432 MHz / 4 MHz crystals. Their exact manufacturer part numbers are not specified in the current BOM, so individual datasheet links are not listed.

## Z80 instruction set
- [Z80.info](https://www.z80.info/) — online Z80 instruction-set reference and opcode tables.
