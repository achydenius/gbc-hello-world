SECTION "Header", ROM0[$100]
Entry:
    di
    jp Start

SECTION "Code", ROM0[$150]
Start:
    ld a, $0
    ld b, b     ; Breakpoint
Loop:
    inc a
    jr Loop
