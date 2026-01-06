# CODE C

.text 0x00400000        # Inicio del código
.globl main

main:
    # --- Inicialización ---
    la   $t0, N           
    lw   $s0, 0($t0)      # $s0 = N (16)
    li   $s1, 1           # i = 1

loop_i:
    # --- Bucle Externo ---
    slt  $t0, $s1, $s0    # ¿i < N?
    beq  $t0, $zero, end  # Si no, fin.
    # [DELAY SLOT]:
    li   $s2, 1           # Inicializamos j = 1 aquí.

loop_j:
    # =========================================================
    # CHEQUEO DE SEGURIDAD: ¿Quedan al menos 2 elementos?
    # =========================================================
    addi $t0, $s2, 1      # Miramos el siguiente índice (j+1).
    slt  $t1, $t0, $s0    # ¿(j+1) < N?
    beq  $t1, $zero, procesar_ultimo # Si no caben 2, saltamos al bloque simple.
    nop                   # Pause de seguridad.

    # =========================================================
    # BLOQUE DESENROSCADO (2 ELEMENTOS A LA VEZ)
    # =========================================================
    
    # 1. Cálculo de direcciones (Offsets)
    sll  $t0, $s1, 6      # Fila i (i * 64)
    sll  $t1, $s2, 2      # Columna j (j * 4)
    add  $t2, $t0, $t1    # $t2 = Dirección del Elemento 1
    addi $a3, $t2, 4      # $a3 = Dirección del Elemento 2 (Elemento 1 + 4 bytes)

    # 2. [OPTIMIZACIÓN CLAVE]: Cargas Agrupadas (Instruction Scheduling)
    # Cargamos TODO de golpe para dar tiempo a que lleguen los datos.
    
    # --- Cargar Grupo 1 ---
    la   $t3, A
    add  $t3, $t3, $t2
    lw   $t4, 0($t3)      # Pide A1... (tarda en llegar)

    la   $t3, B
    add  $t3, $t3, $t2
    lw   $t5, 0($t3)      # Pide B1...

    la   $t3, C
    add  $t3, $t3, $t2
    lw   $t6, 0($t3)      # Pide C1...

    # --- Cargar Grupo 2 ---
    # Mientras pedimos estos, los del Grupo 1 están llegando.
    la   $t3, A
    add  $t3, $t3, $a3
    lw   $s3, 0($t3)      # Pide A2...

    la   $t3, B
    add  $t3, $t3, $a3
    lw   $s4, 0($t3)      # Pide B2...

    la   $t3, C
    add  $t3, $t3, $a3
    lw   $s5, 0($t3)      # Pide C2...

    # 3. Procesamiento (Ahora los datos ya están listos, 0 Stalls)
    
    # --- PROCESAR ELEMENTO 1 (MAX) ---
    add  $t9, $t4, $zero  # MAX1 = A1
    
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

    # --- PROCESAR ELEMENTO 1 (MIN) ---
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

    # --- PROCESAR ELEMENTO 2 (MAX) ---
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
    add  $t3, $t3, $a3
    sw   $t9, 0($t3)      # Guardar MAX2

    # --- PROCESAR ELEMENTO 2 (MIN) ---
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
    add  $t3, $t3, $a3
    sw   $t8, 0($t3)      # Guardar MIN2

    # 4. Control del Bucle (Salto de 2 en 2)
    j    loop_j
    addi $s2, $s2, 2      # [DELAY SLOT]: j += 2 ¡Procesamos doble!

procesar_ultimo:
    # =========================================================
    # BLOQUE DE RESCATE (Para cuando N es impar)
    # =========================================================
    slt  $t0, $s2, $s0    # ¿Queda 1 elemento suelto?
    beq  $t0, $zero, next_i
    nop

    # (Lógica estándar para 1 solo elemento...)
    # ... Cálculo Offset ...
    sll  $t0, $s1, 6
    sll  $t1, $s2, 2
    add  $t2, $t0, $t1

    # ... Cargas ...
    la   $t3, A
    add  $t3, $t3, $t2
    lw   $t4, 0($t3)
    la   $t3, B
    add  $t3, $t3, $t2
    lw   $t5, 0($t3)
    la   $t3, C
    add  $t3, $t3, $t2
    lw   $t6, 0($t3)

    # ... MAX y MIN (versión reducida) ...
    # (Omitido por brevedad en la explicación, es igual al bloque A)
    # ... Lógica MAX ...
    add  $t9, $t4, $zero
    slt  $t7, $t9, $t5
    beq  $t7, $zero, chk_c_s
    nop
    add  $t9, $t5, $zero
chk_c_s:
    slt  $t7, $t9, $t6
    beq  $t7, $zero, sv_max_s
    nop
    add  $t9, $t6, $zero
sv_max_s:
    la   $t3, MAX
    add  $t3, $t3, $t2
    sw   $t9, 0($t3)

    # ... Lógica MIN ...
    add  $t8, $t4, $zero
    slt  $t7, $t5, $t8
    beq  $t7, $zero, chk_mc_s
    nop
    add  $t8, $t5, $zero
chk_mc_s:
    slt  $t7, $t6, $t8
    beq  $t7, $zero, sv_min_s
    nop
    add  $t8, $t6, $zero
sv_min_s:
    la   $t3, MIN
    add  $t3, $t3, $t2
    sw   $t8, 0($t3)

    addi $s2, $s2, 1      # Incremento simple.

next_i:
    j    loop_i           # Siguiente fila.
    addi $s1, $s1, 1      # i++ en Delay Slot.

end:
    li   $v0, 10
    syscall

# --- DATOS (Igual que Parte B) ---
.data
N:      .word 16
A:      .word 10, 20, 30, 40, 50, 60, 70, 80, 1, 2, 3, 4, 5, 6, 7, 8
        .space 960
B:      .word 5, 25, 10, 100, 5, 5, 5, 5, 9, 9, 9, 9, 9, 9, 9, 9
        .space 960
C:      .word 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2
        .space 960
MAX:    .space 1024
MIN:    .space 1024
