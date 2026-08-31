# =====================================================================
# CONFIGURACIÓN DE LIMITADORES DE ANCHO DE BANDA MIKROTIK (Optimizado)
# =====================================================================
# Cada sección asocia una "Address List" de IPs con su marcado de 
# conexiones y paquetes (Mangle) y sus colas de velocidad (Queue Tree).
# =====================================================================
# NOTA IMPORTANTE: Para que estos limitadores funcionen, los clientes
# deben tener la etiqueta "NFAST" asignada en su DHCP Lease o su
# IP agregada a una lista de bypass de FastTrack en el Firewall.
# =====================================================================

# =====================================================================
# LIMITADOR: LMT-32KB
# Velocidad: 32 Kbps (Subida / Bajada)
# Algoritmo: FQ-CoDel
# =====================================================================

# 1. Marcado de conexiones y paquetes
/ip firewall mangle
add chain=forward connection-state=new src-address-list=LMT-32KB \
    action=mark-connection new-connection-mark=LMT32KB-conn passthrough=yes \
    comment="LMT-32KB: Marcar nueva conexion (Subida)"
add chain=forward connection-state=new dst-address-list=LMT-32KB \
    action=mark-connection new-connection-mark=LMT32KB-conn passthrough=yes \
    comment="LMT-32KB: Marcar nueva conexion (Bajada)"

add chain=forward connection-mark=LMT32KB-conn action=jump jump-target=lmt-32kb-pkt \
    comment="LMT-32KB: Enviar a sub-cadena de marcado de paquetes"

add chain=lmt-32kb-pkt src-address-list=LMT-32KB \
    action=mark-packet new-packet-mark=LMT32KB-UPLOAD passthrough=no \
    comment="LMT-32KB: Marcar paquetes (Subida)"
add chain=lmt-32kb-pkt \
    action=mark-packet new-packet-mark=LMT32KB-DOWNLOAD passthrough=no \
    comment="LMT-32KB: Marcar paquetes (Bajada)"

# 2. Cola de velocidad
/queue tree
add max-limit=32k name=LMT32KB-UPLOAD packet-mark=LMT32KB-UPLOAD parent=\
    global queue=fq-codel
add max-limit=32k name=LMT32KB-DOWNLOAD packet-mark=LMT32KB-DOWNLOAD parent=\
    global queue=fq-codel

# 3. Bypass Fasttrack
/ip firewall filter
add action=accept chain=forward comment="BYPASS FASTTRACKING LMT32KB" \
    connection-mark=LMT32KB-conn place-before=[find where action=fasttrack-connection]


# =====================================================================
# LIMITADOR: LMT-2M
# Velocidad: 2 Mbps (Subida / Bajada)
# Algoritmo: CAKE Direccional
# =====================================================================

# 1. Marcado de conexiones y paquetes
/ip firewall mangle
add chain=forward connection-state=new src-address-list=LMT-2M \
    action=mark-connection new-connection-mark=LMT2M-conn passthrough=yes \
    comment="LMT-2M: Marcar nueva conexion (Subida)"
add chain=forward connection-state=new dst-address-list=LMT-2M \
    action=mark-connection new-connection-mark=LMT2M-conn passthrough=yes \
    comment="LMT-2M: Marcar nueva conexion (Bajada)"

add chain=forward connection-mark=LMT2M-conn action=jump jump-target=lmt-2m-pkt \
    comment="LMT-2M: Enviar a sub-cadena de marcado de paquetes"

add chain=lmt-2m-pkt src-address-list=LMT-2M \
    action=mark-packet new-packet-mark=LMT2M-UPLOAD passthrough=no \
    comment="LMT-2M: Marcar paquetes (Subida)"
add chain=lmt-2m-pkt \
    action=mark-packet new-packet-mark=LMT2M-DOWNLOAD passthrough=no \
    comment="LMT-2M: Marcar paquetes (Bajada)"

# 2. Cola de velocidad
/queue tree
add max-limit=2M name=LMT2M-UPLOAD packet-mark=LMT2M-UPLOAD parent=global \
    queue=cake-padre-upload
add max-limit=2M name=LMT2M-DOWNLOAD packet-mark=LMT2M-DOWNLOAD parent=global \
    queue=cake-padre-download

# 3. Bypass Fasttrack
/ip firewall filter
add action=accept chain=forward comment="BYPASS FASTTRACKING LMT2M" \
    connection-mark=LMT2M-conn place-before=[find where action=fasttrack-connection]


# =====================================================================
# LIMITADOR: LMT-5M
# Velocidad: 5 Mbps (Subida / Bajada)
# Algoritmo: CAKE Direccional
# =====================================================================

# 1. Marcado de conexiones y paquetes
/ip firewall mangle
add chain=forward connection-state=new src-address-list=LMT-5M \
    action=mark-connection new-connection-mark=LMT5M-conn passthrough=yes \
    comment="LMT-5M: Marcar nueva conexion (Subida)"
add chain=forward connection-state=new dst-address-list=LMT-5M \
    action=mark-connection new-connection-mark=LMT5M-conn passthrough=yes \
    comment="LMT-5M: Marcar nueva conexion (Bajada)"

