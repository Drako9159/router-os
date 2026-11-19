# Configuration script for MikroTik RouterOS v7 (Using Routing Rules)

# 1. Crear la interfaz WireGuard
/interface wireguard
add name=WG-WARP \
    private-key="x"

# 2. Configurar el Peer
/interface wireguard peers
add interface=WG-WARP \
    name=WARP \
    public-key="x" \
    endpoint-address=engage.cloudflareclient.com \
    endpoint-port=2408 \
    allowed-address=0.0.0.0/0,::/0 \
    persistent-keepalive=25s

# 3. Asignar la IP a la interfaz # Newtwork son los DNS
/ip address
add address=172.16.0.2/32 \
    network=172.16.0.1 \
    interface=WG-WARP \
    comment="IP WARP VPN"


# 4. Crear la tabla de ruteo para separar el tráfico
/routing table
add name=WARP-CLOUDFLARE fib

# 5. Crear la ruta por defecto en esa tabla nueva
/ip route
add dst-address=0.0.0.0/0 \
    gateway=WG-WARP \
    routing-table=WARP-CLOUDFLARE

# /ip firewall address-list
# add address=192.168.88.10 list=WARP

# /ip firewall address-list
# add address=192.168.88.0/24 list=RedesLAN

/ip firewall mangle 
add action=mark-routing \
    chain=prerouting \
    src-address-list=WARP \
    new-routing-mark=WARP-CLOUDFLARE \
    dst-address-list=!RedesLAN \
    passthrough=no

/ip firewall nat
add chain=srcnat \
    out-interface=WG-WARP \
    action=masquerade \
    comment="NAT WARP VPN" \
    place-before=0


/ip firewall filter
add action=accept chain=forward \
    out-interface=WG-WARP \
    comment="BYPASS FASTTRACKING VPN (Salida) WG-WARP" \
    place-before=[find where action=fasttrack-connection]
add action=accept chain=forward \
    in-interface=WG-WARP \
    comment="BYPASS FASTTRACKING VPN (Retorno) WG-WARP" \
    place-before=[find where action=fasttrack-connection]

# Mover a posición 0
/ip firewall mangle
add action=change-mss chain=forward out-interface=WG-WARP new-mss=clamp-to-pmtu passthrough=yes protocol=tcp tcp-flags=syn comment="MSS Clamp WARP"


















