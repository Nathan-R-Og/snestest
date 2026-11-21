.MACRO incbinRange args arg_file, start, end
    .incbin arg_file SKIP start READ end - start
.ENDM

.MACRO BBP_INCBIN args arg_file_gfx, arg_file_pal
    @gfx:
    .incbin arg_file_gfx
    @gfx_END:
    @pal:
    .incbin arg_file_pal
    @pal_END:
.ENDM

.MACRO DoLoadPalette args label, at, size
    ldx #loword(label)
    stx z_L
    ldx #hiword(label)
    stx z_L+2
    ldx #size
    stx func_ram
    ldx #at
    jsr LoadPalette
.ENDM

.MACRO DoLoadGfx1bpp args label, at, size
    ldx #loword(label)
    stx z_L
    ldx #hiword(label)
    stx z_L+2
    ldy #size
    sty func_ram
    ldy #at
    jsr LoadGfx_1bpp
.ENDM

.MACRO DoLoadGfx args label, at, size
    ldx #loword(label)
    stx z_L
    ldx #hiword(label)
    stx z_L+2
    ldy #size
    sty func_ram
    ldy #at
    jsr LoadGfx
.ENDM