INCLUDE "hardware.inc"

SetColor: MACRO
    ld a, \2
    ldh [rBCPD], a
    ld a, \1
    ldh [rBCPD], a
    ENDM

SECTION "Header", ROM0[$0100]
    jp Start

SECTION "Code", ROM0[$0150]
Start:
    ld b, $0
Loop:
    call TestButtonA
    jr nz, Loop

    call WaitVBlank
    ld a, BCPSF_AUTOINC
    ldh [rBCPS], a

    ld a, b
    xor $1
    ld b, a
    jr nz, .magenta

    SetColor $7F, $FF
    jr Loop
.magenta:
    SetColor $7C, $1F
    jr Loop

TestButtonA:
    ld hl, rP1
    ld [hl], ~P1F_5
    bit 0, [hl]
    ret

WaitVBlank:
    ldh a, [rLY]
    cp a, $90
    jr nz, WaitVBlank
    ret
