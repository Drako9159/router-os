### SQM generado por Grok Cake
# 1. Crear tipos de queue CAKE
/queue type
add kind=cake name=cake-down cake-diffserv=besteffort cake-flowmode=dual-dsthost cake-rtt-scheme=internet cake-nat=yes
# besteffort → Sin priorización, trata todo el tráfico igual.
# disserv4 → Prioriza tráfico interactivo (VoIP, video) sobre bulk (torrents).
add kind=cake name=cake-up cake-ack-filter=filter cake-diffserv=besteffort cake-flowmode=dual-srchost cake-rtt-scheme=internet cake-nat=yes
# 2. Crear la Simple Queue (ajusta los valores según tu velocidad real)
# Ejemplo para ~300 Mbps down / upload simétrico o asimétrico
/queue simple
add name=SQM-CAKE max-limit=260M/260M queue=cake-down/cake-up target=ether1 total-queue=default
# Para usar queue tree en lugar de simple queue, comenta la sección anterior y descomenta esta:
/queue tree
add name=Download parent=bridge max-limit=260M queue=cake-down packet-mark=no-mark
add name=Upload parent=ether1 max-limit=260M queue=cake-up packet-mark=no-mark

/ip firewall filter
# Modifica o agrega regla para fasttrack solo LAN (no WAN)
add action=fasttrack-connection chain=forward \
    connection-state=established,related \
    comment="fasttrack LAN only" \
    in-interface-list=LAN \
    out-interface=!ether1

# Marca tráfico con Mangle para packet marking (opcional, para reglas avanzadas o estadísticas)
/ip firewall mangle
# Marcar tráfico saliente de tu PC gaming (ajusta IP)
add action=mark-connection chain=prerouting \
    src-address=192.168.88.100 \   # ← IP de tu PC
    new-connection-mark=gaming_conn passthrough=yes \
    comment="Mark Gaming"
add action=mark-packet chain=prerouting \
    connection-mark=gaming_conn \
    new-packet-mark=gaming passthrough=no
# 1. Primero asegúrate de tener los tipos CAKE (con diffserv4 para mejor priorización)
 /queue type
add kind=cake name=cake-down cake-diffserv=diffserv4 cake-flowmode=dual-dsthost \
    cake-rtt-scheme=internet cake-nat=yes
add kind=cake name=cake-up cake-diffserv=diffserv4 cake-ack-filter=filter \
    cake-flowmode=dual-srchost cake-rtt-scheme=internet cake-nat=yes

/ip firewall mangle
# === Marcar Gaming (ajusta según tu caso) ===
# Para tu PC de gaming (ejemplo IP)
add action=mark-connection chain=prerouting src-address=192.168.88.100 \
    new-connection-mark=gaming_conn passthrough=yes comment="Gaming Conn"
add action=mark-packet chain=prerouting connection-mark=gaming_conn \
    new-packet-mark=gaming passthrough=no comment="Gaming Packet Mark"
# Opcional: marcar por puertos comunes de juegos (ejemplo)
add action=mark-packet chain=prerouting dst-port=3074,27015-27030,3478-3479,5060,5061 \
    protocol=udp new-packet-mark=gaming passthrough=no comment="Gaming Ports"
/queue tree
# === Cola principal Download (todo el tráfico) ===
add name=Download-Main parent=bridge max-limit=260M \
    queue=cake-down packet-mark=no-mark bucket-size=0.01 comment="CAKE Download Principal"
# === Cola principal Upload ===
add name=Upload-Main parent=ether1 max-limit=260M \
    queue=cake-up packet-mark=no-mark bucket-size=0.01 comment="CAKE Upload Principal"
# === Cola hija para Gaming (alta prioridad) ===
# Download Gaming
add name=Gaming-Download parent=Download-Main packet-mark=gaming \
    priority=1 max-limit=260M queue=cake-down bucket-size=0.01
# Upload Gaming
add name=Gaming-Upload parent=Upload-Main packet-mark=gaming \
    priority=1 max-limit=260M queue=cake-up bucket-size=0.01
# packet-mark=no-mark → Captura todo el tráfico que no tenga marca (la mayoría).
# priority=1 → Prioridad más alta (el número más bajo = mayor prioridad). Gaming pasa primero.
# parent=Download-Main → La cola hija está debajo de la principal (jerarquía HTB).
# max-limit → En las hijas puede ser igual o menor que la principal.

### SQM generado por Grok FQ-CoDel
/queue type
add kind=fq-codel name=fq-codel-SQM fq-codel-limit=1200 fq-codel-quantum=300 fq-codel-target=5ms fq-codel-interval=100ms fq-codel-ecn=no
# limit=1200: Buen valor para la mayoría de conexiones.
# quantum=300: Bueno para Ethernet (puedes probar 1514 si ves problemas).
# target=5ms: Muy agresivo para baja latencia (puedes subir a 7-10ms si hay mucho jitter).
/queue simple
add name=SQM-FQ-CoDel \
    max-limit=260M/260M \   # ← Ajusta al 85-95% de tu velocidad real
    queue=fq-codel-SQM/fq-codel-SQM \
    target=ether1 \         # ← Tu interfaz WAN
    total-queue=fq-codel-SQM
/queue tree
# Download (aplicado en el bridge LAN)
add name=Download-Main parent=bridge max-limit=260M \
    queue=fq-codel-SQM packet-mark=no-mark bucket-size=0.01
# Upload (aplicado en WAN)
add name=Upload-Main parent=ether1 max-limit=260M \
    queue=fq-codel-SQM packet-mark=no-mark bucket-size=0.01
# Ejemplo de cola hija para Gaming (alta prioridad)
add name=Gaming-Download parent=Download-Main packet-mark=gaming \
    priority=1 max-limit=260M queue=fq-codel-SQM
add name=Gaming-Upload parent=Upload-Main packet-mark=gaming \
    priority=1 max-limit=260M queue=fq-codel-SQM
/ip firewall filter
add action=fasttrack-connection chain=forward \
    connection-state=established,related \
    in-interface-list=LAN out-interface=!ether1 \
    comment="fasttrack LAN only - SQM funciona"
