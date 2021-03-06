; Begin code at $7530
org $7530

; System variables
tv_flag     EQU $5c3c   ; TV flags
last_k      EQU $5c08   ; Last pressed key

; Screen is 256x192

MAX_STARS   EQU 100

; "Allocate" memory for all the stars
STARS
    REPT MAX_STARS
        ; Star Structure
        db $0   ; X
        db $0   ; Y
        db $0   ; Speed
        db $0   ; Previous X
        db $0   ; Previous Y
    ENDM


start
    xor a
    ld (tv_flag), a
    push bc

    call clear_screen   ; Clear the screen
    call init_stars  ; Initialize the stars data

main_start
    ld hl, STARS    ; points to X of the first star
    ld c, MAX_STARS ; Counter - stars to process

main
; CLEAR THE LAST POSITION
    push bc     ; save counter in the stack

    ld de, $3
    add hl, de  ; skip 3 bytes to PrevX

    ld a, (hl)
    ld d, a     ; Save PrevX to D

    inc hl      ; points to PrevY

    ld a, (hl)
    ld e, a     ; Save PrevY to E

    push hl
    call get_screen_address
    ; Video RAM address for those X,Y is now in HL and the bit needed
    ; to be set in that address value is in A
    call clear_pixel    ; Uses those values and clears the pixel
    pop hl

    ld bc, $4
    sbc hl, bc  ; Go back to X

; WRITES THE PIXEL
    ld a, (hl)  ; HL should point to X
    ld d, a     ; Save X to D

    inc hl      ; points to Y

    ld a, (hl)
    ld e, a     ; Save Y to E

    push hl
    call get_screen_address
    ; Video RAM address for those X,Y is now in HL and the bit needed
    ; to be set in that address value is in A
    call write_pixel    ; Uses those values and writes the pixel
    pop hl

    ld bc, $4
    add hl, bc  ; Skip 4 positions to the next star

    pop bc      ; Remove counter from stack
    dec c       ; Decrement counter

    jr nz, main ; Repeat if not zero

    call increment_x    ; Increment X position in each star
    jr main_start   ; Do it all over again

    pop bc
    ret

PROC
; D = minimum value
; E = maximum value
get_rnd
    push bc

get_rnd_loop
    push de
    ld de, 0
    ld b, 0
    ld c, e
    ld hl, table
    add hl, bc

    ld c, (hl)

    push hl

    ld a, e
    inc a
    and 7
    ld e, a

    ld h, c
    ld l, b

    sbc hl, bc
    sbc hl, bc
    sbc hl, bc

    ld c, d
    add hl, bc

    ld d, h

    ld (get_rnd_loop+2), de

    ld a,l
    cpl

    pop hl

    ld (hl), a
    
    pop de
    
    ld h, a ; Save A to H

    ld a, e ; Maximum value in A
    cp h    ; Compare with random value
    jr z, get_rnd_ret
    jr c, get_rnd_loop

    ld a, d ; Minimum value in A
    cp h    ; Compare with random value
    jr z, get_rnd_ret
    jr c, get_rnd_ret

    jr get_rnd_loop

get_rnd_ret
    ld a, h
    and a   ; Reset carry
    pop bc
    ret
    
table
    db   82,97,120,111,102,116,20,12
ENDP

PROC
; Initialize stars X, Y and Speed with "random" values
init_stars
    push bc
    ld hl, STARS    ; HL points to X of first star
    ld c, MAX_STARS ; Counter

init_stars_loop
    push bc

    push hl
    ld d, 0
    ld e, 255
    call get_rnd    ; Get a random value between 0 and 255
    pop hl

    ld (hl), a      ; Set X value

    inc hl          ; points to Y

    push hl
    ld d, 0
    ld e, 191
    call get_rnd    ; Get a random value between 0 and 191
    pop hl

    ld (hl), a      ; Set Y value

    inc hl          ; points to Speed

    push hl
    ld d, 1
    ld e, 10
    call get_rnd    ; Get a random value between 1 and 10
    pop hl

    ld (hl), a      ; Set Speed value

    ld bc, $3
    add hl, bc      ; Skip 3 bytes to the next star

    pop bc
    dec c           ; Decrement counter
    jr nz, init_stars_loop  ; If not zero, do it again

    pop bc
    ret
ENDP

