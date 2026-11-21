def hexToint(inStr:str):
    return int(inStr, 16)

def intToBin(inInt:int):
    val = bin(inInt).replace("0b","")
    while len(val) < 8:
        val = "0"+val
    return val

def do(string:str):
    string = string.replace(" ", "")

    lines = []
    i = 0
    while i < len(string):
        byte1 = hexToint(string[i:i+2])
        byte2 = (byte1 & 0b11110000) >> 4
        byte1 = byte1 & 0b00001111
        byte3 = hexToint(string[i+2:i+4]) & 0b00001111

        newline = f"gg_color {byte1}, {byte2}, {byte3}"
        lines.append(newline)
        i += 4
    for line in lines:
        print(line)


do("EE 0E EE 0E EE 0E EE 0E EE 0E EE 0E EE 0E EE 0E EE 0E EE 0E EE 0E EE 0E A8 0E EE 0E 00 0E 64 0A")