.BANK 0
.ORG $8000

.include "src/header.asm"

MyProg:
    .include "src/init.asm"



	lda #%10000001 ;joypad autoread
    sta NMITIMEN

    rep #%00010000
    .index 16 ;xy 16 bit


    ;clear ram
	ldx #0
    @zero_ram:
	stz 0, x
    inx
	cpx #OBJECTS.w+$100
	bne @zero_ram

    ;set up screen
    ;bg1+2 graphics at $2000
    ;go until $3000
    ;2 * $1000
    .EQU BG1_GFX $2000
    .EQU BG2_GFX $2000
    lda #(2 << 4) | (2)
    sta BG12NBA
    .EQU BG3_GFX $0000
    .EQU BG4_GFX $0000
    ;bg3+4 graphics at $0000
    ;go until $800
    ;0 * $1000
    stz BG34NBA

    ;bg3 tilemap at $0800
    ;go until $1000
    ;2 * $400
    .EQU BG3_MAP $800
    lda #2 << 2
    sta BG3SC
    ;bg4 tilemap at $1000
    ;go until $1800
    ;4 * $400
    .EQU BG4_MAP $1000
    lda #4 << 2
    sta BG4SC
    ;bg1 tilemap at $1800
    ;go until $2000
    ;6 * $400
    .EQU BG1_MAP $1800
    lda #6 << 2
    sta BG1SC
    ;bg2 tilemap at $3000
    ;go until $3800
    ;12 * $400
    .EQU BG2_MAP $3000
    lda #12 << 2
    sta BG2SC

    stz W12SEL
    lda #%1010
    sta W34SEL

    lda #%10000000
    sta VMAIN

    lda #%00001001
    sta BGMODE

;clear vram
    stz VMADDL
    stz VMADDH
    ldx #$6000 ;size
    @ClearTilemap:
    stz VMDATAL
    stz VMDATAH
    dex
    bne @ClearTilemap

    DoLoadGfx1bpp BitmapFont@gfx, BG3_GFX, BitmapFont@gfx_END-BitmapFont@gfx
    DoLoadGfx BitmapFont2@gfx, BG3_GFX+$100, BitmapFont2@gfx_END-BitmapFont2@gfx

    DoLoadGfx BitmapFont3@gfx, BG1_GFX, BitmapFont3@gfx_END-BitmapFont3@gfx
    DoLoadPalette BitmapFont3@pal, 0, (BitmapFont3@pal_END-BitmapFont3@pal) / 2

    DoLoadGfx BGTiles@gfx, BG1_GFX+$1b0, BGTiles@gfx_END-BGTiles@gfx
    DoLoadPalette BGTiles@pal, $10, (BGTiles@pal_END-BGTiles@pal) / 2

    DoLoadGfx SPRITETiles@gfx, BG1_GFX+$200, SPRITETiles@gfx_END-SPRITETiles@gfx
    DoLoadPalette SPRITETiles@pal, $80, (SPRITETiles@pal_END-SPRITETiles@pal) / 2

