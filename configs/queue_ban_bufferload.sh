# =====================================================================
# MIKROTIK ROUTEROS - BANCO DE PRUEBAS DE DEGRADACIÓN DE RED (AUDITORÍA)
# =====================================================================
# Estructura de nombres optimizada para RouterOS:
# [cat][A/B]-[mecanismo]-[nivel]-[descriptivo]
# =====================================================================

# ---------------------------------------------------------------------
# 1. CREACIÓN DE QUEUE TYPES POR CATEGORÍA
# ---------------------------------------------------------------------
/queue type

# =====================================================================
# CATEGORÍA A: RENDIMIENTO GENERAL (BUFFERBLOAT & DELAY LINEAL)
# Afecta a todo el tráfico por igual mediante buffers FIFO profundos.
# NOTA: Para experimentar bufferbloat real, la cola (Simple Queue) DEBE
# tener un límite de velocidad (max-limit) configurado. De lo contrario,
# el buffer se vaciará instantáneamente y no habrá degradación perceptible.
# =====================================================================

# [A1. Leve / Latencia perceptible bajo carga leve]
# Recomendado para colas <= 10M. Agrega ~100-300ms de lag en ráfagas.
add kind=pfifo name=catA-gen-1-mild pfifo-limit=100
# [A2. Medio / Delay notable en videollamadas y streaming]
# Recomendado para colas <= 5M. Agrega ~300-600ms de lag.
add kind=pfifo name=catA-gen-2-moderate pfifo-limit=250

# [A3. Severo / Lag importante y tiempos de carga elevados]
# Recomendado para colas <= 2M. Buffer de 2MB. Delay de ~8 segundos en saturación.
add bfifo-limit=2000000 kind=bfifo name=catA-gen-3-heavy
# [A4. Pesadilla / Conexión al borde de la inutilidad]
# Recomendado para colas <= 1M. Buffer de 5MB. Delay de ~40 segundos, provoca timeouts.
add bfifo-limit=5000000 kind=bfifo name=catA-gen-4-nightmare
# [A5. Apocalíptico / Retraso masivo de minutos y desconexiones]
# Recomendado para colas <= 512k. Buffer de 10MB. Delay de ~160 segundos, interrupción de TCP.
add bfifo-limit=10000000 kind=bfifo name=catA-gen-5-apocalypse


# =====================================================================
# CATEGORÍA B: DEGRADACIÓN POR CONEXIÓN (CONGESTIÓN PCQ POR PUERTOS)
# Clasifica y estrangula cada puerto/socket de forma independiente.
# Afecta principalmente la carga de páginas web y descargas concurrentes.
# =====================================================================

# [B1. PCQ Muy Leve - Navegación casi normal con ligeras pausas]
# Límite amplio por puerto que solo molesta si se abren muchas pestañas pesadas.
add kind=pcq name=catB-pcq-1-ultralight pcq-classifier=src-port,dst-port \
    pcq-limit=100KiB pcq-rate=5M
# [B2. PCQ Leve - Carga de páginas web ligeramente perezosa]
# Adecuado para simular una conexión de banda ancha hogareña congestionada.
add kind=pcq name=catB-pcq-2-light pcq-classifier=src-port,dst-port pcq-rate=\
    2M
# [B3. PCQ Moderado - Frustración controlada / Carga lenta]
# El viejo nivel 1. Cada puerto se limita a 1M. Comienza a sentirse pesado.
add kind=pcq name=catB-pcq-3-moderate pcq-classifier=src-port,dst-port \
    pcq-limit=30KiB pcq-rate=1M
# [B4. PCQ Heavy - Lentitud extrema / Buffering constante]
# El viejo nivel 2. Limitado a 512k por socket. Páginas complejas tardan segundos.
add kind=pcq name=catB-pcq-4-heavy pcq-classifier=src-port,dst-port \
    pcq-limit=15KiB pcq-rate=512k
# [B5. PCQ Severe - Lentitud insufrible / Timeouts frecuentes]
# El viejo nivel 3. Limitado a 128k por socket y buffer minúsculo de 5 paquetes.
# Genera pérdida por desborde inmediato al menor intento de descarga.
add kind=pcq name=catB-pcq-5-severe pcq-classifier=src-port,dst-port \
    pcq-limit=5KiB pcq-rate=128k


# =====================================================================
# EJEMPLO DE APLICACIÓN - CATEGORÍA B (PCQ POR PUERTOS)
# =====================================================================
# Ejemplo aplicando PCQ Moderado (limita cada socket/puerto individual a 1M)
# /queue simple add name="Audit-PCQ-Ports" target=192.168.88.100 \
#     queue=catB-pcq-3-moderate/catB-pcq-3-moderate max-limit=50M/50M


