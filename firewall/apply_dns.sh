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


# 1. Definir la lista de servidores DoH/DoT comunes (IPs y FQDNs dinámicos)
/ip firewall address-list
# Cloudflare DNS
add list=doh-servers address=1.1.1.1 comment="Cloudflare Primary"
add list=doh-servers address=1.0.0.1 comment="Cloudflare Secondary"
add list=doh-servers address=1.1.1.2 comment="Cloudflare Security Primary"
add list=doh-servers address=1.0.0.2 comment="Cloudflare Security Secondary"
add list=doh-servers address=1.1.1.3 comment="Cloudflare Family Primary"
add list=doh-servers address=1.0.0.3 comment="Cloudflare Family Secondary"
add list=doh-servers address=cloudflare-dns.com comment="Cloudflare DoH Domain"
add list=doh-servers address=dns.cloudflare.com comment="Cloudflare DoH Domain"

# Google DNS
add list=doh-servers address=8.8.8.8 comment="Google Primary"
add list=doh-servers address=8.8.4.4 comment="Google Secondary"
add list=doh-servers address=dns.google comment="Google DoH Domain"

# Quad9
add list=doh-servers address=9.9.9.9 comment="Quad9 Secure Primary"
add list=doh-servers address=149.112.112.112 comment="Quad9 Secure Secondary"
add list=doh-servers address=dns.quad9.net comment="Quad9 DoH Domain"

# AdGuard Family & Standard DNS
add list=doh-servers address=94.140.14.14 comment="AdGuard Default Primary"
add list=doh-servers address=94.140.15.15 comment="AdGuard Default Secondary"
add list=doh-servers address=94.140.14.15 comment="AdGuard Family Primary"
add list=doh-servers address=94.140.15.16 comment="AdGuard Family Secondary"
add list=doh-servers address=dns.adguard-dns.com comment="AdGuard DoH Domain"

# CleanBrowsing
add list=doh-servers address=185.228.168.9 comment="CleanBrowsing Security Primary"
add list=doh-servers address=185.228.169.9 comment="CleanBrowsing Security Secondary"
add list=doh-servers address=185.228.168.168 comment="CleanBrowsing Family Primary"
add list=doh-servers address=185.228.169.168 comment="CleanBrowsing Family Secondary"

# 2. Bloqueo DoH (Puerto 443) para el grupo dnsfamily hacia la lista consolidada
/ip firewall filter
# Nota: El bloqueo de DoT general (puerto 853) para dnsfamily ya está activo arriba (líneas 31-33) sin restringir IP.
# Esta regla de abajo refuerza el bloqueo de DoH (puerto 443) hacia la lista consolidada doh-servers.
add chain=forward protocol=tcp dst-port=443 src-address-list=dnsfamily dst-address-list=doh-servers action=reject reject-with=tcp-reset comment="Block DoH to public resolvers for dnsfamily"


# ==============================================================================
# BLOQUEO DE VPNS IDENTIFICADAS
# ==============================================================================

# 1. Lista de IPs/Dominios de VPNs bloqueadas
/ip firewall address-list
add list=blocked-vpns address=95.173.217.225

# 2. Descartar todo el tráfico hacia las VPNs para el grupo dnsfamily
/ip firewall filter
add chain=forward action=drop src-address-list=dnsfamily dst-address-list=blocked-vpns \
    comment="Block identified VPNs for dnsfamily"

# ==============================================================================
# BLOQUEO DE PUERTOS DE VPN WARP
# ==============================================================================
/ip firewall filter
add chain=forward src-address-list=dnsfamily protocol=udp dst-port=2408,500,1701,4500 action=drop comment="Bloqueo de puertos VPN WARP para dnsfamily"

# ==============================================================================
# BLOQUEO DE TIKTOK POR RAW
# ==============================================================================

/ip firewall raw
add chain=prerouting src-address-list=dnsfamily protocol=tcp dst-port=443 tls-host="*tiktokv.com" action=add-dst-to-address-list address-list=tiktok-ips address-list-timeout=7d comment="Capturar IPs de TikTok para dnsfamily"
add chain=prerouting src-address-list=dnsfamily dst-address-list=tiktok-ips action=drop comment="Bloquear IPs de TikTok para dnsfamily"

/ip firewall raw
add chain=prerouting src-address-list=dnsfamily protocol=tcp dst-port=443 tls-host="*protonvpn*" action=add-dst-to-address-list address-list=blocked-vpns address-list-timeout=7d comment="Capturar IPs de ProtonVPN para dnsfamily"
add chain=prerouting src-address-list=dnsfamily protocol=tcp dst-port=443 tls-host="*proton.me*" action=add-dst-to-address-list address-list=blocked-vpns address-list-timeout=7d comment="Capturar API Proton para dnsfamily"

# ==============================================================================
# CAPTURA DE DOMINIOS DE VPNs Y SERVICIOS DE PROXY
# ==============================================================================

/ip dns static
add name="protonvpn.net" match-subdomain=yes type=FWD address-list=blocked-vpns comment="Capturar todos los nodos .net"

# ==============================================================================
# MAS BLOQUEO DE REDES SOCIALES (FACEBOOK, INSTAGRAM, TIKTOK)
# ==============================================================================

/ip firewall raw
# Facebook & Instagram CDN
add action=add-dst-to-address-list address-list=Bloqueo_Redes address-list-timeout=1d chain=prerouting dst-port=443 protocol=tcp tls-host=*facebook.com
add action=add-dst-to-address-list address-list=Bloqueo_Redes address-list-timeout=1d chain=prerouting dst-port=443 protocol=tcp tls-host=*fbcdn.net
add action=add-dst-to-address-list address-list=Bloqueo_Redes address-list-timeout=1d chain=prerouting dst-port=443 protocol=tcp tls-host=*instagram.com

# TikTok y servidores de contenido (ByteDance)
add action=add-dst-to-address-list address-list=Bloqueo_Redes address-list-timeout=1d chain=prerouting dst-port=443 protocol=tcp tls-host=*tiktok.com
add action=add-dst-to-address-list address-list=Bloqueo_Redes address-list-timeout=1d chain=prerouting dst-port=443 protocol=tcp tls-host=*tiktokcdn.com
add action=add-dst-to-address-list address-list=Bloqueo_Redes address-list-timeout=1d chain=prerouting dst-port=443 protocol=tcp tls-host=*byteoversea.com
add action=add-dst-to-address-list address-list=Bloqueo_Redes address-list-timeout=1d chain=prerouting dst-port=443 protocol=tcp tls-host=*ibytedtos.com