;set scroll
    lda #-$10
    sta BG3HOFS
    stz BG3HOFS
    lda #-$40
    sta BG3VOFS
    stz BG3VOFS

    ;turn on layers
    lda #TM_ARGS(1, 1, 1, 1, 1)
    sta TM

	ldx #0
    @zero_oam:
	stz SHADOW_OAM.w, x
    inx
	lda #$ed
	sta SHADOW_OAM.w, x
    inx
	stz SHADOW_OAM.w, x
    inx
	stz SHADOW_OAM.w, x
    inx
	cpx #$200
	bne @zero_oam

	; Set sprite 0 to be large (16x16)
	;lda #%00000010
	;sta SHADOW_OAM2.w

    stz VMADDL
    lda #hibyte(BG1_MAP)
    sta VMADDH
	ldx #0
    stz func_ram
    @fill_bg1:
	lda #$1c
	sta VMDATAL

    ;every other row hflip
    txa
    and #%00100000
    lsr
    lsr
    lsr
    lsr
    lsr
    sta func_ram

    ;every other tile hflip
    txa
    and #1
    eor func_ram
    beq @no_1hflip
    ;do hflip
	lda #%01000100
	sta VMDATAH
    bra @finish_1hflip
    @no_1hflip:
	lda #%00000100
    sta VMDATAH
    @finish_1hflip:

    inx
	cpx #$400
	bne @fill_bg1

    stz VMADDL
    lda #hibyte(BG2_MAP)
    sta VMADDH
	ldx #0
    stz func_ram
    @fill_bg2:
	lda #$1d
	sta VMDATAL

    ;every other row hflip
    txa
    and #%00100000
    lsr
    lsr
    lsr
    lsr
    lsr
    sta func_ram

    ;every other tile hflip
    txa
    and #1
    eor func_ram
    beq @no_2hflip
    ;do hflip
	lda #%01000100
	sta VMDATAH
    bra @finish_2hflip
    @no_2hflip:
	lda #%00000100
    sta VMDATAH
    @finish_2hflip:

    inx
	cpx #$400
	bne @fill_bg2

    ;init text
    stz CursorX
    stz CursorY

    ldx #loword(txtHelloWorld)
    stx z_L
    lda #bankbyte(txtHelloWorld)
    sta z_L+2

    stz func_ram+1
    jsr PrintString

    lda #14
    sta CursorX
    lda #100
    sta CursorY
    ldx #loword(txtChrimmal)
    stx z_L
    lda #bankbyte(txtChrimmal)
    sta z_L+2
    jsr Menu_DrawWords

    ;do oam dma
    ;this doesnt really do much other than clearing the sprites
	jsr DoOAMDMA

    lda #1
    sta OBJSEL

    lda #%00001111 ;screen on
    sta INIDISP

    cli
main_loop:
    wai

	; Copy OAM data via DMA
	jsr DoOAMDMA

    lda object_count
    cmp #32
    bcs @no_snow_spawn
    jsr Rand
    cmp #$fb
    bcc @no_snow_spawn

    ;get last object index
    ;object_count *= 8

    lda object_count
    asl
    asl
    asl
    tax

    jsr CreateNewObject

    inc object_count
    @no_snow_spawn:


    ;bg1_scrx += 25
    clc
    lda bg1_scrx
    adc #25
    sta bg1_scrx
    lda bg1_scrx+1
    adc #0
    sta bg1_scrx+1

    ;bg1_scry += 25
    clc
    lda bg1_scry
    adc #25
    sta bg1_scry
    lda bg1_scry+1
    adc #0
    sta bg1_scry+1


    ;bg2_scrx -= 25
    sec
    lda bg2_scrx
    sbc #25
    sta bg2_scrx
    lda bg2_scrx+1
    sbc #0
    sta bg2_scrx+1

    ;bg2_scry += 25
    clc
    lda bg2_scry
    adc #25
    sta bg2_scry
    lda bg2_scry+1
    adc #0
    sta bg2_scry+1

    ;load into registers
    lda bg1_scrx+1
    sta BG1HOFS
    lda bg1_scrx
    sta BG1HOFS
    lda bg1_scry+1
    sta BG1VOFS
    lda bg1_scry
    sta BG1VOFS

    lda bg2_scrx+1
    sta BG2HOFS
    lda bg2_scrx
    sta BG2HOFS
    lda bg2_scry+1
    sta BG2VOFS
    lda bg2_scry
    sta BG2VOFS



    ldx #(64 *4)
	lda JOY1H
	bit #PAD_DOWN
	beq @down_not_pressed
        inc SHADOW_OAM.w + 1, x
	@down_not_pressed:
	bit #PAD_UP
    beq @up_not_pressed
        dec SHADOW_OAM.w + 1, x
    @up_not_pressed:
	bit #PAD_LEFT
	beq @right_not_pressed
        inc SHADOW_OAM.w, x
	@right_not_pressed:
	bit #PAD_RIGHT
    beq @left_not_pressed
        dec SHADOW_OAM.w, x
    @left_not_pressed:
	bit #PAD_START
    beq @start_not_pressed
        pha
        stz CursorX
        stz CursorY
        ldx #$2020
        stx func_ram+1
        jsr PrintString
        pla
    @start_not_pressed:
	bit #PAD_SELECT
    beq @select_not_pressed
        pha
        stz CursorX
        stz CursorY
        stz func_ram+1
        jsr PrintString
        pla
    @select_not_pressed:

    jsr DoObjectTick
	jmp main_loop

