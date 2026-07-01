# =====================================================================
# CONFIGURACIÓN DE LIMITADORES DE ANCHO DE BANDA MIKROTIK
# =====================================================================
# Cada sección es independiente y asocia una "Address List" de IPs 
# con su marcado de paquetes (Mangle) y sus colas de velocidad (Queue Tree).
# =====================================================================
# NOTA IMPORTANTE: Para que estos limitadores funcionen, los clientes
# deben tener la etiqueta "nofasttrack" asignada en su DHCP Lease (o su
# IP agregada a una lista de bypass de FastTrack en el Firewall).
# =====================================================================

# =====================================================================
# LIMITADOR: limit32kb
# Velocidad: 32 Kbps (Subida / Bajada)
# Uso: Colocar las IPs a limitar en el address-list "limit32kb"
# Algoritmo: FQ-CoDel (Liviano para velocidades extremadamente bajas)
# =====================================================================

# 1. Marcado de paquetes
/ip firewall mangle
add chain=forward action=mark-packet new-packet-mark=limit32kb-down passthrough=no dst-address-list=limit32kb comment="limit32kb - Download"
add chain=forward action=mark-packet new-packet-mark=limit32kb-up passthrough=no src-address-list=limit32kb comment="limit32kb - Upload"

# 2. Cola de velocidad
/queue tree
add name="limit32kb-down" parent=global packet-mark=limit32kb-down max-limit=32k queue=fq-codel comment="limit32kb - Download Limit"
add name="limit32kb-up" parent=global packet-mark=limit32kb-up max-limit=32k queue=fq-codel comment="limit32kb - Upload Limit"


# =====================================================================
# LIMITADOR: limit2M
# Velocidad: 2 Mbps (Subida / Bajada)
# Uso: Colocar las IPs a limitar en el address-list "limit2M"
# Algoritmo: CAKE Direccional (Optimizado para balancear y aislar)
# =====================================================================

# 1. Marcado de paquetes
/ip firewall mangle
add chain=forward action=mark-packet new-packet-mark=limit2M-down passthrough=no dst-address-list=limit2M comment="limit2M - Download"
add chain=forward action=mark-packet new-packet-mark=limit2M-up passthrough=no src-address-list=limit2M comment="limit2M - Upload"

# 2. Cola de velocidad
/queue tree
add name="limit2M-down" parent=global packet-mark=limit2M-down max-limit=2M queue=cake-padre-download comment="limit2M - Download Limit"
add name="limit2M-up" parent=global packet-mark=limit2M-up max-limit=2M queue=cake-padre-upload comment="limit2M - Upload Limit"


# =====================================================================
# LIMITADOR: limit5M
# Velocidad: 5 Mbps (Subida / Bajada)
# Uso: Colocar las IPs a limitar en el address-list "limit5M"
# Algoritmo: CAKE Direccional (Optimizado para balancear y aislar)
# =====================================================================

# 1. Marcado de paquetes
/ip firewall mangle
add chain=forward action=mark-packet new-packet-mark=limit5M-down passthrough=no dst-address-list=limit5M comment="limit5M - Download"
add chain=forward action=mark-packet new-packet-mark=limit5M-up passthrough=no src-address-list=limit5M comment="limit5M - Upload"

# 2. Cola de velocidad
/queue tree
add name="limit5M-down" parent=global packet-mark=limit5M-down max-limit=5M queue=cake-padre-download comment="limit5M - Download Limit"
add name="limit5M-up" parent=global packet-mark=limit5M-up max-limit=5M queue=cake-padre-upload comment="limit5M - Upload Limit"


# =====================================================================
# LIMITADOR: limit10M
# Velocidad: 10 Mbps (Subida / Bajada)
# Uso: Colocar las IPs a limitar en el address-list "limit10M"
# Algoritmo: CAKE Direccional (Optimizado para balancear y aislar)
# =====================================================================

# 1. Marcado de paquetes
/ip firewall mangle
add chain=forward action=mark-packet new-packet-mark=limit10M-down passthrough=no dst-address-list=limit10M comment="limit10M - Download"
add chain=forward action=mark-packet new-packet-mark=limit10M-up passthrough=no src-address-list=limit10M comment="limit10M - Upload"

# 2. Cola de velocidad
/queue tree
add name="limit10M-down" parent=global packet-mark=limit10M-down max-limit=10M queue=cake-padre-download comment="limit10M - Download Limit"
add name="limit10M-up" parent=global packet-mark=limit10M-up max-limit=10M queue=cake-padre-upload comment="limit10M - Upload Limit"
