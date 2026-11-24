# Algoritmo de prueba: Busqueda binaria iterativa en arreglo ordenado
# Cobertura adicional Tabla 3:
# - lw, add, addi, sll, srl, slt, beq, bne, j, jal, jr,
#   li/move (addiu/addu), syscall 11 (imprimir) y 10 (terminar)

.data
arr:    .word -15, -3, 0, 4, 12, 27, 45, 99
lbl_1:  .asciiz "BS12:"
lbl_2:  .asciiz "BSN15:"
lbl_3:  .asciiz "BS20:"

.text
.globl main
main:
    # 1) Buscar 12 -> esta en el indice 4 (0x00000004)
    la $a0, arr                # direccion base del arreglo
    li $a1, 8                  # cantidad de elementos
    li $a2, 12                 # elemento a buscar
    jal bsearch_iter
    move $s0, $v0
    la $a0, lbl_1
    jal print_res

    # 2) Buscar -15 -> esta en el indice 0 (0x00000000)
    la $a0, arr
    li $a1, 8
    li $a2, -15
    jal bsearch_iter
    move $s0, $v0
    la $a0, lbl_2
    jal print_res

    # 3) Buscar 20 -> no existe, devuelve -1 (0xFFFFFFFF)
    la $a0, arr
    li $a1, 8
    li $a2, 20
    jal bsearch_iter
    move $s0, $v0
    la $a0, lbl_3
    jal print_res

    # Terminar el programa (syscall 10)
    li $v0, 10
    syscall

# bsearch_iter($a0=base, $a1=tamano, $a2=objetivo) -> $v0=indice o -1
bsearch_iter:
    li   $t0, 0                # low = 0
    addi $t1, $a1, -1          # high = tamano - 1

bs_loop:
    slt  $t5, $t1, $t0         # high < low ?
    bne  $t5, $zero, bs_not_found

    add  $t2, $t0, $t1         # low + high
    srl  $t2, $t2, 1           # mid = (low + high) / 2
    sll  $t3, $t2, 2           # desplazamiento en bytes = mid * 4
    add  $t3, $a0, $t3         # direccion de arr[mid]
    lw   $t4, 0($t3)           # val = arr[mid]

    beq  $t4, $a2, bs_found    # si arr[mid] == objetivo -> encontrado

    slt  $t5, $a2, $t4         # objetivo < arr[mid] ?
    beq  $t5, $zero, bs_right  # si no, buscar en la mitad derecha

    addi $t1, $t2, -1          # high = mid - 1 (mitad izquierda)
    j    bs_loop

bs_right:
    addi $t0, $t2, 1           # low = mid + 1 (mitad derecha)
    j    bs_loop

bs_found:
    move $v0, $t2              # devolver el indice encontrado
    jr   $ra

bs_not_found:
    li   $v0, -1               # devolver -1 si no estaba
    jr   $ra

# --- Funciones auxiliares de impresion (usando solo syscall 11) ---
print_res:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    jal  print_str
    move $a0, $s0
    jal  print_hex
    li   $a0, 10               # salto de linea '\n'
    li   $v0, 11
    syscall
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

print_str:
    move $t8, $a0
ps_loop:
    lbu  $a0, 0($t8)
    beq  $a0, $zero, ps_end
    li   $v0, 11
    syscall
    addi $t8, $t8, 1
    j    ps_loop
ps_end:
    jr   $ra

print_hex:
    move $t8, $a0
    li   $t9, 8
ph_loop:
    srl  $t7, $t8, 28
    slti $t6, $t7, 10
    beq  $t6, $zero, ph_let
    addi $a0, $t7, 48          # '0'..'9'
    j    ph_out
ph_let:
    addi $a0, $t7, 55          # 'A'..'F'
ph_out:
    li   $v0, 11
    syscall
    sll  $t8, $t8, 4
    addi $t9, $t9, -1
    bne  $t9, $zero, ph_loop
    jr   $ra