;x == offset
CreateNewObject:
    ;make x speed
    jsr Rand
    and #%00111111
    sec
    adc #0
    sta OBJECTS.w, x
    stz OBJECTS.w+1, x
    ;make x pos
    jsr Rand
    sta OBJECTS.w+2, x
    jsr Rand
    sta OBJECTS.w+3, x
    ;make y speed
    lda #30
    sta OBJECTS.w+4, x
    stz OBJECTS.w+5, x
    ;make y pos
    stz OBJECTS.w+6, x
    stz OBJECTS.w+7, x

    rts

DoObjectTick:
    ;iterate all objects
    ldx #0
    @loop:
    phx

    lda OBJECTS.w, x
    beq @end_early

    jsr Rand
    cmp #$fe
    bcc @no_flip
    lda OBJECTS.w, x
    eor #$ff
    sta OBJECTS.w, x
    lda OBJECTS.w+1, x
    eor #$ff
    sta OBJECTS.w+1, x
    @no_flip:

    ;add x spd to x pos
    clc
    lda OBJECTS.w+2, x
    adc OBJECTS.w, x
    sta OBJECTS.w+2, x

    lda OBJECTS.w+3, x
    adc OBJECTS.w+1, x
    sta OBJECTS.w+3, x
    pha

    ;add y spd to y pos
    clc
    lda OBJECTS.w+6, x
    adc OBJECTS.w+4, x
    sta OBJECTS.w+6, x

    lda OBJECTS.w+7, x
    adc OBJECTS.w+5, x
    sta OBJECTS.w+7, x
    pha

    clc
    cmp #$e8
    bcc @no_make
    pla
    pla
    ;make a new object if object is out of screen
    jsr CreateNewObject
    bra @end_early
    @no_make:


    ;x = (x / 2) + $100 for oam
    ;make accumulator 16
    rep #FLAG_ACCUM16
    txa
    lsr
    adc #$100
    tax
    lda #0
    ;make accumulator 8
    sep #FLAG_ACCUM16

    ;get y
    pla
    sta SHADOW_OAM.w+1, x
    ;get x
    pla
    sta SHADOW_OAM.w, x
    ;get tile
    lda #$21
    sta SHADOW_OAM.w+2, x
    ;get priority
    lda #%00110000
    sta SHADOW_OAM.w+3, x


    @end_early:
    plx
    inx
    inx
    inx
    inx
    inx
    inx
    inx
    inx
    cpx #$100
    bne @loop

    rts

DoOAMDMA:
    @WaitVblank:
        lda HVBJOY
        and #%10000000
        beq @WaitVblank

	; Copy OAM data via DMA
	stz OAMADDL
	lda #%00000000
	sta DMAP1
	lda #lobyte(OAMDATA)
	sta BBAD1
	ldx #loword(SHADOW_OAM)
	stx A1T1L
	lda #bankbyte(SHADOW_OAM)
	sta A1B1
	ldx #$220
	stx DAS1L
	lda #%00000010
	sta MDMAEN

    rts


Menu_DrawWords:

    ;store starting x
    lda CursorX
    sta func_ram

    ldy #0 ;offset
    @again:
    lda [z_L],y
    beq @done
    cmp #1
    beq @newline
    jsr Menu_PrintChar
    iny
    jmp @again
    @done:
    rts

    @newline:
    inc CursorY
    lda func_ram
    sta CursorX
    iny
    jmp @again



.EQU sprite_xpos func_ram+1
.EQU sprite_index func_ram+2
Menu_PrintChar:
    and #%11011111
    beq @imm_end
    ;adjust to font
    sec
    sbc #$41
    pha
    and #%00010000
    beq @no_adjust
    pla
    clc
    adc #$10
    pha
    @no_adjust:
    pla
    clc
    adc #$30

    ;store char
    pha

    ;make xpos
    ;a = (y + CursorX) << 3
    clc
    tya
    adc CursorX
    asl
    asl
    sta sprite_xpos

    ;sprite index << 2
    lda sprite_index
    asl
    asl
    tax

    ;write top of letter
    lda sprite_xpos
    sta SHADOW_OAM.w, x
    lda CursorY
    sta SHADOW_OAM.w+1, x
    pla
    sta SHADOW_OAM.w+2, x
    pha
    ;set priority
    lda #%00100000
    sta SHADOW_OAM.w+3, x

    inc sprite_index
    ;sprite index << 2
    lda sprite_index
    asl
    asl
    tax

    ;write bottom of letter
    lda sprite_xpos
    sta SHADOW_OAM.w, x
    lda CursorY
    clc
    adc #8
    sta SHADOW_OAM.w+1, x
    pla
    clc
    adc #$10
    sta SHADOW_OAM.w+2, x
    ;set priority
    lda #%00100000
    sta SHADOW_OAM.w+3, x

    inc sprite_index

    @imm_end:
    inc CursorX
    rts

