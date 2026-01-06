#PART A
.text 0x00400000        # Indica al ensamblador que el código comienza en la dirección 0x00400000
.globl main             # Declara la etiqueta 'main' como global para que el simulador sepa dónde empezar

main:
    # --- Inicialización ---
    la   $t0, N           # Carga la dirección de memoria de la variable N en el registro temporal $t0
    lw   $s0, 0($t0)      # Lee el valor de N (16) desde la memoria y lo guarda en $s0
    li   $s1, 1           # Inicializa el contador del bucle externo 'i' en 1 ($s1 = 1)

loop_i:
    # --- Condición del bucle externo (i) ---
    # Comprobamos si i < N.
    slt  $t0, $s1, $s0    # Si $s1 (i) < $s0 (N), entonces $t0 = 1. Si no, $t0 = 0.
    beq  $t0, $zero, end  # Si $t0 es 0 (condición falsa, i >= N), salta a la etiqueta 'end'.
    nop                   # Delay Slot: Instrucción vacía necesaria mientras se decide el salto.

    li   $s2, 1           # Inicializa el contador del bucle interno 'j' en 1 ($s2 = 1) cada vez que cambia 'i'. y sl
loop_j:
    # --- Condición del bucle interno (j) ---
    # Comprobamos si j < N.
    slt  $t0, $s2, $s0    # Si $s2 (j) < $s0 (N), entonces $t0 = 1.
    beq  $t0, $zero, next_i # Si j >= N, termina el bucle interno y salta a 'next_i' (incrementar i).
    nop                   # Delay Slot: Instrucción vacía obligatoria.

    # --- Cálculo de la Dirección de Memoria (Offset) ---
    # Queremos acceder a la posición [i][j]. La fórmula es: DirecciónBase + (i * TamañoFila) + (j * TamañoPalabra)
    # TamañoFila = 16 elementos * 4 bytes = 64 bytes.
    
    sll  $t0, $s1, 6      # $t0 = i * 64. (Shift left logical 6 bits equivale a multiplicar por 2^6).
    sll  $t1, $s2, 2      # $t1 = j * 4.  (Shift left logical 2 bits equivale a multiplicar por 2^2).
    add  $t2, $t0, $t1    # $t2 = Offset Total en bytes desde el inicio del array.

    # --- Carga de datos (Matrices A, B, C) ---
    la   $t3, A           # Carga la dirección base (inicio) de la matriz A en $t3.
    add  $t3, $t3, $t2    # Suma la base de A + el offset calculado ($t2) para apuntar a A[i][j].
    lw   $t4, 0($t3)      # Carga el valor de A[i][j] desde la memoria al registro $t4.

    la   $t3, B           # Carga la dirección base de la matriz B.
    add  $t3, $t3, $t2    # Suma el offset ($t2).
    lw   $t5, 0($t3)      # Carga el valor de B[i][j] en el registro $t5.

    la   $t3, C           # Carga la dirección base de la matriz C.
    add  $t3, $t3, $t2    # Suma el offset ($t2).
    lw   $t6, 0($t3)      # Carga el valor de C[i][j] en el registro $t6.

    # --- Lógica de MAX (Cálculo del Máximo) ---
    # Algoritmo: MAX = A; if (B > MAX) MAX = B; if (C > MAX) MAX = C;
    
    add  $t9, $t4, $zero  # Inicializamos temporalmente MAX ($t9) con el valor de A ($t4).
    
    # Comparar MAX actual con B
    slt  $t7, $t9, $t5    # Compara: ¿Es MAX ($t9) < B ($t5)? Si sí, pone $t7 a 1.
    beq  $t7, $zero, check_c # Si $t7 es 0 (MAX >= B), salta a comprobar C sin cambiar nada.
    nop                   # Delay Slot.
    add  $t9, $t5, $zero  # Si no saltó (B era mayor), actualizamos MAX = B.
    
check_c:
    # Comparar MAX actual con C
    slt  $t7, $t9, $t6    # Compara: ¿Es MAX ($t9) < C ($t6)?
    beq  $t7, $zero, save_res # Si $t7 es 0, ya tenemos el máximo. Saltamos a guardar.
    nop                   # Delay Slot.
    add  $t9, $t6, $zero  # Si C era mayor, actualizamos MAX = C.

save_res:
    # Guardar el resultado MAX en memoria
    la   $t3, MAX         # Carga la dirección base de la matriz de resultados MAX.
    add  $t3, $t3, $t2    # Suma el offset para ir a la posición correcta MAX[i][j].
    sw   $t9, 0($t3)      # Guarda el valor final de MAX ($t9) en la memoria.

    # --- Lógica de MIN (Cálculo del Mínimo) ---
    # Algoritmo: MIN = A; if (B < MIN) MIN = B; if (C < MIN) MIN = C;

    add  $t8, $t4, $zero  # Inicializamos temporalmente MIN ($t8) con el valor de A.
    
    # Comparar B con MIN actual
    slt  $t7, $t5, $t8    # Compara: ¿Es B ($t5) < MIN ($t8)? Si sí, $t7 = 1.
    beq  $t7, $zero, check_min_c # Si $t7 es 0 (B >= MIN), saltamos.
    nop                   # Delay Slot.
    add  $t8, $t5, $zero  # Si B era menor, actualizamos MIN = B.
    
check_min_c:
    # Comparar C con MIN actual
    slt  $t7, $t6, $t8    # Compara: ¿Es C ($t6) < MIN ($t8)?
    beq  $t7, $zero, save_min # Si C no es menor, saltamos a guardar.
    nop                   # Delay Slot.
    add  $t8, $t6, $zero  # Si C era menor, actualizamos MIN = C.

save_min:
    # Guardar el resultado MIN en memoria
    la   $t3, MIN         # Carga la dirección base de la matriz MIN.
    add  $t3, $t3, $t2    # Suma el offset.
    sw   $t8, 0($t3)      # Guarda el valor final de MIN ($t8) en la memoria.

    # --- Control de Bucles ---
    addi $s2, $s2, 1      # Incrementa el contador j en 1 (j++).
    j    loop_j           # Salta incondicionalmente al inicio del bucle interno.
    nop                   # Delay Slot.

next_i:
    addi $s1, $s1, 1      # Incrementa el contador i en 1 (i++).
    j    loop_i           # Salta incondicionalmente al inicio del bucle externo.
    nop                   # Delay Slot.

end:
    # --- Finalización del Programa ---
    li   $v0, 10          # Carga el código de servicio 10 (exit) en $v0.
    syscall               # Llama al sistema para terminar la ejecución limpiamente.

# --- SECCIÓN DE DATOS ---
# Se coloca al final para evitar que el procesador intente ejecutar estos datos como instrucciones al inicio.
.data
N:      .word 16        # Variable N = 16 (Tamaño de la matriz).
A:      .space 1024     # Espacio reservado para Matriz A (16x16 palabras de 4 bytes).
B:      .space 1024     # Espacio reservado para Matriz B.
C:      .space 1024     # Espacio reservado para Matriz C.
MAX:    .space 1024     # Espacio reservado para la matriz de salida MAX.
MIN:    .space 1024     # Espacio reservado para la matriz de salida MIN.
