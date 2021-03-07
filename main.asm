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

    xor a, a                        ; Reset variables
    ld hl, Variables
    ld b, 6
.resetVariable:
    ld [hl+], a
    dec b
    jr nz, .resetVariable

    ld hl, rLCDC                    ; Turn on LCD
    set LCDCF_ON_BIT, [hl]

    ld a, KEY1F_PREPARE             ; Set CPU double speed mode
    ld [rKEY1], a
    stop

    ei                              ; Enable interrupts

Loop:
    ld a, ~P1F_5                    ; Read button states
    ld [rP1], a
    ld a, [rP1]
    cpl                             ; Complement bits so that set bit indicates a pressed button
    and a, $1                       ; Ignore others than A button

    ld hl, ButtonState              ; Compare previous and current button state and update the variable
    cp a, [hl]
    ld [hl], a

    jr z, Loop                      ; If current and previous state were equal, do nothing
    cp a, $0                        ; If current state is button press, do nothing
    jr z, Loop

    ld a, [EffectOn]                ; Toggle effect state variable
    xor a, $1
    ld [EffectOn], a

    xor a, a                        ; Reset horizontal scroll register
    ld [rSCX], a
    jr Loop

HBlankHandler:
    push af
    push hl

    ld hl, Gradient                 ; Calculate address to gradient color
    ld a, [HBColorOffset]           ; Address is offset times six (two-byte colors in groups of three)
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

    ld a, [HBColorOffset]           ; Increment color hblank offset
    inc a
    and a, (GRADIENT_STEPS - 1)
    ld [HBColorOffset], a

    ld a, [EffectOn]                ; Apply sine effect only if effect variable is toggled
    cp a, $0
    jr z, .return

    ld a, [HBSineOffset]            ; Calculate address to sine table
    ld b, $0
    ld c, a
    ld hl, Sine
    add hl, bc
    ld a, [hl]
    ld [rSCX], a

.return:
    ld hl, HBSineOffset             ; Increment sine hblank offset
    inc [hl]

    pop hl
    pop af
    reti

VBlankHandler:
    push af
    push hl

    ld a, [VBColorOffset]           ; Increment color vblank offset and
    dec a                           ; start color hblank offset from vblank offset
    ld [VBColorOffset], a
    ld [HBColorOffset], a

    ld a, [VBSineOffset]            ; Increment sine vblank offset and
    inc a                           ; start sine hblank offset from vblank offset
    ld [VBSineOffset], a
    ld [HBSineOffset], a

    pop hl
    pop af
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