add chain=forward connection-mark=LMT5M-conn action=jump jump-target=lmt-5m-pkt \
    comment="LMT-5M: Enviar a sub-cadena de marcado de paquetes"

add chain=lmt-5m-pkt src-address-list=LMT-5M \
    action=mark-packet new-packet-mark=LMT5M-UPLOAD passthrough=no \
    comment="LMT-5M: Marcar paquetes (Subida)"
add chain=lmt-5m-pkt \
    action=mark-packet new-packet-mark=LMT5M-DOWNLOAD passthrough=no \
    comment="LMT-5M: Marcar paquetes (Bajada)"

# 2. Cola de velocidad
/queue tree
add max-limit=5M name=LMT5M-UPLOAD packet-mark=LMT5M-UPLOAD parent=global \
    queue=cake-padre-upload
add max-limit=5M name=LMT5M-DOWNLOAD packet-mark=LMT5M-DOWNLOAD parent=global \
    queue=cake-padre-download

# 3. Bypass Fasttrack
/ip firewall filter
add action=accept chain=forward comment="BYPASS FASTTRACKING LMT5M" \
    connection-mark=LMT5M-conn place-before=[find where action=fasttrack-connection]

# =====================================================================
# LIMITADOR: LMT-4M
# Velocidad: 4 Mbps (Subida / Bajada)
# Algoritmo: CAKE Direccional
# =====================================================================

# 1. Marcado de conexiones y paquetes
/ip firewall mangle
add chain=forward connection-state=new src-address-list=LMT-4M \
    action=mark-connection new-connection-mark=LMT4M-conn passthrough=yes \
    comment="LMT-4M: Marcar nueva conexion (Subida)"
add chain=forward connection-state=new dst-address-list=LMT-4M \
    action=mark-connection new-connection-mark=LMT4M-conn passthrough=yes \
    comment="LMT-4M: Marcar nueva conexion (Bajada)"

add chain=forward connection-mark=LMT4M-conn action=jump jump-target=lmt-4m-pkt \
    comment="LMT-4M: Enviar a sub-cadena de marcado de paquetes"

add chain=lmt-4m-pkt src-address-list=LMT-4M \
    action=mark-packet new-packet-mark=LMT4M-UPLOAD passthrough=no \
    comment="LMT-4M: Marcar paquetes (Subida)"
add chain=lmt-4m-pkt \
    action=mark-packet new-packet-mark=LMT4M-DOWNLOAD passthrough=no \
    comment="LMT-4M: Marcar paquetes (Bajada)"

# 2. Cola de velocidad
/queue tree
add max-limit=4M name=LMT4M-UPLOAD packet-mark=LMT4M-UPLOAD parent=global \
    queue=cake-padre-upload
add max-limit=4M name=LMT4M-DOWNLOAD packet-mark=LMT4M-DOWNLOAD parent=global \
    queue=cake-padre-download

# 3. Bypass Fasttrack
/ip firewall filter
add action=accept chain=forward comment="BYPASS FASTTRACKING LMT4M" \
    connection-mark=LMT4M-conn place-before=[find where action=fasttrack-connection]

# =====================================================================
# LIMITADOR: LMT-1M
# Velocidad: 1 Mbps (Subida / Bajada)
# Algoritmo: CAKE Direccional
# =====================================================================

# 1. Marcado de conexiones y paquetes
/ip firewall mangle
add chain=forward connection-state=new src-address-list=LMT-1M \
    action=mark-connection new-connection-mark=LMT1M-conn passthrough=yes \
    comment="LMT-1M: Marcar nueva conexion (Subida)"
add chain=forward connection-state=new dst-address-list=LMT-1M \
    action=mark-connection new-connection-mark=LMT1M-conn passthrough=yes \
    comment="LMT-1M: Marcar nueva conexion (Bajada)"

add chain=forward connection-mark=LMT1M-conn action=jump jump-target=lmt-1m-pkt \
    comment="LMT-1M: Enviar a sub-cadena de marcado de paquetes"

add chain=lmt-1m-pkt src-address-list=LMT-1M \
    action=mark-packet new-packet-mark=LMT1M-UPLOAD passthrough=no \
    comment="LMT-1M: Marcar paquetes (Subida)"
add chain=lmt-1m-pkt \
    action=mark-packet new-packet-mark=LMT1M-DOWNLOAD passthrough=no \
    comment="LMT-1M: Marcar paquetes (Bajada)"

# 2. Cola de velocidad
/queue tree
add max-limit=1M name=LMT1M-UPLOAD packet-mark=LMT1M-UPLOAD parent=global \
    queue=cake-padre-upload
add max-limit=1M name=LMT1M-DOWNLOAD packet-mark=LMT1M-DOWNLOAD parent=global \
    queue=cake-padre-download

# 3. Bypass Fasttrack
/ip firewall filter
add action=accept chain=forward comment="BYPASS FASTTRACKING LMT1M" \
    connection-mark=LMT1M-conn place-before=[find where action=fasttrack-connection]