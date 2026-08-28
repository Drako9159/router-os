# Se cambió el ARP mode de Enable a reply-only para evitar que el router responda a ARP de dispositivos no deseados. Esto ayuda a prevenir ataques de ARP spoofing y mejora la seguridad de la red.
/interface bridge
add admin-mac=D0:EA:11:74:5A:F4 arp=reply-only auto-mac=no comment=defconf \
    name=bridge
# Se cambió el rango para empezar desde .128
/ip pool
add name=default-dhcp ranges=192.168.88.128-192.168.88.254
# Se activo el Add ARP Entries para que el router agregue automáticamente entradas ARP para los dispositivos que obtienen una dirección IP a través del DHCP. Esto mejora la eficiencia de la red y reduce la latencia.
/ip dhcp-server
add add-arp=yes add-dns-entries=yes address-pool=default-dhcp interface=\
    bridge lease-script="############### Alerta Telegram v5 (Multi-Lista con D"

# Se ajustó el cache DNS de 4096Kib a 10480Kib para mejorar el rendimiento de la resolución de nombres de dominio y reducir la latencia en la navegación web.
/ip dns
set allow-remote-requests=yes cache-size=10480KiB servers=\
    8.8.8.8,1.1.1.1,9.9.9.9 use-doh-server=\
    https://dns.cloudflare.com/dns-query verify-doh-cert=yes
### My default DoH
### https://dns.cloudflare.com/dns-query
### https://dns.google/dns-query


# Algunos servidores agregados para mejorar la resolución de nombres de dominio y proporcionar redundancia en caso de que un servidor falle.
/ip dns static
add address=8.8.8.8 comment="Para DoH" name=dns.google type=A
add address=8.8.4.4 comment="Para DoH" name=dns.google type=A
add address=1.1.1.1 name=cloudflare-dns.com type=A
add address=1.0.0.1 name=cloudflare-dns.com type=A
add address=1.1.1.1 name=dns.cloudflare.com type=A
add address=1.0.0.1 name=dns.cloudflare.com type=A


# Algunos filtros de bloqueo y filtrado especial
/ip firewall filter
# Bloqueo Total sin acceso a internet ni redes locales
add action=drop chain=forward comment=\
    "Bloqueo TOTAL: Sin acceso a internet ni a otras subredes locales" \
    src-address-list=BLACKLIST
# Bloqueo Solo hacía internet, con acceso a redes locales
add chain=forward action=drop src-address-list=blacklist \
    out-interface-list=WAN \
    comment="Bloqueo parcial: Sin internet, pero con acceso a red local/inter-vlan"
# Bloquear acceso de dispositivos aislados a la administración del propio Router
add chain=input action=drop src-address-list=blacklist \
    comment="Bloquear acceso de dispositivos aislados a la administracion del Router"
# Bloquear intentos de fuerza bruta SSH / Winbox
add chain=input action=drop protocol=tcp dst-port=22,8291 src-address-list=blacklist \
    comment="Bloquear accesos de lista negra a puertos de administracion"


### Regla general de bypass para evitar que el FastTrack afecte a los dispositivos de la lista NFAST, asegurando que el tráfico de estos dispositivos sea procesado normalmente por el firewall y las reglas de QoS.
/ip firewall filter
add action=accept chain=forward comment="BYPASS FASTTRACKING NFAST" \
    src-address-list=NFAST
add action=accept chain=forward comment="BYPASS FASTTRACKING NFAST" \
    dst-address-list=NFAST








