# Monitor Firmware

Add authoritative ASM source here. Prior conversation referenced `Z80_monitor_loadbin.asm`, but it has not been imported here; do not assume this is the latest firmware.

## Memory map

The computer supports two memory configurations. The selected configuration changes how the Z80's 64 KiB address space is mapped.

### Standard mode (ROM enabled)

| Z80 address range | Size | Device | Description |
|---|---:|---|---|
| `0000h–7FFFh` | 32 KiB | AT28C256 EEPROM | ROM is mapped at the bottom of the address space. Reset execution starts here. |
| `8000h–FFFFh` | 32 KiB | SRAM | RAM occupies the upper half of the address space. The first available RAM address is `8000h`. |

**Important:** `7FFFh` is still ROM in standard mode. The stack and writable data must be placed in RAM before using operations such as `CALL`, `PUSH`, or `RET`.

The monitor currently reserves `F000h–FFFFh` for its buffer, variables, and stack (a firmware convention). Consequently, the `sendbin.py` utility limits user binary transfers to `8000h–EFFFh`.

### RAM-only mode (ROM disabled)

| Z80 address range | Size | Device | Description |
|---|---:|---|---|
| `0000h–FFFFh` | 64 KiB | SRAM | SRAM is mapped across the entire Z80 address space; ROM is not visible. |

In RAM-only mode, the full 64 KiB address space is RAM. A proposed monitor layout is `0000h–0FFFh` for the monitor and `1000h–FFFFh` for user RAM, but **this layout is only a proposal and has not been implemented or validated**.

### Memory-map comparison

| Feature | Standard mode | RAM-only mode |
|---|---|---|
| `0000h–7FFFh` | ROM | SRAM |
| `8000h–FFFFh` | SRAM | SRAM |
| Reset vector at `0000h` | ROM | SRAM (must contain valid startup code) |
| Total addressable RAM | 32 KiB | 64 KiB |
| `sendbin.py` supported load range | `8000h–EFFFh` | Not currently supported by the utility |

**Note:** `sendbin.py` currently assumes standard mode and validates load addresses in `8000h–EFFFh`. It must be adapted before using it to load binaries in RAM-only mode.

## Build and ROM programming workflow

The following commands are taken from the user's shell history and represent the **known working workflow**.

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

The utility is in [`firmware/utils/make_rom.py`](../utils/make_rom.py).

```sh
python3 firmware/utils/make_rom.py monitor.bin monitor_CRC.bin
```

Run from the repository root (or adjust the script path if working from another directory). The utility takes the assembled program binary as input and creates the final ROM image as output. The input file (for example, `monitor.bin`) is **not** the file to program directly into the ROM; program the generated `monitor_CRC.bin` instead. The monitor firmware uses the stored CRC to check ROM integrity.

Example invocation:

```sh
python3 make_rom.py monitor.bin monitor_CRC.bin
```

The utility:
- Rejects input larger than 32766 bytes (7FFEh).
- Pads the program with `00h` bytes through address 7FFDh.
- Calculates CRC-16/CCITT-FALSE (initial value `FFFFh`, polynomial `1021h`, MSB-first) over `0000h–7FFDh`.
- Stores the CRC at `7FFEh–7FFFh`, MSB first.
- Produces a 32 KiB (`8000h`) ROM image.

### Program the AT28C256 using Minipro/T48

```sh
minipro -p AT28C256 -w monitor_CRC.bin -s
```

This is the command recorded in shell history. The `-s` option is used in the recorded workflow to accept the ROM image size.

## Load a binary into RAM over the serial port

The utility is [`firmware/utils/sendbin.py`](../utils/sendbin.py). It sends a binary file to the monitor over the UART and asks the monitor to store it in RAM.

**Standard memory mode:** ROM occupies `0000h–7FFFh`; SRAM is mapped at `8000h–FFFFh`. Therefore, the first address of RAM in standard mode is **`8000h`**.

Example (from the repository root):

```sh
python3 firmware/utils/sendbin.py /dev/ttyUSB0 8000 SWITCHES_monitor.bin
```

Arguments:
- `/dev/ttyUSB0`: serial port
- `8000`: load address, interpreted by the script as **hexadecimal** (`8000h`)
- `SWITCHES_monitor.bin`: binary file to transfer

Implementation details confirmed from `sendbin.py`:
- UART settings: 115200 baud, timeout 1 s, write timeout 10 s.
- Sends the monitor command `loadbin <address> <length>\r`, with address and byte count in four-digit hexadecimal.
- Waits up to 10 s for `READY` before sending the raw file bytes.
- Waits up to 30 s for the monitor's `loadbin complete` confirmation.
- Validates the load address is in `8000h–EFFFh` and that the transfer does not extend beyond `EFFFh` (the upper boundary is exclusive at `F000h`).
- Requires Python's `pyserial` module.

The current utility restricts transfers to `8000h–EFFFh`, consistent with the monitor's reserved upper RAM area at `F000h–FFFFh`.

## Tools used in the workflow

- `z80asm` — Z80 assembler
- Python 3 — runs `make_rom.py` and `sendbin.py`
- `pyserial` — serial port support for `sendbin.py`
- `minipro` — programs the AT28C256 through the T48
- Serial device such as `/dev/ttyUSB0` — target UART connection

For terminal access to the board:

```sh
screen /dev/ttyUSB0 115200
```

Exit `screen` with Ctrl+A, then K, then Y.

## Complete command sequence from shell history

ROM build/program:

```sh
z80asm -o monitor.bin monitor.asm
python3 firmware/utils/make_rom.py monitor.bin monitor_CRC.bin
minipro -p AT28C256 -w monitor_CRC.bin -s
```

RAM binary load:

```sh
z80asm -o SWITCHES_monitor.bin SWITCHES_monitor.asm
python3 firmware/utils/sendbin.py /dev/ttyUSB0 8000 SWITCHES_monitor.bin
```

## Documentation gaps / pending verification

- Record how to install `z80asm`, Python 3, `pyserial` and Minipro on the target Linux distribution.
- Confirm the exact assembler package/version and options.
- Firmware ASM source has not yet been imported into this repository; preserve the distinction between historical commands and the current authoritative source.
