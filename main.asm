INCLUDE "hardware.inc"

MAP_WIDTH   EQU 32
GFX_WIDTH   EQU 10
GFX_HEIGHT  EQU 12
GFX_OFFSET  EQU 5 + (3 * MAP_WIDTH)

SECTION "VBlankVector", ROM0[$40]
    jp VBlankHandler

SECTION "StatVector", ROM0[$48]
    jp HBlankHandler

SECTION "Header", ROM0[$100]
    jp Start

SECTION "Code", ROM0[$150]
Start:
    di                          ; Disable interrupts

    call WaitVBlank             ; Turn off LCD
    ld hl, rLCDC
    res 7, [hl]

    ld a, IEF_VBLANK | IEF_LCDC ; Enable v-blank and status interrupts
    ld [rIE], a
    ld a, STATF_MODE00          ; Set h-blank to cause a status interrupt
    ld [rSTAT], a

    ld hl, Tiles                ; Copy tiles to VRAM
    ld bc, _VRAM
    ld a, GFX_WIDTH * GFX_HEIGHT
    call DMACopy

    call SetupTileMap           ; Set up the image centered

    ld a, $0                    ; Reset offset counters
    ld [VBlankOffset], a
    ld [HBlankOffset], a

    ld hl, rLCDC                ; Turn on LCD
    set 7, [hl]

    ei                          ; Enable interrupts

Loop:
    jr Loop

HBlankHandler:
    ld a, BCPSF_AUTOINC         ; Set first palette index with auto increment
    ld [rBCPS], a

    ld hl, Gradient             ; Calculate address to gradient color
    ld a, [HBlankOffset]
    ld b, $0
    ld c, a
    add hl, bc

    ld a, [hl+]                 ; Update first two-byte palette color
    ld [rBCPD], a
    ld a, [hl]
    ld [rBCPD], a

    ld a, [HBlankOffset]        ; Increment offset to next two-byte color
    add a, $2
    and a, $7F
    ld [HBlankOffset], a

    reti

VBlankHandler:
    ld a, [VBlankOffset]        ; Increment v-blank offset
    add a, $2
    and a, $7F
    ld [VBlankOffset], a
    ld [HBlankOffset], a        ; Start next h-blank offset from v-blank offset
    reti

SetupTileMap:
    ld a, $0                    ; a = tile index
    ld b, GFX_HEIGHT            ; b = row
    ld hl, _SCRN0 + GFX_OFFSET
.row:
    ld c, GFX_WIDTH             ; c = column
.col:
    ld [hl+], a
    inc a
    dec c
    jp nz, .col

    ld de, MAP_WIDTH - GFX_WIDTH
    add hl, de
    dec b
    jp nz, .row

    ret

WaitVBlank:
    ld a, [rLY]
    cp a, $90
    jp c, WaitVBlank
    ret

; hl = Source address
; bc = Target address
; a = Number of 16 byte blocks to copy
DMACopy:
    ld d, a         ; Save a

    ld a, h         ; Set source
    ld [rHDMA1], a
    ld a, l
    ld [rHDMA2], a

    ld a, b         ; Set target
    ld [rHDMA3], a
    ld a, c
    ld [rHDMA4], a

    ld a, d         ; Start general purpose DMA transfer
    ld [rHDMA5], a
    ret

Gradient:
COL SET 0
    REPT 31
    DW (COL << 10) | (COL << 5) | COL
COL SET COL + 1
    ENDR
    REPT 32
    DW (COL << 10) | (COL << 5) | COL
COL SET COL - 1
    ENDR
    DW $0

SECTION "Tiles", ROM0, ALIGN[4]
Tiles:
    INCBIN "r.2bpp"

SECTION "Variables", WRAM0[$C000]
HBlankOffset:   DS 1
VBlankOffset:   DS 1
