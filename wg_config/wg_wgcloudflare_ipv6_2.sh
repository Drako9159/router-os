# Configuration script for MikroTik RouterOS v7 (WARP Dual-Stack Setup with Mangle)
# Based on zt.conf and wireguard_config_wgcloudflare_mangle.sh

# 1. Crear la interfaz WireGuard
/interface wireguard
add name=wg-cloudflare private-key="x" comment="Cloudflare WARP Interface" mtu=1280

# 2. Configurar el Peer (con AllowedIPs e ID reservado para WARP)
/interface wireguard peers
add interface=wg-cloudflare public-key="x" endpoint-address=162.159.193.10 endpoint-port=2408 allowed-address=0.0.0.0/0,::/0 persistent-keepalive=25s

# 3. Asignar las IPs (IPv4 y IPv6) a la interfaz
/ip address
add address=172.16.0.2/32 interface=wg-cloudflare comment="IP IPv4 Cloudflare WARP"

/ipv6 address
add address=2606:4700:cf1:1000::3/128 interface=wg-cloudflare comment="IP IPv6 Cloudflare WARP" advertise=no

# 4. Crear la tabla de ruteo para separar el tráfico (compartida para IPv4 e IPv6 en v7)
/routing table
add name=via-cloudflare fib

# 5. Crear las rutas por defecto en esa tabla nueva
/ip route
add dst-address=0.0.0.0/0 gateway=wg-cloudflare routing-table=via-cloudflare comment="Ruta por defecto IPv4 hacia Cloudflare"

/ipv6 route
add dst-address=::/0 gateway=wg-cloudflare routing-table=via-cloudflare comment="Ruta por defecto IPv6 hacia Cloudflare"

# 6. Hacer NAT para salir por la VPN (IPv4 y IPv6)
/ip firewall nat
add chain=srcnat out-interface=wg-cloudflare action=masquerade comment="NAT IPv4 Cloudflare"

/ipv6 firewall nat
add chain=srcnat out-interface=wg-cloudflare action=masquerade comment="NAT IPv6 Cloudflare"

# 7. Crear Address List de Redes Locales (Bypass de VPN para recursos locales)
/ip firewall address-list
add list=redes_locales address=192.168.0.0/16
add list=redes_locales address=10.0.0.0/8
add list=redes_locales address=172.16.0.0/12

/ipv6 firewall address-list
add list=redes_locales address=fe80::/10 comment="Link-Local"
add list=redes_locales address=fc00::/7 comment="ULA (Unique Local Address)"

# 8. Marcar el tráfico de los dispositivos elegidos (Mangle IPv4 e IPv6)
# IMPORTANTE: Excluimos redes_locales en dst-address-list para evitar bucles y pérdida de acceso local
/ip firewall mangle
add chain=prerouting src-address-list=wgcloudflare dst-address-list=!redes_locales action=mark-routing new-routing-mark=via-cloudflare passthrough=no comment="Enviar IPv4 a la VPN (excluyendo red local)"

/ipv6 firewall mangle
add chain=prerouting src-address-list=wgcloudflare dst-address-list=!redes_locales action=mark-routing new-routing-mark=via-cloudflare passthrough=no comment="Enviar IPv6 a la VPN (excluyendo red local)"
