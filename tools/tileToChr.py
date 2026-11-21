
binary = open("sblast.gg", "rb").read()[0x64fa1:0x6520c]

i = 0
masking = True
mask = -1
newBytes = bytearray()
def turnbits(byte):
    fuck = bin(byte).replace("0b","")
    while len(fuck) < 8:
        fuck = "0"+fuck
    fuck = fuck[::-1]
    return int(fuck,2)

while i < len(binary):
    if len(newBytes) == 0x180:
        print("s")
    if masking:
        byte1 = turnbits(binary[i]) << 24
        byte2 = turnbits(binary[i+1]) << 16
        byte3 = turnbits(binary[i+2]) << 8
        byte4 = turnbits(binary[i+3])
        mask = byte1 | byte2 | byte3 | byte4
        print(binary[i:i+4].hex(), )
        i += 4
        masking = False
    else:
        for bit in range(32):
            bit = 1 << abs(bit-31)
            if mask & bit:
                newBytes.append(binary[i])
                i += 1
            else:
                newBytes.append(0)
        masking = True

open("tools/outputs/chr.bin", "wb").write(newBytes)