INCLUDE "hardware.inc"

MAP_WIDTH       EQU 32
GFX_WIDTH       EQU 10
GFX_HEIGHT      EQU 12
GFX_OFFSET      EQU 5 + (3 * MAP_WIDTH)
GRADIENT_STEPS  EQU 64
SINE_STEPS      EQU 256

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

    ld a, $0                    ; Reset variables
    ld hl, Variables
    REPT 6
    ld [hl+], a
    ENDR

    ld hl, rLCDC                ; Turn on LCD
    set 7, [hl]

    ld a, KEY1F_PREPARE         ; Set CPU double speed mode
    ld [rKEY1], a
    stop

    ei                          ; Enable interrupts

Loop:
    ld a, ~P1F_5                ; Read button states
    ld [rP1], a
    ld a, [rP1]
    cpl                         ; A set bit 0 indicates pressed A button
    and a, $1

    ld b, a                     ; Compare current and previous button states
    ld a, [ButtonState]
    cp a, b

    ld a, b                     ; Update button state variable
    ld [ButtonState], a

    jr z, Loop                  ; Continue if current and previous states are equal
    cp a, $0                    ; Continue if current state is button press
    jp z, Loop

    ld a, [EffectOn]            ; Toggle effect state variable
    xor a, $1
    ld [EffectOn], a
    ld a, $0                    ; Reset horizontal scroll register
    ld [rSCX], a
    jr Loop

HBlankHandler:
    push af
    push bc

    ld hl, Gradient             ; Calculate address to gradient color
    ld a, [HBColorOffset]       ; Address is offset times six (two-byte colors in groups of three)
    rla
    ld b, $0
    ld c, a
    add hl, bc
    add hl, bc
    add hl, bc

    ld a, BCPSF_AUTOINC         ; Set first palette index with auto increment
    ld [rBCPS], a
    REPT 6
    ld a, [hl+]                 ; Update palette byte by byte
    ld [rBCPD], a
    ENDR

    ld a, [HBColorOffset]       ; Increment color hblank offset
    inc a
    and a, (GRADIENT_STEPS- 1)
    ld [HBColorOffset], a

    ld a, [EffectOn]            ; Apply sine effect only if effect variable is toggled
    cp a, $0
    jr z, .return

    ld a, [HBSineOffset]        ; Calculate address to sine table
    ld b, $0
    ld c, a
    ld hl, Sine
    add hl, bc
    ld a, [hl]
    ld [rSCX], a

.return:
    ld a, [HBSineOffset]        ; Increment sine hblank offset
    inc a
    and a, (SINE_STEPS-1)
    ld [HBSineOffset], a

    pop bc
    pop af
    reti

VBlankHandler:
    push af
    push bc

    ld a, [VBColorOffset]       ; Increment color vblank offset and
    dec a                       ; start color hblank offset from vblank offset
    ld [VBColorOffset], a
    ld [HBColorOffset], a

    ld a, [VBSineOffset]        ; Increment sine vblank offset and
    inc a                       ; start sine hblank offset from vblank offset
    ld [VBSineOffset], a
    ld [HBSineOffset], a

    pop bc
    pop af
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
    ld d, a                     ; Save a

    ld a, h                     ; Set source
    ld [rHDMA1], a
    ld a, l
    ld [rHDMA2], a

    ld a, b                     ; Set target
    ld [rHDMA3], a
    ld a, c
    ld [rHDMA4], a

    ld a, d                     ; Start general purpose DMA transfer
    ld [rHDMA5], a
    ret

SECTION "Data", ROM0, ALIGN[4]
Tiles:
    INCBIN "monoglyph.2bpp"

Gradient:
    INCLUDE "gradient.inc"

Sine:
ANGLE = 0.0
    REPT 256
    DB (MUL(32.0, SIN(ANGLE)) + 1.0) >> 16
ANGLE = ANGLE + 256.0
    ENDR

SECTION "Variables", WRAM0[$C000]
Variables:
HBColorOffset:  DS 1
VBColorOffset:  DS 1
VBSineOffset:   DS 1
HBSineOffset:   DS 1
ButtonState:    DS 1
EffectOn:       DS 1
