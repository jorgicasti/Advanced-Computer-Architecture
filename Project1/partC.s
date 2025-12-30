.text 0x00400000
.globl main

main:
    # --- Inicialización ---
    la   $t0, N           
    lw   $s0, 0($t0)      # $s0 = N (16)
    li   $s1, 1           # i = 1

loop_i:
    # --- Condición bucle externo ---
    slt  $t0, $s1, $s0    
    beq  $t0, $zero, end  
    li   $s2, 1           # j = 1 (Inicialización en Delay Slot)

loop_j:
    # --- Condición bucle interno (Unrolling) ---
    # Al ir de 2 en 2, aseguramos no pasarnos. N=16 es par, así que ok.
    slt  $t0, $s2, $s0    
    beq  $t0, $zero, next_i 
    nop                   

    # =========================================================
    # CÁLCULO DE DIRECCIONES (Para j y j+1)
    # =========================================================
    
    # --- Offset 1 (Posición j) ---
    sll  $t0, $s1, 6      # i * 64
    sll  $t1, $s2, 2      # j * 4
    add  $t2, $t0, $t1    # $t2 = Offset Elemento 1

    # --- Offset 2 (Posición j+1) ---
    addi $a3, $t2, 4      # $a3 = Offset Elemento 2 (Simplemente +4 bytes)

    # =========================================================
    # BLOQUE DE CARGAS MASIVAS (PIPELINE FILLING)
    # Cargamos TODO antes de usar nada para matar los Stalls
    # =========================================================

    # --- Cargar Elementos 1 (A[j], B[j], C[j]) ---
    la   $t3, A
    add  $t3, $t3, $t2
    lw   $t4, 0($t3)      # $t4 = A1

    la   $t3, B
    add  $t3, $t3, $t2
    lw   $t5, 0($t3)      # $t5 = B1

    la   $t3, C
    add  $t3, $t3, $t2
    lw   $t6, 0($t3)      # $t6 = C1

    # --- Cargar Elementos 2 (A[j+1], B[j+1], C[j+1]) ---
    # Usamos registros temporales extra ($s3, $s4, $s5) para guardar el segundo set
    # Mientras hacemos estas cargas, los datos de A1, B1, C1 están llegando.
    
    la   $t3, A
    add  $t3, $t3, $a3    # Usamos offset 2
    lw   $s3, 0($t3)      # $s3 = A2

    la   $t3, B
    add  $t3, $t3, $a3
    lw   $s4, 0($t3)      # $s4 = B2

    la   $t3, C
    add  $t3, $t3, $a3
    lw   $s5, 0($t3)      # $s5 = C2

    # =========================================================
    # PROCESAMIENTO ELEMENTO 1 (Sin Stalls)
    # =========================================================

    # --- MAX 1 ---
    add  $t9, $t4, $zero  # MAX1 = A1 (Aquí t4 YA está listo gracias a las cargas extra)
    
    slt  $t7, $t9, $t5    # ¿MAX1 < B1?
    beq  $t7, $zero, chk_c1
    nop
    add  $t9, $t5, $zero  # MAX1 = B1
chk_c1:
    slt  $t7, $t9, $t6    # ¿MAX1 < C1?
    beq  $t7, $zero, sv_max1
    nop
    add  $t9, $t6, $zero  # MAX1 = C1
sv_max1:
    la   $t3, MAX
    add  $t3, $t3, $t2
    sw   $t9, 0($t3)      # Guardar MAX1

    # --- MIN 1 ---
    add  $t8, $t4, $zero  # MIN1 = A1
    
    slt  $t7, $t5, $t8    # ¿B1 < MIN1?
    beq  $t7, $zero, chk_mc1
    nop
    add  $t8, $t5, $zero  # MIN1 = B1
chk_mc1:
    slt  $t7, $t6, $t8    # ¿C1 < MIN1?
    beq  $t7, $zero, sv_min1
    nop
    add  $t8, $t6, $zero  # MIN1 = C1
sv_min1:
    la   $t3, MIN
    add  $t3, $t3, $t2
    sw   $t8, 0($t3)      # Guardar MIN1

    # =========================================================
    # PROCESAMIENTO ELEMENTO 2 (Sin Stalls)
    # =========================================================

    # --- MAX 2 ---
    add  $t9, $s3, $zero  # MAX2 = A2
    
    slt  $t7, $t9, $s4    # ¿MAX2 < B2?
    beq  $t7, $zero, chk_c2
    nop
    add  $t9, $s4, $zero  # MAX2 = B2
chk_c2:
    slt  $t7, $t9, $s5    # ¿MAX2 < C2?
    beq  $t7, $zero, sv_max2
    nop
    add  $t9, $s5, $zero  # MAX2 = C2
sv_max2:
    la   $t3, MAX
    add  $t3, $t3, $a3    # Usamos offset 2
    sw   $t9, 0($t3)      # Guardar MAX2

    # --- MIN 2 ---
    add  $t8, $s3, $zero  # MIN2 = A2
    
    slt  $t7, $s4, $t8    # ¿B2 < MIN2?
    beq  $t7, $zero, chk_mc2
    nop
    add  $t8, $s4, $zero  # MIN2 = B2
chk_mc2:
    slt  $t7, $s5, $t8    # ¿C2 < MIN2?
    beq  $t7, $zero, sv_min2
    nop
    add  $t8, $s5, $zero  # MIN2 = C2
sv_min2:
    la   $t3, MIN
    add  $t3, $t3, $a3    # Usamos offset 2
    sw   $t8, 0($t3)      # Guardar MIN2

    # =========================================================
    # CONTROL DE BUCLE (Incremento x2)
    # =========================================================
    
    j    loop_j
    addi $s2, $s2, 2      # [UNROLLING]: Incrementamos j en 2.
                          # Procesamos 2 columnas por vuelta.

next_i:
    j    loop_i
    addi $s1, $s1, 1      # i++

end:
    li   $v0, 10
    syscall

# --- DATOS (Igual que antes) ---
.data
N:      .word 16
# Datos aleatorios para A y B
A:      .word 10, 20, 30, 40, 50, 60, 70, 80, 1, 2, 3, 4, 5, 6, 7, 8
        .space 960
B:      .word 5, 25, 10, 100, 5, 5, 5, 5, 9, 9, 9, 9, 9, 9, 9, 9
        .space 960
C:      .word 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2
        .space 960
MAX:    .space 1024
MIN:    .space 1024