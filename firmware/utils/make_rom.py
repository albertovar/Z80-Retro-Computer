#!/usr/bin/env python3

import sys

ROM_SIZE = 0x8000          # 32 KiB
CRC_START = 0x0000
CRC_END = 0x7FFE           # 7FFEh excluido
CRC_ADDR = 0x7FFE          # donde se almacena el CRC


def crc16_ccitt(data):
    """
    CRC-16/CCITT-FALSE
    Polynomial: 0x1021
    Initial value: 0xFFFF
    """
    crc = 0xFFFF

    for byte in data:
        crc ^= byte << 8

        for _ in range(8):
            if crc & 0x8000:
                crc = ((crc << 1) ^ 0x1021) & 0xFFFF
            else:
                crc = (crc << 1) & 0xFFFF

    return crc


def main():

    if len(sys.argv) != 3:
        print(f"Uso: {sys.argv[0]} entrada.bin salida.bin")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    # Leer binario generado por z80asm
    with open(input_file, "rb") as f:
        data = bytearray(f.read())

    print(f"Archivo de entrada : {input_file}")
    print(f"Tamaño             : {len(data)} bytes")

    # El programa debe caber antes de 7FFEh
    if len(data) > CRC_ADDR:
        print("ERROR: el programa ocupa más de 32766 bytes.")
        sys.exit(1)

    # Completar hasta 7FFEh
    data.extend([0x00] * (CRC_ADDR - len(data)))

    # Calcular CRC de 0000h–7FFDh
    crc = crc16_ccitt(data[CRC_START:CRC_END])

    print(f"CRC-16 calculado   : {crc:04X}h")

    # Guardar CRC en 7FFEh–7FFFh
    #
    # MSB primero:
    # 7FFEh = byte alto
    # 7FFFh = byte bajo

    data.append((crc >> 8) & 0xFF)
    data.append(crc & 0xFF)

    # Comprobar tamaño final
    if len(data) != ROM_SIZE:
        print(f"ERROR: tamaño final incorrecto: {len(data)} bytes")
        sys.exit(1)

    # Escribir ROM definitiva
    with open(output_file, "wb") as f:
        f.write(data)

    print(f"ROM generada       : {output_file}")
    print(f"Tamaño final       : {len(data)} bytes")
    print(f"CRC almacenado     : {data[0x7FFE]:02X}{data[0x7FFF]:02X}h")
    print("OK")


if __name__ == "__main__":
    main()