# ---------------------------------------------------------------------
# 3. SIMULACIÓN DE DEGRADACIÓN VÍA FIREWALL (PÉRDIDA DE PAQUETES - RANDOM)
# ---------------------------------------------------------------------
# Permite simular pérdida de paquetes de forma aleatoria directo en el firewall.
# Para aplicar la degradación a un dispositivo, simplemente agregá su IP
# a la address-list correspondiente. Todas las reglas pueden estar activas a la vez.

# =====================================================================
# OPCIÓN A: ENFOCADO EXCLUSIVAMENTE EN GAMING (UDP CHICO)
# (Afecta solo a juegos sin dañar descargas de archivos ni webs)
# =====================================================================

# [Gaming Leve - 5% Packet Loss / Jitter ligero]
# -> Agregar IPs a address-list "lossG5"
/ip firewall filter
add chain=forward protocol=udp dst-port=!53 packet-size=0-500 src-address-list=lossG5 action=drop random=5 \
    comment="Simular LossG5 (Subida) - 5% Gaming"
add chain=forward protocol=udp src-port=!53 packet-size=0-500 dst-address-list=lossG5 action=drop random=5 \
    comment="Simular LossG5 (Bajada) - 5% Gaming"

# [Gaming Severo - 15% Packet Loss / Rubberbanding constante]
# -> Agregar IPs a address-list "lossG15"
/ip firewall filter
add chain=forward protocol=udp dst-port=!53 packet-size=0-500 src-address-list=lossG15 action=drop random=15 \
    comment="Simular LossG15 (Subida) - 15% Gaming"
add chain=forward protocol=udp src-port=!53 packet-size=0-500 dst-address-list=lossG15 action=drop random=15 \
    comment="Simular LossG15 (Bajada) - 15% Gaming"

# [Gaming Extremo - 30% Packet Loss / Desconexiones parciales]
# -> Agregar IPs a address-list "lossG30"
/ip firewall filter
add chain=forward protocol=udp dst-port=!53 packet-size=0-500 src-address-list=LOSS-G30 action=drop random=30 \
    comment="Simular LossG30 (Subida) - 30% Gaming"
add chain=forward protocol=udp src-port=!53 packet-size=0-500 dst-address-list=LOSS-G30 action=drop random=30 \
    comment="Simular LossG30 (Bajada) - 30% Gaming"


# =====================================================================
# OPCIÓN B: ENFOCADO EN DEGRADACIÓN GENERAL (TODO EL TRÁFICO)
# (Destruye la experiencia de navegación, descargas y juegos por igual)
# =====================================================================

# [General Leve - 3% Packet Loss / Navegación ligeramente pausada]
# -> Agregar IPs a address-list "loss3"
/ip firewall filter
add chain=forward src-address-list=LOSS-3 action=drop random=3 \
    comment="Simular Loss3 (Subida) - 3% General"
add chain=forward dst-address-list=LOSS-3 action=drop random=3 \
    comment="Simular Loss3 (Bajada) - 3% General"

# [General Severo - 10% Packet Loss / Buffering constante y lentitud]
# -> Agregar IPs a address-list "loss10"
/ip firewall filter
add chain=forward src-address-list=LOSS-10 action=drop random=10 \
    comment="Simular Loss10 (Subida) - 10% General"
add chain=forward dst-address-list=LOSS-10 action=drop random=10 \
    comment="Simular Loss10 (Bajada) - 10% General"

# [General Extremo - 25% Packet Loss / Timeouts masivos y colapso TCP]
# -> Agregar IPs a address-list "loss25"
/ip firewall filter
add chain=forward src-address-list=LOSS-25 action=drop random=25 \
    comment="Simular Loss25 (Subida) - 25% General"
add chain=forward dst-address-list=LOSS-25 action=drop random=25 \
    comment="Simular Loss25 (Bajada) - 25% General"


# ---------------------------------------------------------------------
# 4. COMANDOS DE DESACTIVACIÓN Y LIMPIEZA (ROLLBACK)
# ---------------------------------------------------------------------
# /queue simple remove [find name~"Audit-"]
# /ip firewall mangle remove [find comment~"Aislar Gaming"]
# /ip firewall filter remove [find comment~"Simular Loss"]
# /queue type remove [find name~"catA-"]
# /queue type remove [find name~"catB-"]