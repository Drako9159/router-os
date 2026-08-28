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

/ip firewall nat
# Redirección DNS tradicional (TCP) - Usado para respuestas grandes
add action=dst-nat chain=dstnat comment=\
    "Force Family DNS (TCP) - Exclusion active" dst-address=!1.1.1.3 \
    dst-port=53 protocol=tcp src-address-list=DNS-FAMILY to-addresses=1.1.1.3 \
    to-ports=53
# Redirección DNS tradicional (UDP) - Solo si no está yendo ya a 1.1.1.3
add action=dst-nat chain=dstnat comment=\
    "Force Family DNS (UDP) - Exclusion active" dst-address=!1.1.1.3 \
    dst-port=53 protocol=udp src-address-list=DNS-FAMILY to-addresses=1.1.1.3 \
    to-ports=53
/ip firewall filter
# Bloqueo de DNS over TLS (DoT) en puerto 853
add action=reject chain=forward comment="Block DNS over TLS (DoT) for Family" \
    dst-port=853 protocol=tcp reject-with=tcp-reset src-address-list=\
    DNS-FAMILY
# Bloqueo de puertos UDP VPN
add action=drop chain=forward comment=\
    "Bloquear puertos de tunel VPN WARP UDP" dst-port=2408,500,1701,4500 \
    protocol=udp src-address-list=DNS-FAMILY
# Bloqueo de puertos TCP VPN
add action=drop chain=forward comment=\
    "Bloquear puertos de tunel VPN WARP TCP" dst-port=\
    9000-9099,9600,9993,1984,9050,9051 protocol=tcp src-address-list=\
    DNS-FAMILY
# Bloqueo de VPNs identificadas (IP/Dominio) para el grupo DNS-FAMILY
add action=drop chain=forward comment="Block identified VPNs for dnsfamily" \
    dst-address-list=blocked-vpns src-address-list=DNS-FAMILY










