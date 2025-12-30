.data
A:      .space 2048
B:      .space 2048
C:      .space 2048
MAX:    .space 2048
MIN:    .space 2048
N:      .word  16

.text
.globl main

main:
    la $s0, A
    la $s1, B
    la $s2, C
    la $s3, MAX
    la $s4, MIN
    lw $s5, N
    
    li $t0, 1               # i = 1

loop_i:
    # CALCULAR i*N ANTES del branch (instrucción útil en pipeline)
    mul $t2, $t0, $s5       # $t2 = i * N (calculamos ANTES)
    
    # Branch con delay slot ÚTIL: incrementamos i para siguiente iteración
    bge $t0, $s5, end_program  # si i >= N, terminar
    addiu $t0, $t0, 1          # DELAY SLOT ÚTIL: i++ (para próxima)
    
    # Ajustar porque ya incrementamos i en el delay slot
    addiu $t0, $t0, -1         # i correcto para ESTA iteración
    
    li $t1, 1                  # j = 1

loop_j:
    # CALCULAR (i*N)+j ANTES del branch
    addu $t3, $t2, $t1        # $t3 = (i*N) + j (instrucción útil)
    
    # Branch con delay slot ÚTIL: incrementamos j
    bge $t1, $s5, end_loop_i  # si j >= N, salir
    addiu $t1, $t1, 1          # DELAY SLOT ÚTIL: j++ (para próxima)
    
    # Ajustar j
    addiu $t1, $t1, -1         # j correcto para ESTA iteración
    
    # --- Continuar con cálculo de direcciones ---
    sll $t4, $t3, 3           # desplazamiento en bytes (×8)
    
    # Cargar valores (con alguna optimización)
    addu $at, $s0, $t4
    ld $t5, 0($at)            # A[i][j]
    
    addu $at, $s1, $t4
    ld $t6, 0($at)            # B[i][j]
    
    addu $at, $s2, $t4
    ld $t7, 0($at)            # C[i][j]
    # Nota: Podríamos preparar siguiente offset aquí si hubiera más optimización
    
    # --- Cálculo de MAX (con nops que no se pueden eliminar fácilmente) ---
    move $t8, $t5
    slt $at, $t8, $t6
    beq $at, $zero, max_skip_b
    nop                       # Este nop es difícil de eliminar
    move $t8, $t6
max_skip_b:
    
    slt $at, $t8, $t7
    beq $at, $zero, max_skip_c
    nop                       # Este nop es difícil de eliminar
    move $t8, $t7
max_skip_c:
    
    # --- Cálculo de MIN ---
    move $t9, $t5
    slt $at, $t6, $t9
    beq $at, $zero, min_skip_b
    nop                       # Este nop es difícil de eliminar
    move $t9, $t6
min_skip_b:
    
    slt $at, $t7, $t9
    beq $at, $zero, min_skip_c
    nop                       # Este nop es difícil de eliminar
    move $t9, $t7
min_skip_c:
    
    # --- Guardar resultados ---
    addu $at, $s3, $t4
    sd $t8, 0($at)            # guardar MAX
    
    addu $at, $s4, $t4
    sd $t9, 0($at)            # guardar MIN
    
    # Saltar al inicio del bucle j
    j loop_j
    nop                       # Necesario para jump

end_loop_i:
    # Volver al bucle i
    j loop_i
    nop                       # Necesario para jump

end_program:
    j end_program
    nop