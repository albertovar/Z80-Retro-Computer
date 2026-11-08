#!/usr/bin/env python3

import sys
import time
from pathlib import Path

import serial


def main():
    if len(sys.argv) != 4:
        print(f"Uso: {sys.argv[0]} PUERTO DIRECCION fichero.bin")
        print(f"Ejemplo: {sys.argv[0]} /dev/ttyUSB0 8000 programa.bin")
        sys.exit(1)

    port = sys.argv[1]
    address = int(sys.argv[2], 16)
    data = Path(sys.argv[3]).read_bytes()

    if not data:
        sys.exit("Error: el fichero está vacío.")

    if not 0x8000 <= address < 0xF000:
        sys.exit("Error: la dirección debe estar entre 8000 y EFFF.")

    if address + len(data) > 0xF000:
        sys.exit("Error: el fichero sobrepasa el límite EFFF.")

    if len(data) > 0xFFFF:
        sys.exit("Error: fichero demasiado grande.")

    print(f"Puerto:     {port}")
    print(f"Dirección:  {address:04X}")
    print(f"Tamaño:     {len(data)} bytes (0x{len(data):04X})")

    with serial.Serial(port, 115200, timeout=1,
                       write_timeout=10) as ser:

        # Dar tiempo a estabilizar el puerto.
        time.sleep(0.2)
        ser.reset_input_buffer()

        # Solicitar la carga.
        command = f"loadbin {address:04X} {len(data):04X}\r"
        ser.write(command.encode("ascii"))
        ser.flush()

        # Esperar READY antes de transmitir el binario.
        deadline = time.monotonic() + 10
        received = bytearray()

        while time.monotonic() < deadline:
            chunk = ser.read(ser.in_waiting or 1)
            if chunk:
                received.extend(chunk)
                print(chunk.decode("ascii", errors="replace"),
                      end="", flush=True)

                if b"READY\r\n" in received or b"READY\n" in received:
                    break
        else:
            sys.exit("\nError: el monitor no ha enviado READY.")

        # Transmitir exactamente el contenido del fichero.
        ser.write(data)
        ser.flush()

        # Esperar la confirmación final.
        deadline = time.monotonic() + 30
        received.clear()

        while time.monotonic() < deadline:
            chunk = ser.read(ser.in_waiting or 1)
            if chunk:
                received.extend(chunk)
                print(chunk.decode("ascii", errors="replace"),
                      end="", flush=True)

                if b"loadbin complete" in received:
                    print("\nTransferencia terminada.")
                    return

        sys.exit("\nError: no se ha recibido la confirmación final.")


if __name__ == "__main__":
    main()