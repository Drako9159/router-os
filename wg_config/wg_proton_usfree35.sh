# Configuration script for MikroTik RouterOS v7 (Corrected for Local LAN bypass)
# Based on hex_us-US-FREE-35.conf

# 1. Crear la interfaz WireGuard
/interface wireguard
add name=wg-proton-usfree35 private-key="x" comment="Proton VPN US-FREE-35" mtu=1280

# 2. Configurar el Peer
/interface wireguard peers
add interface=wg-proton-usfree35 public-key="x" comment="Proton VPN US-FREE-35 Peer" endpoint-address=149.102.254.91 endpoint-port=51820 allowed-address=0.0.0.0/0 persistent-keepalive=25s

# 3. Asignar la IP a la interfaz
/ip address
add address=10.2.0.2/32 interface=wg-proton-usfree35 comment="IP Proton VPN US-FREE-35"

# 4. Crear la tabla de ruteo para separar el tráfico
/routing table
add name=via-proton-usfree35 fib

# 5. Crear la ruta por defecto en esa tabla nueva
/ip route
add dst-address=0.0.0.0/0 gateway=wg-proton-usfree35 routing-table=via-proton-usfree35 comment="Ruta por defecto hacia Proton VPN US-FREE-35"

# 6. Hacer NAT para salir por la VPN (Subirla a posición 0 para que sea la primera regla)
/ip firewall nat
add chain=srcnat out-interface=wg-proton-usfree35 action=masquerade comment="NAT Proton VPN US-FREE-35"

# 7. Crear Address List de Redes Locales (RFC1918)
/ip firewall address-list
add list=wgaddress-local address=192.168.0.0/16
add list=wgaddress-local address=10.0.0.0/8
add list=wgaddress-local address=172.16.0.0/12

# 8. Marcar el tráfico de los dispositivos elegidos (Mangle)
# IMPORTANTE: Excluimos wgaddress-local en dst-address-list para evitar bucles de DNS y pérdida de acceso local
/ip firewall mangle
add chain=prerouting src-address-list=wgproton-usfree35 dst-address-list=!wgaddress-local action=mark-routing new-routing-mark=via-proton-usfree35 passthrough=no comment="Enviar a la VPN (excluyendo red local)"

# Forzar DNS tradicional (UDP) a Proton VPN
/ip firewall nat
add chain=dstnat action=dst-nat to-addresses=8.8.8.8 to-ports=53 \
    protocol=udp src-address-list=wgproton-usfree35 dst-port=53 \
    comment="Force Proton VPN US-FREE-35 DNS (UDP)" place-before=0

# Forzar DNS tradicional (TCP) a Proton VPN
add chain=dstnat action=dst-nat to-addresses=8.8.8.8 to-ports=53 \
    protocol=tcp src-address-list=wgproton-usfree35 dst-port=53 \
    comment="Force Proton VPN US-FREE-35 DNS (TCP)" place-before=0