PROC
; Increment X
increment_x
    push bc
    ld hl, STARS
    ld c, MAX_STARS ; Counter

increment_x_loop
; First lets copy current position to previous position
    ld d, (hl)  ; Save current X to D
    inc hl      ; points to Y
    ld e, (hl)  ; Save current Y to E

    inc hl      ; points to Speed
    inc hl      ; points to PrevX
    ld (hl), d  ; Save X
    inc hl      ; PrevY
    ld (hl), e  ; Save Y

    ld de, $4
    sbc hl, de  ; Go back 4 bytes to X

    ld a, (hl)  ; Is X at $FF - end of screen
    cp $ff
    jr z, increment_x_zero  ; Yes, lets reset it

; Increments X position by speed value
; X = X + Speed
    inc hl      ; points to Y
    inc hl      ; points to Speed

    ld b, (hl)  ; Read speed to B

    dec hl      ; Back to Y
    dec hl      ; Back to X

    add a, b    ; X = X + Speed
    jr c, increment_x_zero ; If carry is set, it passed $ff, lets reset

increment_x_update
; Saves to X the value in A
    ld (hl), a  ; Save X with the value in A

    ld de, $5
    add hl, de  ; Skip 5 bytes to the next star

    dec c       ; Decrement counter
    jr nz, increment_x_loop ; If not zero, do it again

    pop bc
    ret

increment_x_zero
; Sets X to 0 and Y and Speed to random values
    push bc
    inc hl      ; point to Y

    push hl
    ld d, 0
    ld e, 191
    call get_rnd
    pop hl

    ld (hl), a  ; Set Y value

    inc hl      ; point to speed

    push hl
    ld d, 1
    ld e, 10
    call get_rnd
    pop hl

    ld (hl), a  ; Set Speed value

    ld de, $2
    sbc hl, de  ; Get back to X position

    ld a, $0    ; X = 0
    pop bc
    jr increment_x_update
ENDP

PROC
; Video Ram Address in HL
; Pixel to write in A
; Creates a binary value to allow to set the correct bit at HL
write_pixel
    push bc
    ld b, a     ; Counter - value in A
    ld c, $0    ; Start with all bits set to 0
    scf         ; Set carry flag

write_pixel_loop
    ld a, c     ; A = C
    rra         ; Rotate right with carry
    ld c, a     ; C = A

    ld a, b     ; A = B (counter)
    jr z, write_pixel_do_it ; If B is zero, do it!
    dec b       ; B = B - 1
    jr write_pixel_loop ; Do it all over again

write_pixel_do_it
    ld a, (hl)  ; Read the value at HL
    or c        ; OR it with the value in C (the bit to be set)
    ld (hl), a  ; Save it back to HL
    pop bc
    ret
ENDP

PROC
; Video Ram Address in HL
; Pixel to write in A
; Creates a binary value to allow to unset the correct bit at HL
clear_pixel
    push bc
    ld b, a     ; Counter - value in A
    ld c, $ff   ; Start with all bits set to 1
    and a       ; Reset carry flag

clear_pixel_loop
    ld a, c     ; A = C
    rra         ; Rotate right with carry
    ld c, a     ; C = A

    ld a, b     ; A = B (counter)
    jr z, clear_pixel_do_it ; If B is zero, do it!
    dec b       ; B = B - 1
    jr clear_pixel_loop ; Do it all over again

clear_pixel_do_it
    ld a, (hl)  ; Read the value at HL
    and c       ; AND it with the value in C (the bit to be unset)
    ld (hl), a  ; Save it back to HL
    pop bc
    ret
ENDP

PROC
; Calculate the high byte of the screen address and store in H reg.
; On Entry: D reg = X coord,  E reg = Y coord
; On Exit: HL = screen address, A = pixel postion
get_screen_address
    ld a,e
    and %00000111
    ld h,a
    ld a,e
    rra
    rra
    rra
    and %00011000
    or h
    or %01000000
    ld h,a
; Calculate the low byte of the screen address and store in L reg.
    ld a,d
    rra
    rra
    rra
    and %00011111
    ld l,a
    ld a,e
    rla
    rla
    and %11100000
    or l
    ld l,a
; Calculate pixel position and store in A reg.
    ld a,d
    and %00000111
    ret
ENDP

PROC
INCLUDE "clear.asm"
ENDP

END start