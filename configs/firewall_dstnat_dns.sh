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
# Forzar DNS Familiar (1.1.1.3)
add chain=dstnat action=dst-nat to-addresses=1.1.1.3 to-ports=53 \
    protocol=udp src-address-list=DNS-1113 dst-address=!1.1.1.3 dst-port=53 \
    comment="Force Cloudflare Family DNS 1.1.1.3 (UDP)" place-before=0
add chain=dstnat action=dst-nat to-addresses=1.1.1.3 to-ports=53 \
    protocol=tcp src-address-list=DNS-1113 dst-address=!1.1.1.3 dst-port=53 \
    comment="Force Cloudflare Family DNS 1.1.1.3 (TCP)" place-before=0


/ip firewall filter
# Bloqueo de DNS over TLS (DoT) en puerto 853
add action=reject chain=forward comment="Block DNS over TLS (DoT) for Family" \
    dst-port=853 protocol=tcp reject-with=tcp-reset src-address-list=\
    DNS-1113
# Bloqueo de puertos UDP VPN
add action=drop chain=forward comment=\
    "Bloquear puertos de tunel VPN WARP UDP" dst-port=2408,500,1701,4500 \
    protocol=udp src-address-list=DNS-1113
# Bloqueo de puertos TCP VPN
add action=drop chain=forward comment=\
    "Bloquear puertos de tunel VPN WARP TCP" dst-port=\
    9000-9099,9600,9993,1984,9050,9051 protocol=tcp src-address-list=\
    DNS-1113
# Bloqueo de VPNs identificadas (IP/Dominio) para el grupo DNS-1113
add action=drop chain=forward comment="Block identified VPNs for dnsfamily" \
    dst-address-list=blocked-vpns src-address-list=DNS-1113
# Bloqueo de QUIC (UDP 443) para evitar bypass de DNS-1113
add action=reject chain=forward comment="Block QUIC UDP 443 for DNS-1113" \
    dst-port=443 protocol=udp reject-with=icmp-network-unreachable src-address-list=DNS-1113 place-before=[find comment="Block DNS over TLS (DoT) for Family"]

# -------------------------------------------------------------------------------
# GRUPO 2: CLOUDFLARE STANDARD DNS (1.1.1.1)
# Filtra malware pero no contenido para adultos.
/ip firewall nat
# Forzar DNS Estándar (1.1.1.1)
add chain=dstnat action=dst-nat to-addresses=1.1.1.1 to-ports=53 \
    protocol=udp src-address-list=DNS-1111 dst-address=!1.1.1.1 dst-port=53 \
    comment="Force Cloudflare DNS 1.1.1.1 (UDP)" place-before=0
add chain=dstnat action=dst-nat to-addresses=1.1.1.1 to-ports=53 \
    protocol=tcp src-address-list=DNS-1111 dst-address=!1.1.1.1 dst-port=53 \
    comment="Force Cloudflare DNS 1.1.1.1 (TCP)" place-before=0


# -------------------------------------------------------------------------------
# GRUPO 3: ADGUARD DEFAULT DNS (94.140.14.14)
# Filtra anuncios, trackers y malware.
# -------------------------------------------------------------------------------
/ip firewall nat
# Forzar AdGuard DNS (94.140.14.14)
add chain=dstnat action=dst-nat to-addresses=94.140.14.14 to-ports=53 \
    protocol=udp src-address-list=DNS-AdGuard dst-address=!94.140.14.14 dst-port=53 \
    comment="Force AdGuard DNS 94.140.14.14 (UDP)" place-before=0
add chain=dstnat action=dst-nat to-addresses=94.140.14.14 to-ports=53 \
    protocol=tcp src-address-list=DNS-AdGuard dst-address=!94.140.14.14 dst-port=53 \
    comment="Force AdGuard DNS 94.140.14.14 (TCP)" place-before=0

/ip firewall filter
# Bloqueo de DNS over TLS (DoT) en puerto 853 para AdGuard
add action=reject chain=forward comment="Block DNS over TLS (DoT) for AdGuard" \
    dst-port=853 protocol=tcp reject-with=tcp-reset src-address-list=\
    DNS-AdGuard

