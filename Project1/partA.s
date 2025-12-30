.data
N:      .word 16
A:      .space 1024
B:      .space 1024
C:      .space 1024
MAX:    .space 1024
MIN:    .space 1024

.text 
.globl main
main:
    la   $t0, N
    lw   $s0, 0($t0)
    li   $s1, 1        # i = 1

loop_i:
    # Sustitución de: bge $s1, $s0, end
    slt  $t0, $s1, $s0    # $t0 = 1 si i < N
    beq  $t0, $zero, end  # Si $t0 == 0 (i >= N), saltar a end
    nop                   # Delay Slot 

    li   $s2, 1        # j = 1

loop_j:
    # Sustitución de: bge $s2, $s0, next_i
    slt  $t0, $s2, $s0    # $t0 = 1 si j < N
    beq  $t0, $zero, next_i
    nop                   # Delay Slot 

    # --- Cálculo de Offset ---
    sll  $t0, $s1, 6      # i * 64 (para N=16)
    sll  $t1, $s2, 2      # j * 4
    add  $t2, $t0, $t1    # Offset total

    # --- Carga de datos ---
    la   $t3, A
    add  $t3, $t3, $t2
    lw   $t4, 0($t3)      # A[i][j]

    la   $t3, B
    add  $t3, $t3, $t2
    lw   $t5, 0($t3)      # B[i][j]

    la   $t3, C
    add  $t3, $t3, $t2
    lw   $t6, 0($t3)      # C[i][j]

    # --- Lógica de MAX ---
    # Sustitución de move:
    add  $t9, $t4, $zero  # MAX = A
    
    # Comparar MAX con B (Sustitución de bge)
    slt  $t7, $t9, $t5    # $t7 = 1 si MAX < B
    beq  $t7, $zero, check_c # Si MAX >= B, saltar
    nop
    add  $t9, $t5, $zero  # MAX = B
    
check_c:
    slt  $t7, $t9, $t6    # $t7 = 1 si MAX < C
    beq  $t7, $zero, save_res
    nop
    add  $t9, $t6, $zero  # MAX = C

save_res:
    la   $t3, MAX
    add  $t3, $t3, $t2
    sw   $t9, 0($t3)

# --- Lógica de MIN ---
    add  $t8, $t4, $zero  # MIN = A (Asumimos A inicialmente)
    
    # Comparar MIN con B
    slt  $t7, $t5, $t8    # $t7 = 1 si B < MIN
    beq  $t7, $zero, check_min_c # Si B >= MIN, no hacemos nada
    nop
    add  $t8, $t5, $zero  # MIN = B
    
check_min_c:
    slt  $t7, $t6, $t8    # $t7 = 1 si C < MIN
    beq  $t7, $zero, save_min
    nop
    add  $t8, $t6, $zero  # MIN = C

save_min:
    la   $t3, MIN
    add  $t3, $t3, $t2
    sw   $t8, 0($t3)      # Guardar el resultado en la memoria

    # --- Control de Bucles ---
    addi $s2, $s2, 1
    j    loop_j
    nop

next_i:
    addi $s1, $s1, 1
    j    loop_i
    nop

end:
    # --- AQUÍ ESTÁ EL CÓDIGO DE FINALIZACIÓN (BREAK) ---
    li   $v0, 10      # Cargar el código 10 (exit) en el registro $v0
    syscall           # Llamada al sistema para terminar la ejecución