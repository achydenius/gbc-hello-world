INCLUDE "../hardware.inc"

LCDCF_ON_BIT    EQU 7
WIDTH           EQU 8
HEIGHT          EQU 8

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

    ld b, b

    ld hl, rLCDC                    ; Turn on LCD
    set LCDCF_ON_BIT, [hl]

    ld a, KEY1F_PREPARE             ; Set CPU double speed mode
    ld [rKEY1], a
    stop

    ei                              ; Enable interrupts

Loop:
    jp Loop

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
