# Configuration script for MikroTik RouterOS v7 (WARP Dual-Stack IPv4/IPv6 Setup)
# Based on wg_config/zt.conf and wg_config/wireguard_config_wgcloudflare_mangle.sh

# 1. Crear la interfaz WireGuard con MTU 1280
/interface wireguard
add name=wg-cloudflare private-key="x" comment="Cloudflare WARP Interface" mtu=1280

# 2. Configurar el Peer (Incluye los Reserved Bytes de zt.conf indispensables para autenticar en WARP)
/interface wireguard peers
add interface=wg-cloudflare public-key="x" endpoint-address=162.159.193.10 endpoint-port=2408 allowed-address=0.0.0.0/0,::/0 persistent-keepalive=25s

# 3. Asignar las IPs (IPv4 e IPv6) a la interfaz WireGuard
/ip address
add address=172.16.0.2/32 interface=wg-cloudflare comment="IP IPv4 Cloudflare WARP"

/ipv6 address
add address=2606:4700:cf1:1000::3/128 interface=wg-cloudflare comment="IP IPv6 Cloudflare WARP"

# 4. Habilitar IPv6 Local en la LAN (Bridge) para los dispositivos
# Asigna un rango privado de IPv6 (ULA) a tu bridge para que los dispositivos obtengan IPv6 mediante SLAAC.
# (Ajustá "bridge" si el nombre de tu interfaz local es diferente, por ejemplo, "bridge-local")
/ipv6 address
add address=fd00:1234::1/64 interface=bridge advertise=yes comment="ULA IPv6 LAN Bridge"

# 5. Enrutamiento IPv6 Completo por la VPN
# Como WARP no cambia tu geolocalización (egresa en tu propio país), enrutar todo IPv6 por WARP es ideal
# y soluciona el bloqueo de Twitch sin romper nada.
/ipv6 route
add dst-address=::/0 gateway=wg-cloudflare comment="Ruta por defecto IPv6 via WARP"

# 6. NAT66 para que la LAN salga a internet por IPv6 usando la IP de WARP
/ipv6 firewall nat
add chain=srcnat out-interface=wg-cloudflare action=masquerade comment="NAT66 Cloudflare WARP"

# 7. Configuración IPv4 (Ruteo por Mangle según Address-List)
/routing table
add name=via-cloudflare fib

/ip route
add dst-address=0.0.0.0/0 gateway=wg-cloudflare routing-table=via-cloudflare comment="Ruta por defecto IPv4 via WARP"

/ip firewall nat
add chain=srcnat out-interface=wg-cloudflare action=masquerade comment="NAT IPv4 Cloudflare"

/ip firewall address-list
add list=redes_locales address=192.168.0.0/16
add list=redes_locales address=10.0.0.0/8
add list=redes_locales address=172.16.0.0/12

# 8. Bypass de FastTrack para evitar fugas (IPv4)
/ip firewall filter
add chain=forward action=accept connection-state=established,related src-address-list=wgcloudflare comment="Bypass FastTrack para VPN Cloudflare (Ida)" place-before=[find action=fasttrack-connection]
add chain=forward action=accept connection-state=established,related dst-address-list=wgcloudflare comment="Bypass FastTrack para VPN Cloudflare (Vuelta)" place-before=[find action=fasttrack-connection]

# 9. Reglas Mangle (Marcar ruta IPv4 y aplicar MSS Clamping)
/ip firewall mangle
add chain=prerouting src-address-list=wgcloudflare dst-address-list=!redes_locales action=mark-routing new-routing-mark=via-cloudflare passthrough=no comment="Enviar a la VPN (excluyendo red local)"
add chain=forward action=change-mss new-mss=clamp-to-pmtu protocol=tcp tcp-flags=syn out-interface=wg-cloudflare comment="MSS Clamping TCP para evitar fragmentación en IPv4"
