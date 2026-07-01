# Configuration script for MikroTik RouterOS v7 - Domain-based Routing
# Routes traffic to specific websites (like Netflix, YouTube, etc.) through the VPN.

# 1. Crear la interfaz WireGuard (si no existe)
/interface wireguard
add name=wg-vpn private-key="x" listen-port=13231

# 2. Configurar el Peer
/interface wireguard peers
add interface=wg-vpn public-key="x" endpoint-address=149.102.254.91 endpoint-port=51820 allowed-address=0.0.0.0/0 persistent-keepalive=25s

# 3. Asignar la IP a la interfaz
/ip address
add address=10.2.0.2/32 interface=wg-vpn

# 4. Crear la tabla de ruteo
/routing table
add name=to-vpn fib

# 5. Crear la ruta por defecto en esa tabla nueva
/ip route
add dst-address=0.0.0.0/0 gateway=wg-vpn routing-table=to-vpn

# 6. Hacer NAT para salir por la VPN
/ip firewall nat
add chain=srcnat out-interface=wg-vpn action=masquerade comment="NAT para VPN"

# 7. Crear Address List de Redes Locales (para exclusión)
/ip firewall address-list
add list=redes_locales address=192.168.0.0/16
add list=redes_locales address=10.0.0.0/8
add list=redes_locales address=172.16.0.0/12

# 8. Agregar dominios a la Address List
# MikroTik resolverá estos dominios automáticamente y mantendrá las IPs actualizadas con el TTL del DNS.
/ip firewall address-list
add list=sitios_vpn address=netflix.com comment="Netflix"
add list=sitios_vpn address=fast.com comment="Fast Speed Test"
add list=sitios_vpn address=icanhazip.com comment="Test IP check"

# 9. Marcar el tráfico basado en el DESTINO (Mangle)
# Cualquier dispositivo de la red que vaya a esos sitios web saldrá por la VPN.
/ip firewall mangle
add chain=prerouting dst-address-list=sitios_vpn dst-address-list=!redes_locales action=mark-routing new-routing-mark=to-vpn passthrough=no comment="Rutar sitios_vpn por la VPN"
