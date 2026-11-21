
binary = open("sblast.gg", "rb").read()[0x64fa1:0x6520c]

i = 0
masking = True
mask = -1
lines = []
while i < len(binary):
    if masking:
        mask = int.from_bytes(binary[i:i+4], "little")
        i += 4
        binner = bin(mask).replace("0b","")
        while len(binner) < 32:
            binner = "0"+binner
        bin1 = binner[:8]
        bin2 = binner[8:16]
        bin3 = binner[16:24]
        bin4 = binner[24:]
        lines.append(f".db %{bin1},%{bin2}\n.db %{bin3},%{bin4}")
        masking = False
    else:
        tile = []
        for bit in range(32):
            bit = 1 << abs(bit-31)
            if mask & bit:
                tile.append(hex(binary[i]).replace("0x","$"))
                i += 1
            else:
                tile.append("    ")
            if len(tile) == 4:
                for x in range(len(tile)):
                    if tile[x] != "    ":
                        tile[x] += ","
                entry = False
                for x in range(len(tile)):
                    x += 1
                    if tile[-x].find(",") != -1:
                        tile[-x] = tile[-x].replace(",","")
                        entry = True
                        break
                if entry:
                    lines.append(".db "+"".join(tile)+"")
                else:
                    lines.append(" ")
                tile = []
        masking = True
        lines.append(" ")
for line in lines:
    print(line)