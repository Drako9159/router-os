# =====================================================================
# MIKROTIK ROUTEROS - BANCO DE PRUEBAS DE DEGRADACIÓN DE RED (AUDITORÍA)
# =====================================================================
# Estructura de nombres optimizada para RouterOS:
# [cat][A/B/C]-[mecanismo]-[nivel]-[descriptivo]
# =====================================================================

# ---------------------------------------------------------------------
# 1. CREACIÓN DE QUEUE TYPES POR CATEGORÍA
# ---------------------------------------------------------------------
/queue type

# =====================================================================
# CATEGORÍA A: RENDIMIENTO GENERAL (BUFFERBLOAT & DELAY LINEAL)
# Afecta a todo el tráfico por igual mediante buffers FIFO profundos.
# =====================================================================

# [A1. Leve / Latencia perceptible bajo carga]
add name="catA-gen-1-mild" kind=pfifo pfifo-limit=150

# [A2. Severo / Impacto notable en videollamadas]
add name="catA-gen-2-heavy" kind=bfifo bfifo-limit=2000000

# [A3. Pesadilla / Microcortes y timeouts]
add name="catA-gen-3-nightmare" kind=bfifo bfifo-limit=5000000

# [A4. Apocalíptico / Retraso masivo de minutos]
# (Nota: Llenar este buffer requiere limitar el target a <= 512k)
add name="catA-gen-4-apocalypse" kind=bfifo bfifo-limit=10000000


# =====================================================================
# CATEGORÍA B: DEGRADACIÓN POR CONEXIÓN (CONGESTIÓN PCQ POR PUERTOS)
# Clasifica y estrangula cada puerto/socket de forma independiente.
# Afecta principalmente la carga de páginas web y descargas concurrentes.
# =====================================================================

# [B1. PCQ Leve - Tránsito algo ralentizado]
add name="catB-pcq-1-light" kind=pcq pcq-classifier=dst-port,src-port pcq-limit=30 pcq-rate=1M

# [B2. PCQ Medio - Frustración controlada / Carga pesada]
add name="catB-pcq-2-moderate" kind=pcq pcq-classifier=dst-port,src-port pcq-limit=15 pcq-rate=512k

# [B3. PCQ Heavy - Lentitud extrema / Timeout parcial]
add name="catB-pcq-3-severe" kind=pcq pcq-classifier=dst-port,src-port pcq-limit=5 pcq-rate=128k


# =====================================================================
# CATEGORÍA C: TIEMPO REAL & GAMING (DEGRADACIÓN MEDIANTE ALGORITMO RED)
# Afecta el tráfico interactivo UDP de tamaño pequeño sin estrangular el
# ancho de banda general. Se usa RED de manera uniforme para modular la
# probabilidad y agresividad del descarte aleatorio de paquetes.
# =====================================================================

# [C1. Gaming Jitter - Pérdida aleatoria ligera]
# RED suave. Comienza a descartar al superar los 15 paquetes y descarta 100%
# al llegar a 35. Simula pérdida intermitente y jitter leve (1-3% packet loss).
add name="catC-game-1-jitter" kind=red red-limit=60 red-min-threshold=15 red-max-threshold=35 red-burst=20

# [C2. Gaming Rubberband - Pérdida moderada por ráfagas]
# RED intermedio. Umbrales muy juntos (5 a 12 paquetes). En cuanto el juego 
# envía ráfagas de movimiento, la probabilidad de descarte sube drásticamente (10-20% loss).
# Provoca que el jugador teletransporte constantemente hacia atrás (rubberbanding).
add name="catC-game-2-rubberband" kind=red red-limit=30 red-min-threshold=5 red-max-threshold=12 red-burst=10

# [C3. Gaming Choke - Desconexión inminente]
# RED destructivo. Umbral mínimo de 1 paquete y máximo de 2. Prácticamente todo
# paquete que encuentre cola es descartado al instante. Provoca desincronización
# total y expulsión de la partida al lobby en segundos.
add name="catC-game-3-choke" kind=red red-limit=8 red-min-threshold=1 red-max-threshold=2 red-burst=2


# ---------------------------------------------------------------------
# 2. AUDITORÍA EXCLUSIVA DE GAMING (MANGLE + QUEUE TREE)
# ---------------------------------------------------------------------
# Aplica los perfiles de la Categoría C únicamente al tráfico UDP de juego.

# A. Marcado de tráfico de juegos en el Firewall (Mangle)
# /ip firewall mangle
# add chain=forward protocol=udp dst-port=!53 packet-size=0-500 \
#     action=mark-packet new-packet-mark=gaming-only-bad passthrough=no \
#     comment="Aislar Gaming (UDP chico)"

# B. Aplicación en Queue Tree (Ejemplo con el Perfil C2)
# /queue tree
# add name="Audit-Gaming-Only" parent=global packet-mark=gaming-only-bad \
#     queue=catC-game-2-rubberband max-limit=10M


# ---------------------------------------------------------------------
# 3. APLICACIÓN GENERAL A UN DISPOSITIVO (SIMPLE QUEUES)
# ---------------------------------------------------------------------
# NOTA: Reemplazar "192.168.88.100" con la IP del dispositivo objetivo.

# Ejemplo Aplicando Categoría B (PCQ Moderado):
# /queue simple add name="Audit-PCQ-Ports" \
#     target=192.168.88.100 \
#     queue=catB-pcq-2-moderate/catB-pcq-2-moderate \
#     max-limit=50M/50M

# Ejemplo Aplicando Categoría C (Gaming Choke total):
# /queue simple add name="Audit-Choke-Extreme" \
#     target=192.168.88.100 \
#     queue=catC-game-3-choke/catC-game-3-choke \
#     max-limit=20M/20M


# ---------------------------------------------------------------------
# 4. COMANDOS DE DESACTIVACIÓN Y LIMPIEZA (ROLLBACK)
# ---------------------------------------------------------------------
# /queue simple remove [find name~"Audit-"]
# /queue tree remove [find name~"Audit-"]
# /ip firewall mangle remove [find comment~"Aislar Gaming"]
# /queue type remove [find name~"catA-"]
# /queue type remove [find name~"catB-"]
# /queue type remove [find name~"catC-"]