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
    lw $s5, N                  # N = 16 (múltiplo de 4)
    
    li $t0, 1                  # i = 1

loop_i:
    # Pre-cálculo útil para el bucle
    mul $t2, $t0, $s5          # $t2 = i * N (reutilizable)
    
    # Branch con optimización
    bge $t0, $s5, end_program  # si i >= N, terminar
    addiu $t0, $t0, 1          # DELAY SLOT: i++ (para siguiente)
    
    # Ajustar i
    addiu $t0, $t0, -1         # i correcto para esta iteración
    
    li $t1, 1                  # j = 1

loop_j:
    # --- PRIMERA ITERACIÓN: procesar [i][j] ---
    # Calcular offset para j
    addu $t3, $t2, $t1         # $t3 = (i*N) + j
    sll $t4, $t3, 3            # $t4 = offset bytes para [i][j]
    
    # Cargar A[i][j], B[i][j], C[i][j] con reordenamiento
    addu $at, $s0, $t4
    ld $t5, 0($at)             # $t5 = A[i][j]
    
    addu $at, $s1, $t4
    ld $t6, 0($at)             # $t6 = B[i][j]
    
    addu $at, $s2, $t4
    ld $t7, 0($at)             # $t7 = C[i][j]
    
    # Preparar offset para j+1 MIENTRAS se calcula
    addiu $t3, $t3, 1          # $t3 = (i*N) + (j+1) - para siguiente
    sll $t9, $t3, 3            # $t9 = offset bytes para [i][j+1]
    
    # Calcular MAX para [i][j]
    move $t8, $t5              # max_temp = A[i][j]
    slt $at, $t8, $t6
    beq $at, $zero, max_skip_b1
    nop
    move $t8, $t6              # max_temp = B[i][j]
max_skip_b1:
    
    slt $at, $t8, $t7
    beq $at, $zero, max_skip_c1
    nop
    move $t8, $t7              # max_temp = C[i][j]
max_skip_c1:
    
    # Calcular MIN para [i][j]
    move $t3, $t5              # min_temp = A[i][j] (reusamos $t3)
    slt $at, $t6, $t3
    beq $at, $zero, min_skip_b1
    nop
    move $t3, $t6              # min_temp = B[i][j]
min_skip_b1:
    
    slt $at, $t7, $t3
    beq $at, $zero, min_skip_c1
    nop
    move $t3, $t7              # min_temp = C[i][j]
min_skip_c1:
    
    # Guardar resultados de [i][j]
    addu $at, $s3, $t4
    sd $t8, 0($at)             # MAX[i][j] = max_temp
    
    addu $at, $s4, $t4
    sd $t3, 0($at)             # MIN[i][j] = min_temp
    
    # --- SEGUNDA ITERACIÓN: procesar [i][j+1] ---
    # Cargar valores para [i][j+1]
    addu $at, $s0, $t9
    ld $t5, 0($at)             # A[i][j+1]
    
    addu $at, $s1, $t9
    ld $t6, 0($at)             # B[i][j+1]
    
    addu $at, $s2, $t9
    ld $t7, 0($at)             # C[i][j+1]
    
    # Calcular MAX para [i][j+1]
    move $t8, $t5              # max_temp = A[i][j+1]
    slt $at, $t8, $t6
    beq $at, $zero, max_skip_b2
    nop
    move $t8, $t6              # max_temp = B[i][j+1]
max_skip_b2:
    
    slt $at, $t8, $t7
    beq $at, $zero, max_skip_c2
    nop
    move $t8, $t7              # max_temp = C[i][j+1]
max_skip_c2:
    
    # Calcular MIN para [i][j+1]
    move $t3, $t5              # min_temp = A[i][j+1]
    slt $at, $t6, $t3
    beq $at, $zero, min_skip_b2
    nop
    move $t3, $t6              # min_temp = B[i][j+1]
min_skip_b2:
    
    slt $at, $t7, $t3
    beq $at, $zero, min_skip_c2
    nop
    move $t3, $t7              # min_temp = C[i][j+1]
min_skip_c2:
    
    # Guardar resultados de [i][j+1]
    addu $at, $s3, $t9
    sd $t8, 0($at)             # MAX[i][j+1] = max_temp
    
    addu $at, $s4, $t9
    sd $t3, 0($at)             # MIN[i][j+1] = min_temp
    
    # --- Incrementar j en 2 (UNROLLING) ---
    addiu $t1, $t1, 2          # j += 2
    
    # Preparar i*N para siguiente iteración mientras verificamos condición
    mul $t2, $t0, $s5          # Recalcular i*N (instrucción útil)
    blt $t1, $s5, loop_j       # si j < N, continuar
    nop                        # Delay slot necesario
    
    # Fin del bucle j, continuar con siguiente i
    j loop_i
    nop

end_program:
    j end_program
    nop