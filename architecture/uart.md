# WD8250 UART

- I/O 00h–07h / Y0.
- Clock 1.8432MHz; 115200 8N1; divisor=1.
- LSR offset5; DR bit0; THRE bit5.
- RX/TX validated. BAUDOUT pin15→RCLK pin9. MR pin35 active-high receives RESET.
- Data D0–D7 to Z80 data bus; A0–A2 to Z80 A0–A2.
- /DISTR pin21 associated with /RD; /DOSTR pin18 associated with /WR; verify exact strobe wiring before change.
- ADS pin25 held appropriate/stable.

Pin list: D0–D7 1–8; RCLK9; SIN10; SOUT11; CS0/1/2 12/13/14; BAUDOUT15; XTAL1/2 16/17; /DOSTR18; DOSTR19; GND20; /DISTR21; DISTR22; DDIS23; CSOUT24; /ADS25; A2/A1/A0 26/27/28; INTRPT30; OUT2/RTS/DTR/OUT1 31/32/33/34; MR35; CTS/DSR/DCD/RI 36–39; VCC40.

Resident monitor proposal: ROM initializes UART; RAM monitor uses existing configuration and does not reinitialize.
Terminal: `screen /dev/ttyUSB0 115200`, no flow control; exit Ctrl+A K Y.
