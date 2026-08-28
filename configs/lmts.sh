# =====================================================================
# CONFIGURACIÓN DE LIMITADORES DE ANCHO DE BANDA MIKROTIK
# =====================================================================
# Cada sección es independiente y asocia una "Address List" de IPs 
# con su marcado de paquetes (Mangle) y sus colas de velocidad (Queue Tree).
# =====================================================================
# NOTA IMPORTANTE: Para que estos limitadores funcionen, los clientes
# deben tener la etiqueta "NFAST" asignada en su DHCP Lease (o su
# IP agregada a una lista de bypass de FastTrack en el Firewall).
# O Podrían tener FastTrack desactivado en el Firewall para que las colas de velocidad
# =====================================================================

# =====================================================================
# LIMITADOR: LMT-32KB
# Velocidad: 32 Kbps (Subida / Bajada)
# Uso: Colocar las IPs a limitar en el address-list "LMT-32KB"
# Algoritmo: FQ-CoDel (Liviano para velocidades extremadamente bajas)
# =====================================================================

# 1. Marcado de paquetes
/ip firewall mangle
add action=mark-packet chain=forward comment=LMT32KB-UPLOAD new-packet-mark=\
    LMT32KB-UPLOAD passthrough=no src-address-list=LMT-32KB
add action=mark-packet chain=forward comment=LMT32KB-DOWNLOAD \
    dst-address-list=LMT-32KB new-packet-mark=LMT32KB-DOWNLOAD passthrough=no


# 2. Cola de velocidad
/queue tree
add max-limit=32k name=LMT32KB-UPLOAD packet-mark=LMT32KB-UPLOAD parent=\
    global queue=fq-codel
add max-limit=32k name=LMT32KB-DOWNLOAD packet-mark=LMT32KB-DOWNLOAD parent=\
    global queue=fq-codel

# 3. Byppas Fastrack - Antes de la regla de FastTrack en el Firewall, agregar estas dos reglas para que las IPs limitadas no sean fasttrackadas y puedan ser controladas por las colas de velocidad.
/ip firewall filter
add action=accept chain=forward comment="BYPASS FASTTRACKING LMT32KB" \
    src-address-list=LMT-32KB
add action=accept chain=forward comment="BYPASS FASTTRACKING LMT32KB" \
    dst-address-list=LMT-32KB
# =====================================================================
# LIMITADOR: LMT-2M
# Velocidad: 2 Mbps (Subida / Bajada)
# Uso: Colocar las IPs a limitar en el address-list "LMT-2M"
# Algoritmo: CAKE Direccional (Optimizado para balancear y aislar)
# =====================================================================

# 1. Marcado de paquetes
/ip firewall mangle
add action=mark-packet chain=forward comment=LMT2M-UPLOAD new-packet-mark=\
    LMT2M-UPLOAD passthrough=no src-address-list=LMT-2M
add action=mark-packet chain=forward comment=LMT2M-DOWNLOAD dst-address-list=\
    LMT-2M new-packet-mark=LMT2M-DOWNLOAD passthrough=no

# 2. Cola de velocidad
/queue tree
add max-limit=2M name=LMT2M-UPLOAD packet-mark=LMT2M-UPLOAD parent=global \
    queue=cake-padre-upload
add max-limit=2M name=LMT2M-DOWNLOAD packet-mark=LMT2M-DOWNLOAD parent=global \
    queue=cake-padre-download

# 3. Byppas Fastrack - Antes de la regla de FastTrack en el Firewall, agregar estas dos reglas para que las IPs limitadas no sean fasttrackadas y puedan ser controladas por las colas de velocidad.
/ip firewall filter
add action=accept chain=forward comment="BYPASS FASTTRACKING LMT2M" \
    src-address-list=LMT-2M
add action=accept chain=forward comment="BYPASS FASTTRACKING LMT2M" \
    dst-address-list=LMT-2M
# =====================================================================
# LIMITADOR: LMT-5M
# Velocidad: 5 Mbps (Subida / Bajada)
# Uso: Colocar las IPs a limitar en el address-list "LMT-5M"
# Algoritmo: CAKE Direccional (Optimizado para balancear y aislar)
# =====================================================================

# 1. Marcado de paquetes
/ip firewall mangle
add action=mark-packet chain=forward comment=LMT5M-UPLOAD new-packet-mark=\
    LMT5M-UPLOAD passthrough=no src-address-list=LMT-5M
add action=mark-packet chain=forward comment=LMT5M-DOWNLOAD dst-address-list=\
    LMT-5M new-packet-mark=LMT5M-DOWNLOAD passthrough=no

# 2. Cola de velocidad
/queue tree
add max-limit=5M name=LMT5M-UPLOAD packet-mark=LMT5M-UPLOAD parent=global \
    queue=cake-padre-upload
add max-limit=5M name=LMT5M-DOWNLOAD packet-mark=LMT5M-DOWNLOAD parent=global \
    queue=cake-padre-download

# 3. Byppas Fastrack - Antes de la regla de FastTrack en el Firewall, agregar estas dos reglas para que las IPs limitadas no sean fasttrackadas y puedan ser controladas por las colas de velocidad.
/ip firewall filter
add action=accept chain=forward comment="BYPASS FASTTRACKING LMT5M" \
    src-address-list=LMT-5M
add action=accept chain=forward comment="BYPASS FASTTRACKING LMT5M" \
    dst-address-list=LMT-5M