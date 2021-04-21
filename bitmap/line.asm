SECTION "Line", ROM0

; \1 = inc or dec instruction depending on the slope
; a  = dy
; d  = Pixel mask
DrawLow:\
    MACRO
    ld [dy], a

    ; Calculate D
    ld a, [dxHalf]
    ld b, a
    ld a, [dy]
    sub a, b
    ld e, a                         ; e = D

    ld a, [dx]
    ld c, a                         ; c = x counter
.step\@:
    ld a, d
    or a, [hl]
    ld [hl], a

    rrc d
    jr nc, .sameColumn\@

    ; Move to the next column
    inc h

    ; Continue in the same column
.sameColumn\@:
    ld a, e                         ; 1
    bit 7, a                        ; 2
    jr nz, .sameRow\@               ; 3/2

    ; Move to the next row
    \1 l                            ;   1
    \1 l                            ;   1
    ld a, [dx]                      ;   4
    ld b, a                         ;   1
    ld a, e                         ;   1
    sub a, b                        ;   1
    ld e, a                         ;   1

    ; Continue in the same row
.sameRow\@:
    ld a, [dy]                      ; 4
    ld b, a                         ; 1
    ld a, e                         ; 1
    add a, b                        ; 1
    ld e, a                         ; 1

    dec c                           ; 1
    jr nz, .step\@
    ENDM

; Draw a line with color 1
; b = x0
; c = y0
; d = x1
; e = y1
DrawLine:
    ; Swap x-coordinates if x0 > x1
    ld a, b
    cp a, d
    jr c, .skip

    ld b, d
    ld d, a
    ld a, c
    ld c, e
    ld e, a
.skip:
    ; Calculate and store dx and dx/2
    ld a, d
    sub a, b
    ld [dx], a
    sra a
    ld [dxHalf], a                  ; TODO: Can this be preserved in a register?

    ; Get pixel mask for a pixel inside character
    ld a, b
    and a, %00000111
    ld hl, Pixels
    add a, l
    ld l, a
    ld a, [hl]
    ld d, a                         ; d = Pixel mask

    ; Calculate address to row in character
    ld hl, _VRAM

    ld a, c                         ; Add y offset
    sla a
    add a, l
    ld l, a

    ld a, b                         ; Add x character offset
    sra a
    sra a
    sra a
    add a, h
    ld h, a

    ; Calculate dy and invert it if slope is descending
    ld a, e
    sub a, c
    bit 7, a
    jr z, .ascending
    cpl
    inc a

    DrawLow dec
    ret

.ascending:
    DrawLow inc
    ret

SECTION "Data", ROM0
Pixels:
    DB %10000000
    DB %01000000
    DB %00100000
    DB %00010000
    DB %00001000
    DB %00000100
    DB %00000010
    DB %00000001

SECTION "Variables", WRAM0
dx:     DS 1
dxHalf: DS 1
dy:     DS 1
