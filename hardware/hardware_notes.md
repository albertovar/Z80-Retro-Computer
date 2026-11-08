# Hardware Notes

## PCB
KiCad 10.0.4 macOS. PCB fabricated. Freerouting 2.2.4 fixed SES parse issue in 2.2.3. GND zone: select copper layer/net GND and refill B. F.Mask/B.Mask are solder-mask opening layers, not copper; include in Gerbers. Check layer, clearance, thermal, net/refill if GND appears unconnected.

## Reset
RC/button/two 74HC14: RESET LOW normal/HIGH while pressed; RESET_INV HIGH normal/LOW during reset.
- Z80 RESET pin26 active-low ← RESET_INV
- 74HC273 MR active-low ← RESET_INV
- WD8250 MR pin35 active-high ← RESET
- 82C55 active-high reset ← RESET
Reset spans at least three full clock cycles.

## Bring-up
Reset→ROM fetch→execution→HALT validated. ROM/RAM selection, LCD, UART, switches, LED path tested.

## Practical troubleshooting
Use multimeter, continuity, LEDs, switches, manual reset/clock. State exact node, condition and expected voltage/polarity. No scope/logic analyzer available.

## EEPROM history
T48/Minipro successfully wrote/read/verified 28C256. Old manual experiment used 4.7k data pulldowns, switches to VCC and manual /WE pulse; symptom 1→FF is historical. If recurring, inspect CE/OE/WE, stable address/data, levels, polarity, pulldowns; don't assume delay alone.
