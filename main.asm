INCLUDE "hardware.inc"

SECTION "VBlank", ROM0[$40]
    jp VBlankHandler

SECTION "Header", ROM0[$100]
    jp Start

SECTION "Code", ROM0[$150]
Start:
    di                  ; Disable interrupts
    ld a, IEF_VBLANK    ; Set v-blank interrupt handler
    ld [rIE], a
    ld a, $0            ; Reset offset counter
    ld [Offset], a
    ei                  ; Enable interrupts

Loop:
    jr Loop

VBlankHandler:
    ld a, BCPSF_AUTOINC ; Set first palette index with auto increment
    ld [rBCPS], a

    ld hl, Gradient     ; Calculate address to gradient color
    ld a, [Offset]
    ld b, $0
    ld c, a
    add hl, bc

    ld a, [hl+]         ; Update first two-byte palette color
    ld [rBCPD], a
    ld a, [hl]
    ld [rBCPD], a

    ld a, [Offset]      ; Increment offset to next two-byte color
    add a, $2
    and a, $7F
    ld [Offset], a

    reti

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

SECTION "Variables", WRAM0[$C000]
Offset: DS 1
