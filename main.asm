INCLUDE "hardware.inc"

LCDCF_ON_BIT    EQU 7
LOGO_WIDTH      EQU 10
LOGO_HEIGHT     EQU 12
LOGO_OFFSET_X   EQU 5
LOGO_OFFSET_Y   EQU 3
GRADIENT_STEPS  EQU 64

SECTION "VBlankVector", ROM0[$40]
    jp VBlankHandler

SECTION "StatVector", ROM0[$48]
    jp HBlankHandler

SECTION "Header", ROM0[$100]
    jp Start

SECTION "Code", ROM0[$150]
Start:
    di                              ; Disable interrupts

    call WaitVBlank                 ; Turn off LCD
    ld hl, rLCDC
    res LCDCF_ON_BIT, [hl]

    ld a, IEF_VBLANK | IEF_LCDC     ; Enable vblank and status interrupts
    ld [rIE], a
    ld a, STATF_MODE00              ; Set hblank to cause a status interrupt
    ld [rSTAT], a

    ld hl, Tiles                    ; Copy tiles to VRAM
    ld bc, _VRAM
    ld a, LOGO_WIDTH * LOGO_HEIGHT
    call DMACopy

    ld hl, TileMap                  ; Copy tilemap to VRAM
    ld bc, _SCRN0
    ld a, 32
    call DMACopy

    xor a, $0                       ; Reset offset variables
    ld [HBlankOffset], a
    ld [HBlankOffset + 1], a

    ld hl, rLCDC                    ; Turn on LCD
    set LCDCF_ON_BIT, [hl]

    ei                              ; Enable interrupts

Loop:
    halt                            ; Wait until next interrupt
    jr Loop

HBlankHandler:
    ld hl, Gradient                 ; Calculate address to gradient color
    ld a, [HBlankOffset]            ; Address is offset times six (two-byte colors in groups of three)
    rla
    ld b, $0
    ld c, a
    add hl, bc
    add hl, bc
    add hl, bc

    ld a, BCPSF_AUTOINC             ; Set first palette index with auto increment
    ld [rBCPS], a
    REPT 6
    ld a, [hl+]                     ; Update palette byte by byte
    ld [rBCPD], a
    ENDR

    ld a, [HBlankOffset]            ; Increment color hblank offset
    inc a
    and a, (GRADIENT_STEPS - 1)
    ld [HBlankOffset], a

    reti

VBlankHandler:
    ld a, [VBlankOffset]            ; Increment color vblank offset and
    dec a                           ; set hblank offset to start from vblank offset
    ld [VBlankOffset], a
    ld [HBlankOffset], a
    reti

WaitVBlank:
    ld a, [rLY]
    cp a, $90
    jr nz, WaitVBlank
    ret

; hl = Source address
; bc = Target address
; a = Number of 16 byte blocks to copy
DMACopy:
    ld d, a                         ; Save a
    ld a, h                         ; Set source
    ld [rHDMA1], a
    ld a, l
    ld [rHDMA2], a
    ld a, b                         ; Set target
    ld [rHDMA3], a
    ld a, c
    ld [rHDMA4], a
    ld a, d                         ; Start general purpose DMA transfer
    ld [rHDMA5], a
    ret

SECTION "Data", ROM0, ALIGN[4]
Tiles:
    INCBIN "monoglyph.2bpp"

TileMap:
OFF = 0
Y = 0
    REPT 18
X = 0
        REPT 32
            IF Y >= LOGO_OFFSET_Y && \
               Y < LOGO_HEIGHT + LOGO_OFFSET_Y && \
               X >= LOGO_OFFSET_X && \
               X < LOGO_WIDTH + LOGO_OFFSET_X
                DB OFF
OFF = OFF + 1
            ELSE
                DB 0
            ENDC
X = X + 1
        ENDR
Y = Y + 1
    ENDR

Gradient:
    INCLUDE "gradient.inc"

SECTION "Variables", WRAM0[$C000]
HBlankOffset:   DS 1
VBlankOffset:   DS 1
