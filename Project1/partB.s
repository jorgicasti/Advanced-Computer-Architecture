.text 0x00400000        # Inicio del código
.globl main

main:
    # --- Inicialización ---
    la   $t0, N           
    lw   $s0, 0($t0)      # $s0 = N (16)
    li   $s1, 1           # i = 1

loop_i:
    # --- Condición del bucle externo (i) ---
    # Comprobamos si i < N
    slt  $t0, $s1, $s0    
    beq  $t0, $zero, end  
    li   $s2, 1           # [DELAY SLOT LLENO]: Inicializamos j=1 AQUI. 
                          # Se ejecuta mientras el procesador decide si salta o no.
                          # Hemos borrado el NOP anterior.

loop_j:
    # --- Condición del bucle interno (j) ---
    # Comprobamos si j < N
    slt  $t0, $s2, $s0    
    beq  $t0, $zero, next_i 
    nop                   # [NOTA]: Aquí dejamos el NOP porque si saltamos, 
                          # no hay instrucción útil segura que poner sin cambiar mucho tu lógica.
                          # Pero los saltos importantes (loops) están optimizados abajo.

    # --- Cálculo de la Dirección de Memoria (Offset) ---
    sll  $t0, $s1, 6      # i * 64
    sll  $t1, $s2, 2      # j * 4
    add  $t2, $t0, $t1    # Offset Total

    # --- Carga de datos (Matrices A, B, C) ---
    la   $t3, A           
    add  $t3, $t3, $t2    
    lw   $t4, 0($t3)      # $t4 = A[i][j]

    la   $t3, B           
    add  $t3, $t3, $t2    
    lw   $t5, 0($t3)      # $t5 = B[i][j]

    la   $t3, C           
    add  $t3, $t3, $t2    
    lw   $t6, 0($t3)      # $t6 = C[i][j]

    # --- Lógica de MAX ---
    add  $t9, $t4, $zero  # MAX = A
    
    # Comparar MAX con B
    slt  $t7, $t9, $t5    # ¿MAX < B?
    beq  $t7, $zero, check_c
    nop                   # NOP necesario por estructura IF/ELSE
    add  $t9, $t5, $zero  # MAX = B
    
check_c:
    # Comparar MAX con C
    slt  $t7, $t9, $t6    # ¿MAX < C?
    beq  $t7, $zero, save_res
    nop                   # NOP necesario
    add  $t9, $t6, $zero  # MAX = C

save_res:
    # Guardar MAX
    la   $t3, MAX         
    add  $t3, $t3, $t2    
    sw   $t9, 0($t3)      

    # --- Lógica de MIN ---
    add  $t8, $t4, $zero  # MIN = A
    
    # Comparar B con MIN
    slt  $t7, $t5, $t8    # ¿B < MIN?
    beq  $t7, $zero, check_min_c
    nop                   # NOP necesario
    add  $t8, $t5, $zero  # MIN = B
    
check_min_c:
    # Comparar C con MIN
    slt  $t7, $t6, $t8    # ¿C < MIN?
    beq  $t7, $zero, save_min
    nop                   # NOP necesario
    add  $t8, $t6, $zero  # MIN = C

save_min:
    # Guardar MIN
    la   $t3, MIN         
    add  $t3, $t3, $t2    
    sw   $t8, 0($t3)      

    # --- OPTIMIZACIÓN DELAY SLOT (Bucle J) ---
    # En tu código original aquí tenías: addi, j, nop.
    # Ahora ponemos el addi DESPUÉS del j.
    
    j    loop_j           # Salta al inicio
    addi $s2, $s2, 1      # [DELAY SLOT LLENO]: j++ se ejecuta MIENTRAS salta.
                          # ¡Ahorramos 1 ciclo por cada casilla de la matriz!

next_i:
    # --- OPTIMIZACIÓN DELAY SLOT (Bucle I) ---
    # Igual que arriba: movemos el i++ al hueco del salto.
    
    j    loop_i           # Salta al inicio externo
    addi $s1, $s1, 1      # [DELAY SLOT LLENO]: i++ se ejecuta MIENTRAS salta.

end:
    li   $v0, 10          
    syscall               

# --- DATOS ---
.data
N:      .word 16        
# NOTA: He puesto algunos valores de prueba en A y B para que veas que funciona.
# El resto (.space) estará a 0.
A:      .word 10, 20, 30, 40, 50, 60, 70, 80, 1, 2, 3, 4, 5, 6, 7, 8
        .space 960      
B:      .word 5, 25, 10, 100, 5, 5, 5, 5, 9, 9, 9, 9, 9, 9, 9, 9
        .space 960      
C:      .space 1024     
MAX:    .space 1024     
MIN:    .space 1024