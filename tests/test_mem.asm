# Cobertura Tabla 3:
# - lw, sw: desplazamiento positivo (+4) y desplazamiento negativo (-4)
# - lb, lbu: byte con bit 7 = 1 en posiciones distintas (d[1:0] = 0, 1, 2, 3)
# - sb: en las 4 posiciones de una misma palabra (d[1:0] = 0, 1, 2, 3),
#       comprobando con lw que los otros bytes no cambiaron
# - syscall: servicios 11 (imprimir) y 10 (terminar)

.data
buf:        .word 0, 0, 0, 0
word_bytes: .word 0x8192A3B4
sb_target:  .word 0x11223344
lbl_lw:     .asciiz "LW:"
lbl_lb:     .asciiz "LB:"
lbl_lu:     .asciiz "LU:"
lbl_sb01:   .asciiz "SB01:"
lbl_sb23:   .asciiz "SB23:"

.text
.globl main
main:
    # 1) sw y lw con desplazamiento positivo (+4) y negativo (-4)
    la $s5, buf
    addi $s5, $s5, 8           # $s5 apunta al centro del buffer (buf[2])
    lui $t0, 0x1234
    ori $t0, $t0, 0x5678
    li  $t1, -55               # 0xFFFFFFC9
    sw  $t0, 4($s5)            # offset positivo
    sw  $t1, -4($s5)           # offset negativo
    lw  $s0, 4($s5)            # 0x12345678
    lw  $s1, -4($s5)           # 0xFFFFFFC9
    la  $a0, lbl_lw
    jal print_pair

    # 2) lb y lbu sobre bytes con bit 7 = 1 en distintas posiciones d[1:0]
    # En little-endian, 0x8192A3B4 tiene: [0]=B4, [1]=A3, [2]=92, [3]=81
    la  $s5, word_bytes
    lb  $s0, 0($s5)            # 0xFFFFFFB4 (d[1:0]=0)
    lb  $s1, 2($s5)            # 0xFFFFFF92 (d[1:0]=2)
    la  $a0, lbl_lb
    jal print_pair

    lbu $s0, 1($s5)            # 0x000000A3 (d[1:0]=1)
    lbu $s1, 3($s5)            # 0x00000081 (d[1:0]=3)
    la  $a0, lbl_lu
    jal print_pair

    # 3) sb en las 4 posiciones (0, 1, 2, 3) sobre 0x11223344 y chequeo con lw
    la  $s5, sb_target
    li  $t0, 0xAA
    sb  $t0, 0($s5)
    lw  $s0, 0($s5)            # 0x112233AA
    li  $t0, 0xBB
    sb  $t0, 1($s5)
    lw  $s1, 0($s5)            # 0x1122BBAA
    la  $a0, lbl_sb01
    jal print_pair

    li  $t0, 0xCC
    sb  $t0, 2($s5)
    lw  $s0, 0($s5)            # 0x11CCBBAA
    li  $t0, 0xDD
    sb  $t0, 3($s5)
    lw  $s1, 0($s5)            # 0xDDCCBBAA
    la  $a0, lbl_sb23
    jal print_pair

    li $v0, 10
    syscall

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