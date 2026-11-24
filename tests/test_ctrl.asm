# Cobertura Tabla 3:
# - beq, bne: cada uno tomado y no tomado, y un salto hacia atras (bucle)
# - j: salto incondicional explicito
# - jal, jr: procedimiento no hoja (calc_outer llama a calc_inner),
#            guardando $ra en la pila y retornando correctamente
# - syscall: servicios 11 (imprimir) y 10 (terminar)

.data
lbl_br: .asciiz "BR:"
lbl_lp: .asciiz "LP:"
lbl_fn: .asciiz "FN:"

.text
.globl main
main:
    # 1) beq tomado y no tomado
    li $t0, 7
    li $t1, 7
    li $t2, 9
    li $s0, 0
    beq $t0, $t1, beq_taken    # TOMADO
    addi $s0, $s0, 100         # no debe ejecutarse
beq_taken:
    addi $s0, $s0, 1           # $s0 = 1
    beq $t0, $t2, beq_skip     # NO TOMADO
    addi $s0, $s0, 2           # $s0 = 3 (0x00000003)
beq_skip:

    # 2) bne tomado y no tomado
    li $s1, 0
    bne $t0, $t2, bne_taken    # TOMADO
    addi $s1, $s1, 100         # no debe ejecutarse
bne_taken:
    addi $s1, $s1, 4           # $s1 = 4
    bne $t0, $t1, bne_skip     # NO TOMADO
    addi $s1, $s1, 8           # $s1 = 12 (0x0000000C)
bne_skip:
    la $a0, lbl_br
    jal print_pair

    # 3) Salto hacia atras (bucle suma 1+2+3+4+5 = 15 = 0x0F) y salto j
    li $t3, 1
    li $t4, 6
    li $s0, 0
sum_loop:
    add $s0, $s0, $t3
    addi $t3, $t3, 1
    bne $t3, $t4, sum_loop     # salto hacia atras

    li $s1, 10
    j jump_target              # salto j explicito
    addi $s1, $s1, 99          # no debe ejecutarse
jump_target:
    addi $s1, $s1, 5           # $s1 = 15 (0x0000000F)
    la $a0, lbl_lp
    jal print_pair

    # 4) Procedimiento no hoja: calc_outer(6) -> calc_inner(6) + 10 = 13 + 10 = 23 (0x17)
    li $a0, 6
    jal calc_outer
    move $s0, $v0
    la $a0, lbl_fn
    jal print_str
    move $a0, $s0
    jal print_hex
    li $a0, 10
    li $v0, 11
    syscall

    li $v0, 10
    syscall

# Procedimiento no hoja: guarda $ra en la pila y llama a calc_inner
calc_outer:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal calc_inner             # $v0 = 2*x + 1
    addi $v0, $v0, 10          # $v0 = 2*x + 11
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Procedimiento hoja: devuelve 2*x + 1
calc_inner:
    add $v0, $a0, $a0
    addi $v0, $v0, 1
    jr $ra

print_pair:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal print_str
    move $a0, $s0
    jal print_hex
    li $a0, 32
    li $v0, 11
    syscall
    move $a0, $s1
    jal print_hex
    li $a0, 10
    li $v0, 11
    syscall
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

print_str:
    move $t8, $a0
ps_loop:
    lbu $a0, 0($t8)
    beq $a0, $zero, ps_end
    li $v0, 11
    syscall
    addi $t8, $t8, 1
    j ps_loop
ps_end:
    jr $ra

print_hex:
    move $t8, $a0
    li $t9, 8
ph_loop:
    srl $t7, $t8, 28
    slti $t6, $t7, 10
    beq $t6, $zero, ph_let
    addi $a0, $t7, 48
    j ph_out
ph_let:
    addi $a0, $t7, 55
ph_out:
    li $v0, 11
    syscall
    sll $t8, $t8, 4
    addi $t9, $t9, -1
    bne $t9, $zero, ph_loop
    jr $ra