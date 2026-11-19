# Configuration script for MikroTik RouterOS v7 (Connection Marking method - Optimized)
# This version uses connection marking to route selected LAN clients through WireGuard,
# optimized for CPU efficiency and robust FastTrack bypass.

# 1. Crear la interfaz WireGuard
/interface wireguard
add name=wg-cloudflare private-key="x" \
    comment="Cloudflare WARP Interface"

# 2. Configurar el Peer
/interface wireguard peers
add interface=wg-cloudflare public-key="x" \
    comment="Cloudflare WARP Peer" endpoint-address=162.159.193.10 endpoint-port=2408 \
    allowed-address=0.0.0.0/0 persistent-keepalive=25s

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

# 8. Marcar la CONEXIÓN y el RUTEO (Mangle Optimizado)
/ip firewall mangle
# Regla 1: Marcamos la conexión completa SOLO para el primer paquete de conexiones nuevas externas
add chain=prerouting src-address-list=WG-CLOUDFLARE dst-address-list=!wgaddress-local \
    connection-mark=no-mark action=mark-connection new-connection-mark=conn-wg-vpn passthrough=yes \
    comment="Marcar conexion de la VPN (Solo primer paquete)"

# Regla 2: Aplicamos la marca de ruteo usando un chequeo de interfaz de entrada LAN (Ultra liviano)
add chain=prerouting connection-mark=conn-wg-vpn in-interface-list=LAN \
    action=mark-routing new-routing-mark=via-cloudflare passthrough=no \
    comment="Marcar ruteo para la VPN (Solo ida LAN)"

# 9. Bypass FastTrack para el tráfico de la VPN (Basado en Interfaz - Recomendado)
# Esto desacopla el bypass del Mangle y asegura que todo tráfico por la interfaz no se rompa por FastTrack.
/ip firewall filter
add action=accept chain=forward out-interface=wg-cloudflare comment="BYPASS FASTTRACKING VPN (Salida) wg-cloudflare" \
    place-before=[find where action=fasttrack-connection]
add action=accept chain=forward in-interface=wg-cloudflare comment="BYPASS FASTTRACKING VPN (Retorno) wg-cloudflare" \
    place-before=[find where action=fasttrack-connection]

# 10. EVITAR DNS LEAK / CDN MISMATCH
# Redireccionamos las consultas DNS de los clientes hacia un DNS público a través de la VPN.
/ip firewall nat
add chain=dstnat action=dst-nat to-addresses=1.1.1.1 to-ports=53 \
    protocol=udp src-address-list=WG-CLOUDFLARE dst-address-list=!wgaddress-local dst-port=53 \
    comment="Force Cloudflare DNS (UDP)" place-before=0
add chain=dstnat action=dst-nat to-addresses=1.1.1.1 to-ports=53 \
    protocol=tcp src-address-list=WG-CLOUDFLARE dst-address-list=!wgaddress-local dst-port=53 \
    comment="Force Cloudflare DNS (TCP)" place-before=0