# ==============================================================================
# OPCIÓN ALTERNATIVA: CONFIGURACIÓN CON ALTA DISPONIBILIDAD (RECOMENDADA)
# ==============================================================================
# Esta implementación usa address-lists para definir los servidores DNS permitidos.
# Evita el bucle de redirección hacia el secundario si el primario falla,
# manteniendo la seguridad intacta ya que ambos servidores aplican los filtros.
#
# Para probar esta opción, primero debés comentar/deshabilitar las reglas de los 
# Grupos 1, 2 y 3 de arriba.

# 1. Definición de Servidores DNS Autorizados por Grupo
/ip firewall address-list
add address=1.1.1.3 list=Allowed-DNS-Family comment="Cloudflare Family Primary"
add address=1.0.0.3 list=Allowed-DNS-Family comment="Cloudflare Family Secondary"

add address=1.1.1.1 list=Allowed-DNS-Standard comment="Cloudflare Standard Primary"
add address=1.0.0.1 list=Allowed-DNS-Standard comment="Cloudflare Standard Secondary"

add address=94.140.14.14 list=Allowed-DNS-AdGuard comment="AdGuard DNS Primary"
add address=94.140.15.15 list=Allowed-DNS-AdGuard comment="AdGuard DNS Secondary"


# 2. Reglas de NAT con soporte de redundancia (dst-address-list=!)
/ip firewall nat

# Redirección Cloudflare Family
add chain=dstnat action=dst-nat to-addresses=1.1.1.3 to-ports=53 \
    protocol=udp src-address-list=DNS-1113 dst-address-list=!Allowed-DNS-Family dst-port=53 \
    comment="HA: Force Cloudflare Family DNS (UDP)" place-before=0
add chain=dstnat action=dst-nat to-addresses=1.1.1.3 to-ports=53 \
    protocol=tcp src-address-list=DNS-1113 dst-address-list=!Allowed-DNS-Family dst-port=53 \
    comment="HA: Force Cloudflare Family DNS (TCP)" place-before=0

# Redirección Cloudflare Standard
add chain=dstnat action=dst-nat to-addresses=1.1.1.1 to-ports=53 \
    protocol=udp src-address-list=DNS-1111 dst-address-list=!Allowed-DNS-Standard dst-port=53 \
    comment="HA: Force Cloudflare Standard DNS (UDP)" place-before=0
add chain=dstnat action=dst-nat to-addresses=1.1.1.1 to-ports=53 \
    protocol=tcp src-address-list=DNS-1111 dst-address-list=!Allowed-DNS-Standard dst-port=53 \
    comment="HA: Force Cloudflare Standard DNS (TCP)" place-before=0

# Redirección AdGuard Default
add chain=dstnat action=dst-nat to-addresses=94.140.14.14 to-ports=53 \
    protocol=udp src-address-list=DNS-AdGuard dst-address-list=!Allowed-DNS-AdGuard dst-port=53 \
    comment="HA: Force AdGuard DNS (UDP)" place-before=0
add chain=dstnat action=dst-nat to-addresses=94.140.14.14 to-ports=53 \
    protocol=tcp src-address-list=DNS-AdGuard dst-address-list=!Allowed-DNS-AdGuard dst-port=53 \
    comment="HA: Force AdGuard DNS (TCP)" place-before=0


# 3. Filtros de Seguridad (Bloqueo de DoT y bypasses)
/ip firewall filter

# Bloqueo DoT (Puerto 853) para todos los perfiles
add action=reject chain=forward comment="HA: Block DoT for DNS-1113" \
    dst-port=853 protocol=tcp reject-with=tcp-reset src-address-list=DNS-1113
add action=reject chain=forward comment="HA: Block DoT for DNS-1111" \
    dst-port=853 protocol=tcp reject-with=tcp-reset src-address-list=DNS-1111
add action=reject chain=forward comment="HA: Block DoT for DNS-AdGuard" \
    dst-port=853 protocol=tcp reject-with=tcp-reset src-address-list=DNS-AdGuard

# Bloqueo de puertos VPN (Solo aplicados al perfil restringido DNS-1113)
add action=drop chain=forward comment="HA: Block VPN UDP ports for Family" \
    dst-port=2408,500,1701,4500 protocol=udp src-address-list=DNS-1113
add action=drop chain=forward comment="HA: Block VPN TCP ports for Family" \
    dst-port=9000-9099,9600,9993,1984,9050,9051 protocol=tcp src-address-list=DNS-1113
add action=drop chain=forward comment="HA: Block identified VPNs for Family" \
    dst-address-list=blocked-vpns src-address-list=DNS-1113
