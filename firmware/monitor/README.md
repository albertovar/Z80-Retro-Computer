# Monitor Firmware

Add authoritative ASM source here. Prior conversation referenced `Z80_monitor_loadbin.asm`, but it has not been imported here; do not assume this is the latest firmware.

## Build and ROM programming workflow

The following commands are taken from the user's shell history and represent the **known working workflow**. They have not been independently tested in this repository.

### Assemble the monitor

From the directory containing the ASM source:

```sh
z80asm -o monitor.bin monitor.asm
```

A historical build also used listing output:

```sh
z80asm -l -o Z80_monitor.bin Z80_monitor.asm
```

- Tool: `z80asm`
- Input: monitor ASM source
- Output: raw binary (`.bin`)
- The listing option `-l` was used in an earlier command.

### Add ROM padding and CRC

```sh
python3 make_rom.py monitor.bin monitor_CRC.bin
```

This is the recorded invocation of the project utility `make_rom.py`. The resulting `monitor_CRC.bin` is the ROM image intended for programming.

The documented ROM format is 32 KiB, CRC-16/CCITT-FALSE (initial value `FFFFh`, polynomial `1021h`, MSB-first), covering `0000h–7FFDh`, with CRC stored at `7FFEh–7FFFh` (MSB first).

**Pending:** The `make_rom.py` source itself is not currently documented or included here. Its exact padding/fill behavior and error handling should be verified from the actual script before relying on those details.

### Program the AT28C256 using Minipro/T48

```sh
minipro -p AT28C256 -w monitor_CRC.bin -s
```

This is the command recorded in shell history. The `-s` option is used in the recorded workflow to accept the ROM image size.

### Load a binary into RAM over the serial port

```sh
python3 sendbin.py /dev/ttyUSB0 8000 SWITCHES_monitor.bin
```

Recorded parameters:
- Serial device: `/dev/ttyUSB0`
- Load address argument: `8000` (as passed to the script)
- Input binary: `SWITCHES_monitor.bin`

**Pending:** The `sendbin.py` source is not currently documented or included here. Confirm baud rate, address parsing (hexadecimal vs decimal), transfer protocol, acknowledgements and error handling from the script itself. Do not assume the script's implementation from the command line alone.

## Tools used in the workflow

- `z80asm` — Z80 assembler
- `python3` — runs `make_rom.py` and `sendbin.py`
- `minipro` — programs the AT28C256 through the T48
- Serial device such as `/dev/ttyUSB0` — target UART connection

For terminal access to the board, the project context records:

```sh
screen /dev/ttyUSB0 115200
```

Exit `screen` with Ctrl+A, then K, then Y.

## Complete command sequence from shell history

ROM build/program:

```sh
z80asm -o monitor.bin monitor.asm
python3 make_rom.py monitor.bin monitor_CRC.bin
minipro -p AT28C256 -w monitor_CRC.bin -s
```

RAM binary load:

```sh
z80asm -o SWITCHES_monitor.bin SWITCHES_monitor.asm
python3 sendbin.py /dev/ttyUSB0 8000 SWITCHES_monitor.bin
```

## Documentation gaps / pending verification

- Add the actual `make_rom.py` and `sendbin.py` source files or document their exact behavior.
- Record how to install `z80asm`, Python 3 and Minipro on the target Linux distribution.
- Confirm the exact assembler package/version and options.
- Confirm serial baud rate and protocol used by `sendbin.py`.
- Document whether `8000` is parsed as hexadecimal by `sendbin.py`.
- Firmware ASM source has not yet been imported into this repository; preserve the distinction between historical commands and the current authoritative source.
