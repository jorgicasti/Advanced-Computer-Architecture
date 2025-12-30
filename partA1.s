.data
# Matrices 16x16 de 64-bit (8 bytes por elemento)
# Total: 16*16*8 = 2048 bytes por matriz
A:      .space 2048
B:      .space 2048
C:      .space 2048
MAX:    .space 2048
MIN:    .space 2048
N:      .word  16          # N = 16

.text
.globl main

main:
    # Cargar direcciones base de matrices
    la $s0, A              # $s0 = dirección de A
    la $s1, B              # $s1 = dirección de B  
    la $s2, C              # $s2 = dirección de C
    la $s3, MAX            # $s3 = dirección de MAX
    la $s4, MIN            # $s4 = dirección de MIN
    lw $s5, N              # $s5 = N = 16
    
    li $t0, 1              # i = 1 (empieza en 1, no en 0)

loop_i:
    # Condición: i < N ? (si i >= N, terminar)
    bge $t0, $s5, end_program
    nop                     # DELAY SLOT (nop - Código A)
    
    li $t1, 1               # j = 1

loop_j:
    # Condición: j < N ? (si j >= N, siguiente i)
    bge $t1, $s5, end_loop_i
    nop                     # DELAY SLOT (nop - Código A)
    
    # --- Calcular dirección de A[i][j] ---
    # Fórmula: dirección = base + ((i*N + j) * 8)
    mul $t2, $t0, $s5       # $t2 = i * N
    addu $t2, $t2, $t1      # $t2 = i*N + j
    sll $t3, $t2, 3         # $t3 = (i*N + j) * 8 (desplazamiento bytes)
    
    # --- Cargar A[i][j], B[i][j], C[i][j] ---
    addu $t4, $s0, $t3      # $t4 = dirección de A[i][j]
    ld $t5, 0($t4)          # $t5 = valor de A[i][j] (64-bit)
    
    addu $t4, $s1, $t3      # $t4 = dirección de B[i][j]
    ld $t6, 0($t4)          # $t6 = valor de B[i][j]
    
    addu $t4, $s2, $t3      # $t4 = dirección de C[i][j]
    ld $t7, 0($t4)          # $t7 = valor de C[i][j]
    
    # --- Calcular MAX(A,B,C) ---
    move $t8, $t5           # max = A[i][j]
    
    # Comparar con B
    slt $at, $t8, $t6       # ¿max < B?
    beq $at, $zero, skip_max_B
    nop
    move $t8, $t6           # si B > max, max = B
skip_max_B:
    
    # Comparar con C
    slt $at, $t8, $t7       # ¿max < C?
    beq $at, $zero, skip_max_C
    nop
    move $t8, $t7           # si C > max, max = C
skip_max_C:
    
    # --- Calcular MIN(A,B,C) ---
    move $t9, $t5           # min = A[i][j]
    
    # Comparar con B
    slt $at, $t6, $t9       # ¿B < min?
    beq $at, $zero, skip_min_B
    nop
    move $t9, $t6           # si B < min, min = B
skip_min_B:
    
    # Comparar con C
    slt $at, $t7, $t9       # ¿C < min?
    beq $at, $zero, skip_min_C
    nop
    move $t9, $t7           # si C < min, min = C
skip_min_C:
    
    # --- Guardar resultados en MAX[i][j] y MIN[i][j] ---
    addu $t4, $s3, $t3      # $t4 = dirección de MAX[i][j]
    sd $t8, 0($t4)          # almacenar MAX (64-bit)
    
    addu $t4, $s4, $t3      # $t4 = dirección de MIN[i][j]
    sd $t9, 0($t4)          # almacenar MIN (64-bit)
    
    # --- Incrementar j y continuar bucle interno ---
    addiu $t1, $t1, 1       # j = j + 1
    j loop_j
    nop                     # DELAY SLOT (nop - Código A)

end_loop_i:
    # --- Incrementar i y continuar bucle externo ---
    addiu $t0, $t0, 1       # i = i + 1
    j loop_i
    nop                     # DELAY SLOT (nop - Código A)

end_program:
    # Fin del programa (bucle infinito)
    j end_program
    nop