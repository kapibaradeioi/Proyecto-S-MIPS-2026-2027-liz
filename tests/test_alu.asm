# Cobertura Tabla 3:
# - add, sub: operandos positivos y negativos
# - and, or: operandos con unos en los 16 bits altos
# - slt, slti: resultado 1 y 0, con operando negativo (signo vs sin signo)
# - sll, srl: shamt = 0 y shamt != 0; srl sobre numero negativo
# - addi: inmediato negativo
# - addiu, addu: mediante pseudoinstrucciones li y move
# - andi, ori: inmediato con bit 15 = 1 (extension con ceros)
# - lui: inmediato con bit 15 = 1
# - $zero: escritura en $zero comprobando que sigue valiendo 0
# - syscall: servicios 11 (imprimir) y 10 (terminar)

.data
lbl_add: .asciiz "ADD:"
lbl_sub: .asciiz "SUB:"
lbl_log: .asciiz "LOG:"
lbl_slt: .asciiz "SLT:"
lbl_sli: .asciiz "SLI:"
lbl_sll: .asciiz "SLL:"
lbl_srl: .asciiz "SRL:"
lbl_imm: .asciiz "IMM:"
lbl_zex: .asciiz "ZEX:"
lbl_lui: .asciiz "LUI:"

.text
.globl main
main:
    # 1) add: pos+pos (10+25=35=0x23) y pos+neg (10+(-30)=-20=0xFFFFFFEC)
    li $t0, 10
    li $t1, 25
    li $t2, -30
    add $s0, $t0, $t1
    add $s1, $t0, $t2
    la $a0, lbl_add
    jal print_pair

    # 2) sub: pos-pos (40-15=25=0x19) y neg-pos (-10-5=-15=0xFFFFFFF1)
    li $t0, 40
    li $t1, 15
    li $t2, -10
    li $t3, 5
    sub $s0, $t0, $t1
    sub $s1, $t2, $t3
    la $a0, lbl_sub
    jal print_pair

    # 3) and, or con unos en los 16 bits altos
    lui $t0, 0xAAAA
    ori $t0, $t0, 0x1234
    lui $t1, 0xFF00
    ori $t1, $t1, 0x0FF0
    and $s0, $t0, $t1          # 0xAA000230
    or  $s1, $t0, $t1          # 0xFFAA1FF4
    la $a0, lbl_log
    jal print_pair

    # 4) slt: -5 < 3 -> 1 (con signo), 3 < -5 -> 0
    li $t0, -5
    li $t1, 3
    slt $s0, $t0, $t1          # 0x00000001
    slt $s1, $t1, $t0          # 0x00000000
    la $a0, lbl_slt
    jal print_pair

    # 5) slti: -5 < 10 -> 1, 10 < -5 -> 0
    li $t0, -5
    li $t1, 10
    slti $s0, $t0, 10          # 0x00000001
    slti $s1, $t1, -5          # 0x00000000
    la $a0, lbl_sli
    jal print_pair

    # 6) sll con shamt=0 y shamt=4 sobre valor negativo (0x80000012)
    lui $t0, 0x8000
    ori $t0, $t0, 0x0012
    sll $s0, $t0, 0            # 0x80000012
    sll $s1, $t0, 4            # 0x00000120
    la $a0, lbl_sll
    jal print_pair

    # 7) srl con shamt=0 y shamt=4 sobre valor negativo (entran ceros)
    lui $t0, 0x8000
    ori $t0, $t0, 0x0012
    srl $s0, $t0, 0            # 0x80000012
    srl $s1, $t0, 4            # 0x08000001
    la $a0, lbl_srl
    jal print_pair

    # 8) addi (inmediato negativo) y addiu/addu (mediante li y move)
    li $t0, 50
    addi $s0, $t0, -100        # -50 = 0xFFFFFFCE
    li $t1, -1234              # genera addiu $t1, $zero, -1234
    move $s1, $t1              # genera addu $s1, $zero, $t1 (0xFFFFFB2E)
    la $a0, lbl_imm
    jal print_pair

    # 9) andi, ori con inmediato cuyo bit 15 vale 1 (extension con ceros)
    li $t0, -1                 # 0xFFFFFFFF
    andi $s0, $t0, 0x800F      # debe ser 0x0000800F (no 0xFFFF800F)
    lui $t1, 0x1234
    ori  $s1, $t1, 0x80F0      # debe ser 0x123480F0 (no 0xFFFF80F0)
    la $a0, lbl_zex
    jal print_pair

    # 10) lui con bit 15 = 1, e intento de escritura en $zero
    lui $s0, 0x80AB            # 0x80AB0000
    addi $zero, $zero, 99      # debe ignorarse
    ori  $zero, $zero, 0x1234  # debe ignorarse
    move $s1, $zero            # debe seguir siendo 0x00000000
    la $a0, lbl_lui
    jal print_pair

    # Terminar (syscall 10)
    li $v0, 10
    syscall

# Imprime: <etiqueta><$s0 en hex> <$s1 en hex>\n
print_pair:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal print_str
    move $a0, $s0
    jal print_hex
    li $a0, 32                 # espacio ' '
    li $v0, 11
    syscall
    move $a0, $s1
    jal print_hex
    li $a0, 10                 # salto de linea '\n'
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
    addi $a0, $t7, 48          # '0'..'9'
    j ph_out
ph_let:
    addi $a0, $t7, 55          # 'A'..'F'
ph_out:
    li $v0, 11
    syscall
    sll $t8, $t8, 4
    addi $t9, $t9, -1
    bne $t9, $zero, ph_loop
    jr $ra