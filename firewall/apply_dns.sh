# ==============================================================================
# MIKROTIK DNS FORCING & SECURITY CONFIGURATION
# ==============================================================================
# Este script automatiza la redirección de tráfico DNS (Puerto 53 UDP/TCP) 
# hacia servidores DNS seguros específicos según el grupo de dispositivos.
#
# IMPORTANTE: 
# 1. Usar siempre rutas absolutas en MikroTik para evitar errores de contexto.
# 2. Excluir la IP de destino (!to-addresses) en la regla dst-nat para evitar 
#    bucles de procesamiento innecesarios.
# 3. Bloquear DoT (Puerto 853) para evitar que los dispositivos evadan la 
#    redirección usando DNS cifrado sobre TLS.
# ==============================================================================

# ------------------------------------------------------------------------------
# GRUPO 1: CLOUDFLARE FAMILY DNS (1.1.1.3)
# Filtra malware y contenido para adultos.
# ------------------------------------------------------------------------------

# Redirección DNS tradicional (UDP) - Solo si no está yendo ya a 1.1.1.3
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=1.1.1.3 to-ports=53 \
    protocol=udp src-address-list=dnsfamily dst-address=!1.1.1.3 dst-port=53 \
    comment="Force Family DNS (UDP) - Exclusion active"

# Redirección DNS tradicional (TCP) - Usado para respuestas grandes
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=1.1.1.3 to-ports=53 \
    protocol=tcp src-address-list=dnsfamily dst-address=!1.1.1.3 dst-port=53 \
    comment="Force Family DNS (TCP) - Exclusion active"

# Bloqueo de DNS over TLS (DoT) en puerto 853
/ip firewall filter add chain=forward action=reject reject-with=tcp-reset \
    protocol=tcp src-address-list=dnsfamily dst-port=853 \
    comment="Block DNS over TLS (DoT) for Family"


# ------------------------------------------------------------------------------
# GRUPO 2: CLEANBROWSING DNS (185.228.168.168)
# Filtro familiar estricto.
# ------------------------------------------------------------------------------

# Redirección DNS tradicional (UDP)
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=185.228.168.168 to-ports=53 \
    protocol=udp src-address-list=cleanbrowsing dst-address=!185.228.168.168 dst-port=53 \
    comment="Force CleanBrowsing DNS (UDP)"

# Redirección DNS tradicional (TCP)
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=185.228.168.168 to-ports=53 \
    protocol=tcp src-address-list=cleanbrowsing dst-address=!185.228.168.168 dst-port=53 \
    comment="Force CleanBrowsing DNS (TCP)"

# Bloqueo de DNS over TLS (DoT) para CleanBrowsing
/ip firewall filter add chain=forward action=reject reject-with=tcp-reset \
    protocol=tcp src-address-list=cleanbrowsing dst-port=853 \
    comment="Block DNS over TLS (DoT) for CleanBrowsing"


# ------------------------------------------------------------------------------
# GRUPO 3: ADGUARD FAMILY DNS (94.140.14.15)
# Bloqueo de anuncios, malware y contenido adulto.
# ------------------------------------------------------------------------------

# Redirección DNS tradicional (UDP)
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=94.140.14.15 to-ports=53 \
    protocol=udp src-address-list=agfamily dst-address=!94.140.14.15 dst-port=53 \
    comment="Force Adguard Family DNS (UDP)"

# Redirección DNS tradicional (TCP)
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=94.140.14.15 to-ports=53 \
    protocol=tcp src-address-list=agfamily dst-address=!94.140.14.15 dst-port=53 \
    comment="Force Adguard Family DNS (TCP)"

# Bloqueo de DNS over TLS (DoT) para Adguard Family
/ip firewall filter add chain=forward action=reject reject-with=tcp-reset \
    protocol=tcp src-address-list=agfamily dst-port=853 \
    comment="Block DNS over TLS (DoT) for AdGuard Family"


# ------------------------------------------------------------------------------
# GRUPO 4: NEXTDNS (45.90.28.42) - Deshabilitado por defecto
# DNS personalizado.
# ------------------------------------------------------------------------------

# Redirección DNS tradicional (UDP)
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=45.90.28.42 to-ports=53 \
    protocol=udp src-address-list=nextdns dst-address=!45.90.28.42 dst-port=53 disabled=yes \
    comment="Force NextDNS (UDP)"

# Redirección DNS tradicional (TCP)
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=45.90.28.42 to-ports=53 \
    protocol=tcp src-address-list=nextdns dst-address=!45.90.28.42 dst-port=53 disabled=yes \
    comment="Force NextDNS (TCP)"

# Bloqueo de DNS over TLS (DoT) para NextDNS
/ip firewall filter add chain=forward action=reject reject-with=tcp-reset \
    protocol=tcp src-address-list=nextdns dst-port=853 disabled=yes \
    comment="Block DNS over TLS (DoT) for NextDNS"


# ==============================================================================
# REGLAS NUEVAS RECOMENDADAS (SEGURIDAD Y CONTROL)
# ==============================================================================

# A. Bloqueo de DNS over HTTPS (DoH) mediante Address List
# Explicación: DoH corre sobre HTTPS (puerto 443), por lo que la única forma de 
# filtrarlo es bloqueando el acceso a las IPs conocidas de servidores DoH públicos.
# NOTA: Debes crear la lista "doh-servers" con las IPs de los servidores DoH comunes.
/ip firewall filter add chain=forward action=reject reject-with=tcp-reset \
    protocol=tcp src-address-list=dnsfamily dst-address-list=doh-servers \
    comment="Block DNS over HTTPS (DoH) for Family group"

/ip firewall filter add chain=forward action=reject reject-with=tcp-reset \
    protocol=tcp src-address-list=cleanbrowsing dst-address-list=doh-servers \
    comment="Block DNS over HTTPS (DoH) for CleanBrowsing group"

/ip firewall filter add chain=forward action=reject reject-with=tcp-reset \
    protocol=tcp src-address-list=agfamily dst-address-list=doh-servers \
    comment="Block DNS over HTTPS (DoH) for AdGuard Family group"