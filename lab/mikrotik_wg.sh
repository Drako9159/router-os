# ==============================================================================
# SCRIPT DE CONFIGURACIÓN DE WIREGUARD CLIENTE PARA MIKROTIK ROUTEROS V7
# Generado automáticamente a partir de zt.conf
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. INTERFAZ WIREGUARD
# Se crea la interfaz física/virtual de WireGuard con su MTU y clave privada.
# ------------------------------------------------------------------------------
/interface wireguard
add name=wg-client private-key="x" mtu=1280 comment="Cliente WireGuard VPN"

# ------------------------------------------------------------------------------
# 2. DIRECCIONAMIENTO IP
# Asigna la IP (o IPs) que te entregó el proveedor a la interfaz WireGuard.
# ------------------------------------------------------------------------------
/ip address
add address=172.16.0.2/32 interface=wg-client comment="IP Cliente WireGuard IPv4"

/ipv6 address
add address=2606:4700:cf1:1000::3/128 interface=wg-client advertise=no comment="IP Cliente WireGuard IPv6"

# ------------------------------------------------------------------------------
# 3. CONFIGURACIÓN DEL PEER (SERVIDOR)
# Conecta la interfaz al servidor remoto (Endpoint) usando su clave pública.
# AllowedIPs = 0.0.0.0/0 indica que permitimos ruterar cualquier destino por ahí.
# ------------------------------------------------------------------------------
/interface wireguard peers
add interface=wg-client public-key="x" endpoint-address=162.159.193.10 endpoint-port=2408 allowed-address=0.0.0.0/0,::/0 persistent-keepalive=25s comment="Peer WireGuard VPN"

# ------------------------------------------------------------------------------
# 4. ENRUTAMIENTO Y TABLAS DE RUTAS (PBR - Policy Based Routing)
# Para ruterar SOLO ALGUNOS clientes por la VPN, no podemos usar la tabla principal.
# Creamos una tabla de ruteo dedicada y agregamos la ruta por defecto ahí.
# ------------------------------------------------------------------------------
/routing table
add name=to-wg-vpn fib comment="Tabla de ruteo exclusiva para tráfico VPN"

/ip route
add dst-address=0.0.0.0/0 gateway=wg-client routing-table=to-wg-vpn comment="Ruta por defecto IPv4 VPN"

/ipv6 route
add dst-address=::/0 gateway=wg-client routing-table=to-wg-vpn comment="Ruta por defecto IPv6 VPN"

# ------------------------------------------------------------------------------
# 5. DIRECCIONES LOCALES EXCLUIDAS (BYPASS LAN)
# Para que los clientes de la VPN sigan accediendo a las impresoras y recursos locales,
# creamos una lista de redes locales para excluir del ruteo VPN.
# ------------------------------------------------------------------------------
/ip firewall address-list
add list=local-subnets address=192.168.0.0/16 comment="Subredes LAN RFC1918"
add list=local-subnets address=172.16.0.0/12 comment="Subredes LAN RFC1918"
add list=local-subnets address=10.0.0.0/8 comment="Subredes LAN RFC1918"

# ------------------------------------------------------------------------------
# 6. MARCAR TRÁFICO (MANGLE)
# Aquí ocurre la magia. Definimos la lista 'vpn-allowed-clients'.
# Cualquier paquete de un IP en esta lista, con destino EXTERNO (fuera de local-subnets),
# se le asignará la marca de ruteo para forzarlo a ir por la VPN.
# ------------------------------------------------------------------------------
/ip firewall mangle
add chain=prerouting src-address-list=vpn-allowed-clients dst-address-list=!local-subnets action=mark-routing new-routing-mark=to-wg-vpn passthrough=yes comment="Enrutar clientes permitidos a la VPN"

# ------------------------------------------------------------------------------
# 7. ENMASCARAMIENTO (NAT / MASQUERADE)
# Como las IPs de tu LAN son privadas y la VPN solo conoce la IP 172.16.0.2/32,
# hacemos NAT para traducir el origen del tráfico antes de enviarlo por el túnel.
# ------------------------------------------------------------------------------
/ip firewall nat
add chain=srcnat out-interface=wg-client action=masquerade comment="NAT para tráfico VPN IPv4"

/ipv6 firewall nat
add chain=srcnat out-interface=wg-client action=masquerade comment="NAT para tráfico VPN IPv6"

# ------------------------------------------------------------------------------
# 8. ADVERTENCIA IMPORTANTE: FASTTRACK BYPASS
# Si tenés FastTrack activo en tu Firewall (regla común en configuraciones por defecto),
# las conexiones establecidas van a saltarse el Mangle.
# Deberás deshabilitar FastTrack para las conexiones marcadas o agregar una regla
# de aceptación (accept) ANTES de la regla de FastTrack.
# Ejemplo para insertar arriba de FastTrack:
# /ip firewall filter add chain=forward action=accept connection-state=established,related routing-mark=to-wg-vpn place-before=[find where action=fasttrack-connection]
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# CÓMO AGREGAR UN CLIENTE A LA VPN:
# Ejecutá en la terminal de MikroTik o añadilo en IP -> Firewall -> Address Lists:
# /ip firewall address-list add list=vpn-allowed-clients address=192.168.88.50
# ------------------------------------------------------------------------------
