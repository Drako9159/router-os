# Configuration script for MikroTik RouterOS v7 with Kill Switch
# Prevents traffic leaks to the normal WAN if the VPN connection drops.

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

# 7. Crear Address List de Redes Locales
/ip firewall address-list
add list=redes_locales address=192.168.0.0/16
add list=redes_locales address=10.0.0.0/8
add list=redes_locales address=172.16.0.0/12

# 8. Marcar el tráfico de los dispositivos elegidos (Mangle)
/ip firewall mangle
add chain=prerouting src-address-list=dispositivos_vpn dst-address-list=!redes_locales action=mark-routing new-routing-mark=to-vpn passthrough=no comment="Enviar a la VPN (excluyendo red local)"

# 9. CONFIGURACIÓN DEL KILL SWITCH (RouterOS v7 Routing Rule)
# Esto obliga al router a buscar ruta EXCLUSIVAMENTE en la tabla 'to-vpn'.
# Si la interfaz wg-vpn se cae y la ruta desaparece, el tráfico se dropea en lugar de salir por la WAN principal.
/routing rule
add routing-mark=to-vpn action=lookup-only-in-table table=to-vpn comment="Kill Switch para tráfico marcado hacia VPN"
