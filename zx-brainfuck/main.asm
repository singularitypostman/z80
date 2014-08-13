org 30000

tv_flag     equ $5c3c       ; Variavel das flags da tv
last_k      equ $5c08       ; Contem a ultima tecla pressionada

OP_INC_DP   equ ">"
OP_DEC_DP   equ "<"
OP_INC_VAL  equ "+"
OP_DEC_VAL  equ "-"
OP_OUT      equ "."
OP_IN       equ ","
OP_JMP_FWD  equ "["
OP_JMP_BCK  equ "]"

;brainfuck   db  "++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>.", 0
;brainfuck   db  "+++++++++++++++++++++++++++++++++.", 0
brainfuck   db  "++++[>++++++++++<-]>++.>+++++++++++++.<<++[>.<-]>>.<<+++[>.<-]>>.<<++++[>.<-]>>.<<+++++[>.<-]>>.", 0
;brainfuck   db  "++[>+<-]" ,0
memory_pos  db  $0,$80
source_pos  db  $0,$0

start                       ; Começa em $75a2
    xor a                   ; O mesmo que LD a, 0
    ld (tv_flag), a         ; Faz com que o rst $10 envie output pra tv
    push bc                 ; Guarda BC na stack

main
    ld hl, brainfuck
    ld de, (source_pos)

    add hl, de
    ld a, (hl)

    ; EOF
    cp $0
    jr z, end_main

    ; >
    cp OP_INC_DP
    jr z, F_INC_DP

    ; <
    cp OP_DEC_DP
    jr z, F_DEC_DP

    ; +
    cp OP_INC_VAL
    jr z, F_INC_VAL

    ; -
    cp OP_DEC_VAL
    jr z, F_DEC_VAL

    ; .
    cp OP_OUT
    jr z, F_OUT
    
    ; ,
    cp OP_IN
    jr z, F_IN
    
    ; [
    cp OP_JMP_FWD
    jr z, F_JMP_FWD
    
    ; ]
    cp OP_JMP_BCK
    jr z, F_JMP_BCK

continue
    ld de, (source_pos)
    inc de
    ld (source_pos), de
    jr main

end_main
    pop bc                  ; Tira o BC da stack
    ret                     ; Sai para o BASIC

; -------------------------------------

F_INC_DP
    ld de, (memory_pos)
    inc de
    ld (memory_pos), de
    jr continue

; -------------------------------------

F_DEC_DP
    ld de, (memory_pos)
    dec de
    ld (memory_pos), de
    jr continue

; -------------------------------------

F_INC_VAL
    ld de, (memory_pos)
    ld a, (de)
    inc a
    ld (de), a
    jr continue

; -------------------------------------

F_DEC_VAL
    ld de, (memory_pos)
    ld a, (de)
    dec a
    ld (de), a
    jr continue

; -------------------------------------

F_OUT
    ld de, (memory_pos)
    ld a, (de)
    rst $10
    jr continue

; -------------------------------------

F_IN
    ld a, $0
    ld (last_k), a          ; Limpa o valor da ultima tecla pressionada
F_IN_LOOP
    ld a, (last_k)          ; Se o valor da ultima tecla pressionada ainda
    cp $0                   ; for 0, é porque ainda não se pressionou nenhuma
    jr z, F_IN_LOOP         ; tecla, por isso... repete
    ld de, (memory_pos)
    ld (de), a
    jr continue

; -------------------------------------

F_JMP_FWD
    ld de, (memory_pos)
    ld a, (de)
    cp 0
    jr z, SKIP_LOOP
    
    ld de, (source_pos)
    push de
    jr continue
    
SKIP_LOOP
    ld de, (source_pos)
    inc de
    ld (source_pos), de

    ld hl, brainfuck

    add hl, de
    ld a, (hl)
    cp OP_JMP_BCK
    jr nz, SKIP_LOOP

    ld de, (source_pos)
    inc de
    ld (source_pos), de
    jp main

; -------------------------------------

F_JMP_BCK
    pop de
    ld (source_pos), de
    jp main

; -------------------------------------

end start