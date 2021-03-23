SECTION "Header", ROM0[$0100]
    jr Start

SECTION "Code", ROM0[$0150]
Start:
    ; Wait for the next vblank
    ldh a, [$FF44]
    cp a, $90
    jr nz, Start

    ; Select the first palette color
    ; and set auto increment flag
    ld a, %10000000
    ldh [$FF68], a

    ; Set the color
    xor a, a
    ldh [$FF69], a
    ld a, $FC
    ldh [$FF69], a

Loop:
    ; Enter low-power mode
    halt
    jr Loop