PrintString:
    rts
    ;store starting x
    lda CursorX
    sta func_ram

    ldy #0 ;offset
    @again:
    lda [z_L],y
    beq @done
    cmp #1
    beq @newline
    jsr PrintChar
    iny
    jmp @again
    @done:
    rts

    @newline:
    inc CursorY
    lda func_ram
    sta CursorX
    iny
    jmp @again


PrintChar:
    and #%11011111
    beq @space
    ;adjust to font
    sec
    sbc #64
    clc
    adc func_ram+1
    @space:
    pha
    ldx z_L
    phx
    lda CursorY
    sta z_L+1

    lda #0
    clc
    ror z_L+1
    ror
    ror z_L+1
    ror
    ror z_L+1
    ror
    adc CursorX
    sta z_L
    WaitVblank:
        lda HVBJOY
        and #%10000000
        beq WaitVblank

    ;set vmaddr
    ldx z_L
    stx VMADDL
    lda #hibyte(BG3_MAP)
    sta VMADDH

    plx
    stx z_L
    pla
    sta VMDATAL
    lda #%00100000
    sta VMDATAH
    inc CursorX
    rts

;z_L == addr
;x == cg at
;y == rom at
;func_ram == size
LoadPalette:
    ;clear a
    and #0
    tay

@loop:
    phy

    ;CGADD = x (8 bit)
    txa
    sta CGADD

    tya
    asl
    tay

    ;get palette 16 bit
    lda [z_L],y
    sta CGDATA
    iny
    lda [z_L],y
    sta CGDATA

    ply

    iny
    inx
    dec func_ram
    bne @loop

    rts

;z_L == addr
;y == at
;func_ram == size
LoadGfx_1bpp:
    ;write vmaddl + vmaddh (16 bit)
    sty VMADDL

    ldy #0
    @loop:
    lda [z_L], y ;whole word
    sta VMDATAL
    sta VMDATAH
    iny

    cpy func_ram
    bne @loop

    rts


;z_L == addr
;y == at
;func_ram == size
LoadGfx:
    ;make accumulator 16
    rep #FLAG_ACCUM16
    ;write vmaddl + vmaddh (16 bit)
    sty VMADDL

    ldy #0
    @loop:
    lda [z_L], y ;whole word
    sta VMDATAL
    iny
    iny

    cpy func_ram
    bne @loop

    ;make accumulator 8
    sep #FLAG_ACCUM16
    rts

nmi:
	bit RDNMI
	inc nmi_count.w
_rti:
	rti

Rand:
    clc
    lda random_num
    adc random_num+1
    sta random_num+1
    clc
    lda random_num
    adc #$75
    sta random_num
    lda random_num+1
    adc #$63
    sta random_num+1

    rts

BitmapFont:
BBP_INCBIN "gfx/font.1bpp", "gfx/font.pal"

BitmapFont2:
BBP_INCBIN "gfx/font.2bpp", "gfx/font.pal"

BitmapFont3:
BBP_INCBIN "gfx/font.4bpp", "gfx/font2.pal"

BGTiles:
BBP_INCBIN "gfx/tiles.4bpp", "gfx/tiles.pal"

SPRITETiles:
BBP_INCBIN "gfx/sprites.4bpp", "gfx/sprites.pal"

txtHelloWorld:
    .db "HEY SO  NOT TO ALARM",1
    .db "ANYONE BUT WHOEVER OWNS THE",1
    .db "GREY CHEVY SILVERADO",1
    .db "OUTSIDE REAAAAALLY NEEDS TO",1
    .db "CHECK THEIR TIRE PRESSURE",1
    .db "DONT ASK ME WHY",1
    .db "I JUST HAVE",1
    .db "AN INTUITION",0

txtChrimmal:
    .db "MERRY  CHRISTMAS",0