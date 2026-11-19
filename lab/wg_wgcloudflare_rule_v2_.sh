# Configuration script for MikroTik RouterOS v7 (Using Routing Rules)
# Based on wg_wgcloudflare.sh, optimized for performance without Mangle

# 1. Crear la interfaz WireGuard
/interface wireguard
add name=wg-cloudflare-lastversion \
    private-key="x" \
    comment="Cloudflare WARP Interface Last Version"

# 2. Configurar el Peer
/interface wireguard peers
add interface=wg-cloudflare-lastversion \
    public-key="x" \
    comment="Cloudflare WARP Peer Last Version" \
    endpoint-address=engage.cloudflareclient.com \
    endpoint-port=2408 \
    allowed-address=0.0.0.0/0

# 3. Asignar la IP a la interfaz
/ip address
add address=172.16.0.2/32 \
    interface=wg-cloudflare-lastversion \
    comment="IP Cloudflare WARP Last Version"

# 4. Crear la tabla de ruteo para separar el tráfico
/routing table
add name=via-cloudflare-lastversion fib \
    comment="Tabla de ruteo para Cloudflare WARP Last Version"

# 5. Crear la ruta por defecto en esa tabla nueva
/ip route
add dst-address=0.0.0.0/0 \
    gateway=wg-cloudflare-lastversion \
    routing-table=via-cloudflare-lastversion \
    comment="Ruta por defecto hacia Cloudflare Last Version"

# 6. Hacer NAT para salir por la VPN (Subirla a posición 0 para que sea la primera regla)
# /ip firewall nat
# add chain=srcnat out-interface=wg-cloudflare-lastversion action=src-nat to-addresses=172.16.0.2 \
#     comment="NAT Cloudflare" place-before=0
/ip firewall nat
add chain=srcnat \
    out-interface=wg-cloudflare-lastversion \
    action=masquerade \
    comment="NAT Cloudflare Last Version" \
    place-before=0

# 7. Reglas de Ruteo (Routing Rules) - Bypass de redes locales (RFC1918)
# Estas reglas aseguran que el tráfico hacia la red local no se envíe por la VPN
/routing rule
# add dst-address=192.168.0.0/16 action=lookup table=main comment="Bypass Local LAN"
# add dst-address=10.0.0.0/8 action=lookup table=main comment="Bypass Local LAN"
# add dst-address=172.16.0.0/12 action=lookup table=main comment="Bypass Local LAN"

# EJEMPLO: Para enviar un cliente a la VPN, descomentar y adaptar la siguiente regla:
# /routing rule
add action=lookup-only-in-table \
    src-address=192.168.88.11/32 \
    table=via-cloudflare-lastversion \
    comment="Route client through Cloudflare VPN Realme GT2 Pro Last Version"

# 8. Bypass FastTrack para los clientes de la VPN
# Es necesario evitar que el tráfico de la VPN sea fasttrackeado para que las reglas de ruteo apliquen
# /ip firewall filter
# add action=accept chain=forward comment="BYPASS FASTTRACKING WGCLOUDFLARE" \
#     src-address-list=WG-CLOUDFLARE place-before=[find where action=fasttrack-connection]
# add action=accept chain=forward comment="BYPASS FASTTRACKING WG-CLOUDFLARE" \
#     dst-address-list=WG-CLOUDFLARE place-before=[find where action=fasttrack-connection]

/ip firewall filter
add action=accept chain=forward \
    out-interface=wg-cloudflare-lastversion \
    comment="BYPASS FASTTRACKING VPN (Salida) wg-cloudflare-lastversion" \
    place-before=[find where action=fasttrack-connection]
add action=accept chain=forward \
    in-interface=wg-cloudflare-lastversion \
    comment="BYPASS FASTTRACKING VPN (Retorno) wg-cloudflare-lastversion" \
    place-before=[find where action=fasttrack-connection]

# 9. Forzar DNS tradicional (UDP/TCP) a Cloudflare
/ip firewall nat
add chain=dstnat action=dst-nat to-addresses=1.1.1.1 to-ports=53 \
    protocol=udp src-address-list=WG-CLOUDFLARE dst-address-list=!wgaddress-local dst-port=53 \
    comment="Force Cloudflare DNS (UDP)" place-before=0
add chain=dstnat action=dst-nat to-addresses=1.1.1.1 to-ports=53 \
    protocol=tcp src-address-list=WG-CLOUDFLARE dst-address-list=!wgaddress-local dst-port=53 \
    comment="Force Cloudflare DNS (TCP)" place-before=0

# 10. MSS Clamping para evitar fragmentación de paquetes TCP
#/ip firewall mangle
#add action=change-mss \
#    chain=forward \
#    new-mss=clamp-to-pmtu \
#    passthrough=yes \
#    protocol=tcp tcp-flags=syn \
#    out-interface=wg-cloudflare \
#    comment="Clamp MSS for wg-cloudflare"

/ip firewall mangle
add action=change-mss \
    chain=forward \
    comment="Clamp MSS to PMTU for Cloudflare VPN Last Version" \
    new-mss=clamp-to-pmtu \
    out-interface=wg-cloudflare-lastversion \
    protocol=tcp tcp-flags=syn














