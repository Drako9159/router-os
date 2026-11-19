# Configuration script for MikroTik RouterOS v7 (Using Routing Rules)

# 1. Crear la interfaz WireGuard
/interface wireguard
add name=WG-PROTON-USA \
    private-key="x"

# 2. Configurar el Peer
/interface wireguard peers
add interface=WG-PROTON-USA \
    name=PROTON-USA \
    public-key="x" \
    endpoint-address=194.180.33.4 \
    endpoint-port=51820 \
    allowed-address=0.0.0.0/0,::/0 \
    persistent-keepalive=25s

# 3. Asignar la IP a la interfaz # Newtwork son los DNS
/ip address
add address=10.2.0.2/32 \
    network=10.2.0.1 \
    interface=WG-PROTON-USA \
    comment="IP Proton VPN"


# 4. Crear la tabla de ruteo para separar el tráfico
/routing table
add name=PROTON-USA fib

# 5. Crear la ruta por defecto en esa tabla nueva
/ip route
add dst-address=0.0.0.0/0 \
    gateway=WG-PROTON-USA \
    routing-table=PROTON-USA

# /ip firewall address-list
# add address=192.168.88.10 list=VPN-PROTON-USA

# /ip firewall address-list
# add address=192.168.88.0/24 list=RedesLAN

/ip firewall mangle 
add action=mark-routing \
    chain=prerouting \
    src-address-list=VPN-PROTON-USA \
    new-routing-mark=PROTON-USA \
    dst-address-list=!RedesLAN \
    passthrough=no

/ip firewall nat
add chain=srcnat \
    out-interface=WG-PROTON-USA \
    action=masquerade \
    comment="NAT Proton VPN" \
    place-before=0


/ip firewall filter
add action=accept chain=forward \
    out-interface=WG-PROTON-USA \
    comment="BYPASS FASTTRACKING VPN (Salida) WG-PROTON-USA" \
    place-before=[find where action=fasttrack-connection]
add action=accept chain=forward \
    in-interface=WG-PROTON-USA \
    comment="BYPASS FASTTRACKING VPN (Retorno) WG-PROTON-USA" \
    place-before=[find where action=fasttrack-connection]

# Mover a posición 0
/ip firewall mangle
add action=change-mss chain=forward out-interface=WG-PROTON-USA new-mss=clamp-to-pmtu passthrough=yes protocol=tcp tcp-flags=syn comment="MSS Clamp Proton USA"



















