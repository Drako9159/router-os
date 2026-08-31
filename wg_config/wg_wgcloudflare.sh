# Configuration script for MikroTik RouterOS v7 (Corrected for Local LAN bypass)
# Based on hex_us-US-FREE-35.conf

# 1. Crear la interfaz WireGuard
/interface wireguard
add name=wg-cloudflare private-key="x" \
    comment="Cloudflare WARP Interface" mtu=1280 listen-port=13231

# 2. Configurar el Peer
/interface wireguard peers
add interface=wg-cloudflare public-key="x" \
    comment="Cloudflare WARP Peer" endpoint-address=162.159.193.10 endpoint-port=2408 allowed-address=0.0.0.0/0 persistent-keepalive=25s

# 3. Asignar la IP a la interfaz
/ip address
add address=172.16.0.2/32 interface=wg-cloudflare \
    comment="IP Cloudflare WARP"

# 4. Crear la tabla de ruteo para separar el tráfico
/routing table
add name=via-cloudflare fib

# 5. Crear la ruta por defecto en esa tabla nueva
/ip route
add dst-address=0.0.0.0/0 gateway=wg-cloudflare routing-table=via-cloudflare \
    comment="Ruta por defecto hacia Cloudflare"

# 6. Hacer NAT para salir por la VPN (Subirla a posición 0 para que sea la primera regla)
/ip firewall nat
add chain=srcnat out-interface=wg-cloudflare action=masquerade \
    comment="NAT Cloudflare" place-before=0

# 7. Crear Address List de Redes Locales (RFC1918)
/ip firewall address-list
add list=wgaddress-local address=192.168.0.0/16
add list=wgaddress-local address=10.0.0.0/8
add list=wgaddress-local address=172.16.0.0/12

# 8. Marcar el tráfico de los dispositivos elegidos (Mangle)
# IMPORTANTE: Excluimos wgaddress-local en dst-address-list para evitar bucles de DNS y pérdida de acceso local
/ip firewall mangle
add chain=prerouting src-address-list=WG-CLOUDFLARE dst-address-list=!wgaddress-local \
    action=mark-routing new-routing-mark=via-cloudflare passthrough=no \
    comment="Enviar a la VPN (excluyendo red local)"

# 9. Bypass FastTrack para el tráfico de la VPN
# Esto es necesario para que el tráfico de la VPN pueda ser controlado por las colas
/ip firewall filter
add action=accept chain=forward comment="BYPASS FASTTRACKING WGCLOUDFLARE" \
    src-address-list=WG-CLOUDFLARE place-before=[find where action=fasttrack-connection]
add action=accept chain=forward comment="BYPASS FASTTRACKING WG-CLOUDFLARE" \
    dst-address-list=WG-CLOUDFLARE place-before=[find where action=fasttrack-connection]

# /ip firewall filter
# add action=accept chain=input comment="Permitir Wireguard" dst-port=13231 protocol=udp place-before=1
# add action=accept chain=input comment="Permitir tráfico de Cloudflare WARP" src-address-list=WG-CLOUDFLARE place-before=1

# IMPORTANTE - EVITAR DNS LEAK / CDN MISMATCH:
# Si los clientes consultan al DNS local del router, el router resolverá la consulta
# usando su propio proceso local (cadena OUTPUT), saliendo por la WAN física. Esto
# provoca que CDNs (como Twitch o Netflix) devuelvan IPs optimizadas para la WAN
# real, pero el cliente intentará conectar a través de la VPN (cadena PREROUTING),
# resultando en bloqueos o problemas de carga.
# Estas reglas redireccionan el puerto 53 de los clientes para forzar que las consultas
# viajen a través del túnel hacia un DNS externo (1.1.1.1).
# Se excluye 'wgaddress-local' para no romper la resolución de nombres de la red local.

# Forzar DNS tradicional (UDP) a Cloudflare
/ip firewall nat
add chain=dstnat action=dst-nat to-addresses=1.1.1.1 to-ports=53 \
    protocol=udp src-address-list=WG-CLOUDFLARE dst-port=53 \
    comment="Force Cloudflare DNS (UDP)" place-before=0

# Forzar DNS tradicional (TCP) a Cloudflare
add chain=dstnat action=dst-nat to-addresses=1.1.1.1 to-ports=53 \
    protocol=tcp src-address-list=WG-CLOUDFLARE dst-port=53 \
    comment="Force Cloudflare DNS (TCP)" place-before=0
