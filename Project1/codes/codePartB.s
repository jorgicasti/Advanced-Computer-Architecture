#PART B

.text 0x00400000        # Dirección de memoria donde arranca el programa.
.globl main             # Etiqueta global necesaria para el simulador.

main:
    # --- Inicialización de Variables ---
    la   $t0, N           # Busca dónde está la variable N en el almacén.
    lw   $s0, 0($t0)      # Lee el valor de N (16) y lo guarda en $s0.
    li   $s1, 1           # Pone el contador 'i' en 1 para empezar.

loop_i:
    # --- Comprobación del Bucle Externo (Fila) ---
    slt  $t0, $s1, $s0    # ¿Es i (1) menor que N (16)? (1=Sí, 0=No).
    beq  $t0, $zero, end  # Si es 0 (falso), salta al final del programa.
    
    # [OPTIMIZACIÓN DELAY SLOT]: Relleno útil
    li   $s2, 1           # Mientras decide si salta, ponemos j = 1.
                          # Así ahorramos hacerlo antes.

loop_j:
    # --- Comprobación del Bucle Interno (Columna) ---
    slt  $t0, $s2, $s0    # ¿Es j menor que N?
    beq  $t0, $zero, next_i # Si es falso (j llegó al final), vete a la siguiente fila.
    nop                   # [PAUSA]: Aquí dejamos el NOP porque es peligroso poner algo.

    # --- Matemáticas para saber la posición en memoria ---
    sll  $t0, $s1, 6      # Calcula fila: i * 64 (salto de 6 bits).
    sll  $t1, $s2, 2      # Calcula columna: j * 4 (salto de 2 bits).
    add  $t2, $t0, $t1    # Suma todo: $t2 es la dirección exacta del dato.

    # --- Cargar Dato de Matriz A ---
    la   $t3, A           # Apunta al inicio de la matriz A.
    add  $t3, $t3, $t2    # Camina hasta la posición [i][j].
    lw   $t4, 0($t3)      # Carga el valor de A en $t4.

    # --- Cargar Dato de Matriz B ---
    la   $t3, B           # Apunta al inicio de la matriz B.
    add  $t3, $t3, $t2    # Camina hasta la posición [i][j].
    lw   $t5, 0($t3)      # Carga el valor de B en $t5.

    # --- Cargar Dato de Matriz C ---
    la   $t3, C           # Apunta al inicio de la matriz C.
    add  $t3, $t3, $t2    # Camina hasta la posición [i][j].
    lw   $t6, 0($t3)      # Carga el valor de C en $t6.

    # --- Lógica para encontrar el MÁXIMO (MAX) ---
    add  $t9, $t4, $zero  # Suponemos que A es el mayor por ahora.
    
    # ¿Es B mayor que el MAX actual?
    slt  $t7, $t9, $t5    # Compara: ¿MAX < B?
    beq  $t7, $zero, check_c # Si NO es menor, salta a mirar la C.
    nop                   # [PAUSA]: Necesaria para no romper la lógica del IF.
    add  $t9, $t5, $zero  # Si era menor, actualizamos: MAX ahora es B.
    
check_c:
    # ¿Es C mayor que el MAX actual?
    slt  $t7, $t9, $t6    # Compara: ¿MAX < C?
    beq  $t7, $zero, save_res # Si NO es menor, ya terminamos. Salta a guardar.
    nop                   # [PAUSA]: Necesaria.
    add  $t9, $t6, $zero  # Si era menor, actualizamos: MAX ahora es C.

save_res:
    # Guardar el resultado MAX
    la   $t3, MAX         # Busca dónde guardar en la matriz MAX.
    add  $t3, $t3, $t2    # Va a la posición correcta.
    sw   $t9, 0($t3)      # Escribe el valor final en memoria.

    # --- Lógica para encontrar el MÍNIMO (MIN) ---
    add  $t8, $t4, $zero  # Suponemos que A es el menor por ahora.
    
    # ¿Es B menor que el MIN actual?
    slt  $t7, $t5, $t8    # Compara: ¿B < MIN?
    beq  $t7, $zero, check_min_c # Si NO es menor, salta a mirar la C.
    nop                   # [PAUSA]: Necesaria.
    add  $t8, $t5, $zero  # Si era menor, actualizamos: MIN ahora es B.
    
check_min_c:
    # ¿Es C menor que el MIN actual?
    slt  $t7, $t6, $t8    # Compara: ¿C < MIN?
    beq  $t7, $zero, save_min # Si NO es menor, ya terminamos.
    nop                   # [PAUSA]: Necesaria.
    add  $t8, $t6, $zero  # Si era menor, actualizamos: MIN ahora es C.

save_min:
    # Guardar el resultado MIN
    la   $t3, MIN         # Busca dónde guardar en la matriz MIN.
    add  $t3, $t3, $t2    # Va a la posición correcta.
    sw   $t8, 0($t3)      # Escribe el valor final en memoria.

    # --- Fin del Bucle J (Optimizado) ---
    j    loop_j           # Vuelve arriba para la siguiente columna.
    
    # [OPTIMIZACIÓN DELAY SLOT]:
    addi $s2, $s2, 1      # ¡TRUCO!: Sumamos 1 a 'j' MIENTRAS el procesador salta.
                          # Antes esto estaba arriba y después había un NOP.

next_i:
    # --- Fin del Bucle I (Optimizado) ---
    j    loop_i           # Vuelve arriba para la siguiente fila.
    
    # [OPTIMIZACIÓN DELAY SLOT]:
    addi $s1, $s1, 1      # ¡TRUCO!: Sumamos 1 a 'i' MIENTRAS el procesador salta.

end:
    # --- Terminar Programa ---
    li   $v0, 10          # Código para decir "Fin del programa".
    syscall               # Ejecutar el fin.

# --- SECCIÓN DE DATOS (Valores de prueba) ---
.data
N:      .word 16        # Tamaño de la matriz (16x16).

# Matriz A con algunos valores reales para probar que funciona
A:      .word 10, 20, 30, 40, 50, 60, 70, 80, 1, 2, 3, 4, 5, 6, 7, 8
        .space 960      # El resto vacío.

# Matriz B con valores diferentes para comparar
B:      .word 5, 25, 10, 100, 5, 5, 5, 5, 9, 9, 9, 9, 9, 9, 9, 9
        .space 960      # El resto vacío.

C:      .space 1024     # Matriz C vacía.
MAX:    .space 1024     # Resultado MAX.
MIN:    .space 1024     # Resultado MIN.