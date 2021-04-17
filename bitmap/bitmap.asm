INCLUDE "../hardware.inc"

LCDCF_ON_BIT    EQU 7
WIDTH           EQU 16
HEIGHT          EQU 16

SECTION "Header", ROM0[$100]
    jp Start

SECTION "Code", ROM0[$150]
Start:
    di                              ; Disable interrupts

    call WaitVBlank                 ; Turn off LCD
    ld hl, rLCDC
    res LCDCF_ON_BIT, [hl]

    ld a, %10000010                 ; Set second palette color to black
    ldh [$FF68], a
    xor a, a
    ldh [$FF69], a
    ldh [$FF69], a

    ld hl, _VRAM
    ld bc, WIDTH * HEIGHT * 16
    call Clear

    call InitTilemap

    ld hl, rLCDC                    ; Turn on LCD
    set LCDCF_ON_BIT, [hl]

    ld a, KEY1F_PREPARE             ; Set CPU double speed mode
    ld [rKEY1], a
    stop

    ei                              ; Enable interrupts

Loop:
    call WaitVBlank

    ld b, 9
    ld c, 10
    ld d, 75
    ld e, 11
    call DrawLine
    ; call PutPixel
    jr Loop

; Plot a single pixel with color 1
; b = x-coordinate
; c = y-coordinate
PutPixel:
    ld hl, _VRAM                    ; Base address

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

    ld a, b                         ; Get x pixel mask
    and a, %00000111
    ld de, Pixels
    add a, e
    ld e, a
    ld a, [de]

    or a, [hl]
    ld [hl], a

    ret

; Draw a line with color 1
; b = x0
; c = y0
; d = x1
; e = y1
DrawLine:
    ld a, d
    sub a, b
    ld [dx], a
    sra a
    ld [dx2], a                     ; TODO: Might not need storing to RAM?

    ld a, e
    sub a, c
    ld [dy], a

    ld a, b                         ; Get x pixel mask
    and a, %00000111
    ld hl, Pixels
    add a, l
    ld l, a
    ld a, [hl]
    ld d, a                         ; d = Pixel mask

    ld hl, dx2
    ld a, [dy]
    sub a, [hl]
    ld e, a                         ; e = Diff

    ld hl, _VRAM                    ; Base address

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

    ld a, [dx]
    ld c, a                         ; c = x counter

.plot:
    ld a, d
    or a, [hl]
    ld [hl], a

    rrc d
    jr nc, .sameColumn

    inc h                           ; Move to next column
.sameColumn:
    ld a, e                         ; 1
    bit 7, a                        ; 2
    jr nz, .sameRow                 ; 3/2

    inc l                           ;   1   Move to next row
    inc l                           ;   1
    ld a, [dx]                      ;   4
    ld b, a                         ;   1
    ld a, e                         ;   1
    sub a, b                        ;   1
    ld e, a                         ;   1
.sameRow:
    ld a, [dy]                      ; 4
    ld b, a                         ; 1
    ld a, e                         ; 1
    add a, b                        ; 1
    ld e, a                         ; 1

    dec c                           ; 1
    jr nz, .plot

    ret

; Wait until beginning of the next vblank
WaitVBlank:
    ld a, [rLY]
    cp a, $90
    jr nz, WaitVBlank
    ret

; Clear (set to zero) bytes
; hl = Start address
; bc = Number of bytes to clear
Clear:
    xor a, a
    ld [hl+], a
    dec bc
    ld a, b
    or a, c
    jr nz, Clear
    ret

; Init column-major area in tilemap for bitmap graphics
; WIDTH and HEIGHT constants define the dimensions
InitTilemap:
    xor a, a                        ; a = Tile index
    ld b, WIDTH                     ; b = Column index
    ld hl, _SCRN0
.col:
    push hl
    ld c, HEIGHT                    ; c = Row index
.row:
    ld [hl], a
    inc a
    ld d, $0
    ld e, $20
    add hl, de
    dec c
    jr nz, .row

    pop hl
    inc hl
    dec b
    jr nz, .col

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

SECTION "Variables", WRAM0[$C000]
dx:     DS 1
dx2:    DS 1
dy:     DS 1
