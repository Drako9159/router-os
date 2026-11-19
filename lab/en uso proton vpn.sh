# Create the wireguard interface
/interface wireguard
add name=wg-proton-usfree35 \
    private-key="x" \
    comment="Proton VPN US-FREE-35"
# Add the Peer
/interface wireguard peers
add interface=wg-proton-usfree35 \
    public-key="x" \
    comment="Proton VPN US-FREE-35 Peer" \
    endpoint-address=84.20.27.33 \
    endpoint-port=51820 \
    allowed-address=0.0.0.0/0 \
    persistent-keepalive=25s

# Assign an IP Address to the interface
/ip address
add address=10.2.0.2/32 \
    interface=wg-proton-usfree35 \
    comment="IP Proton VPN US-FREE-35"

/routing table
add name=via-proton-usfree35 fib \
    comment="Routing table for Proton VPN US-FREE-35"

/ip route
add dst-address=0.0.0.0/0 \
    gateway=wg-proton-usfree35 \
    routing-table=via-proton-usfree35 \
    comment="Ruta por defecto hacia Proton VPN US-FREE-35"

/ip firewall nat
add chain=srcnat \
    out-interface=wg-proton-usfree35 \
    action=masquerade \
    comment="NAT Proton VPN US-FREE-35" \
    place-before=0

/ip firewall filter
add action=accept chain=forward \
    out-interface=wg-proton-usfree35 \
    comment="BYPASS FASTTRACKING VPN (Salida) wg-proton-usfree35" \
    place-before=[find where action=fasttrack-connection]
add action=accept chain=forward \
    in-interface=wg-proton-usfree35 \
    comment="BYPASS FASTTRACKING VPN (Retorno) wg-proton-usfree35" \
    place-before=[find where action=fasttrack-connection]

# Add Routetin rules
# Route traffic from specific hosts through the VPN
/routing rule 
add action=lookup-only-in-table \
    src-address=192.168.88.11/32 \
    table=via-proton-usfree35 \
    comment="Route client through Proton VPN US-FREE-35"

# Optionals
/ip firewall mangle
add action=change-mss chain=forward \
    comment="Clamp MSS to PMTU for Proton VPN US-FREE-35" \
    new-mss=clamp-to-pmtu \
    out-interface=wg-proton-usfree35 \
    protocol=tcp tcp-flags=syn

# Or add action=change-mss chain=forward new-mss=1380 out-interface=wg-proton-usfree35 protocol=tcp tcp-flags=syn tcp-mss=1381-65535













# --------------------------------------



# 5. NAT y Bypass FastTrack






# 7. MSS Clamping
