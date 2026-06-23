############### Bloqueo de DNS over TLS (DoT) para la familia ############
# 1. Interceptar y redirigir consultas DNS tradicionales por UDP
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=1.1.1.3 to-ports=53 \
    protocol=udp src-address-list=dnsfamily dst-port=53 comment="Force Family DNS (UDP)"
# 2. Interceptar y redirigir consultas DNS tradicionales por TCP (usadas para respuestas largas)
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=1.1.1.3 to-ports=53 \
    protocol=tcp src-address-list=dnsfamily dst-port=53 comment="Force Family DNS (TCP)"
# 3. BLOQUEO CLAVE: Rechazar DNS over TLS (DoT - Puerto TCP 853)
/ip firewall filter add chain=forward action=reject reject-with=tcp-reset \
    protocol=tcp src-address-list=dnsfamily dst-port=853 comment="Block DNS over TLS (DoT) for Family"


############### Filtro CleanBrowsing ############
# 1. Interceptar y redirigir consultas DNS tradicionales por UDP
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=185.228.168.168 to-ports=53 \
    protocol=udp src-address-list=cleanbrowsing dst-port=53 comment="Force CleanBrowsing DNS (UDP)"
# 2. Interceptar y redirigir consultas DNS tradicionales por TCP (usadas para respuestas largas)
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=185.228.168.168 to-ports=53 \
    protocol=tcp src-address-list=cleanbrowsing dst-port=53 comment="Force CleanBrowsing DNS (TCP)"


############### Adguard Family ############
# 1. Interceptar y redirigir consultas DNS tradicionales por UDP
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=94.140.14.15 to-ports=53 \
    protocol=udp src-address-list=agfamily dst-port=53 comment="Force Adguard Family DNS (UDP)"
# 2. Interceptar y redirigir consultas DNS tradicionales por TCP (usadas para respuestas largas)
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=94.140.14.15 to-ports=53 \
    protocol=tcp src-address-list=agfamily dst-port=53 comment="Force Adguard Family DNS (TCP)"

### MIS list DNS ###
/ip firewall nat
add action=dst-nat chain=dstnat comment=dnsfamily-udp disabled=yes \
    dst-address=!1.1.1.3 dst-port=53 protocol=udp src-address-list=\
    dnsfamily-list to-addresses=1.1.1.3
add action=dst-nat chain=dstnat comment=dnsfamily-tcp disabled=yes \
    dst-address=!1.1.1.3 dst-port=53 protocol=tcp src-address-list=\
    dnsfamily-list to-addresses=1.1.1.3

### NEXTDNS
/ip firewall nat
add action=dst-nat chain=dstnat comment=nextdns-udp disabled=yes \
    dst-address=!45.90.28.42 dst-port=53 protocol=udp src-address-list=\
    nextdns to-addresses=45.90.28.42
add action=dst-nat chain=dstnat comment=nextdns-tcp disabled=yes \
    dst-address=!45.90.28.42 dst-port=53 protocol=tcp src-address-list=\
    nextdns to-addresses=45.90.28.42