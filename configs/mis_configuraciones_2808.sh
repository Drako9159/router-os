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

### Cloudflare (Estándar) https://cloudflare-dns.com/dns-query
### Cloudflare (Seguridad) https://security.cloudflare-dns.com/dns-query
### Google (Estándar) https://dns.google/dns-query
### Quad (Privadidad) https://dns.quad9.net/dns-query
### Adguard (Adblock) https://dns.adguard-dns.com/dns-query
### Mullvad (Adblock, Privacidad) https://adblock.doh.mullvad.net/dns-query
### ControlD (Adblock, Malware) https://freedns.controld.com/p2
### NextDNS (Personalizado) https://dns.nextdns.io/ID-DE-TU-PERFIL

### Cambios en DoH configuraciones
### DoH Max Server Connections de 5 a 20
### DoH Max Concurrent Queries de 50 a 100
### DoH Timeout de 5.000 a 10.000


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

# ----------------- 
# Se activó un cliente de NTP para tener la hora correcta en el router y sincronizarla con servidores de tiempo confiables. Esto es importante para la seguridad y el registro de eventos en el sistema.
/system ntp client
set enabled=yes servers=time.google.com,time.cloudflare.com

# Se activó NTP Server para que el router pueda actuar como servidor de tiempo para otros dispositivos en la red local, proporcionando una fuente confiable de sincronización horaria.
/system ntp server
set enabled=yes # Marca la casilla Use Local Clock para que el servidor NTP utilice la hora local del router como referencia para sincronizar otros dispositivos en la red.

# Activa el NTP Server en el Servidor DHCP en IP > DHCP Server > Network > NTP Server, 192.168.88.1 para que los clientes DHCP reciban automáticamente la dirección del servidor NTP y puedan sincronizar su hora correctamente.

# Desactiva el SMB para que no se active por defecto
/ip smb set enabled=no
# En Disks > Settings > Auto SMB Share > Disable, para que no se comparta automáticamente el contenido de los discos conectados al router a través del protocolo SMB, mejorando la seguridad y evitando accesos no autorizados.
/disks settings set auto-smb-share=no
/disks settings set auto-media-share=no


# Desactivé algunos servicios como
# www-ssl, telnet, ftp, ssh, api-ssl y api para mejorar la seguridad del router y reducir la superficie de ataque, limitando los servicios expuestos a la red.



# Creando una nueva subred para separar clientes
/ip address
add address=192.168.77.1/24 interface=bridge network=192.168.77.0 comment="RED CONFIABLES"
# Se crea la subred para el DHCP sever
/ip dhcp-server network
add address=192.168.77.0/24 gateway=192.168.77.1 dns-server=192.168.77.1 comment="NETWORK CONFIABLES"
# Estableciendo un lease para el dispositivo de la subred confiable
/ip dhcp-server lease
set [find mac-address="XX:XX:XX:XX:XX:XX"] address=192.168.77.20

# Sub red para clientes cancelados
/ip address
add address=192.168.33.1/24 interface=bridge network=192.168.33.0 comment="RED CANCELADOS"
/ip dhcp-server network
add address=192.168.33.0/24 gateway=192.168.33.1 dns-server=192.168.33.1 comment="NETWORK CANCELADOS"


/ip firewall filter
# 1. Bloquear que la red .33 acceda a las interfaces de administración del MikroTik
add chain=input src-address=192.168.33.0/24 dst-port=8291,80,443,22 protocol=tcp action=drop comment="Drop Admin Access from Honey"
# 2. Bloquear que la red .33 intente alcanzar a tus equipos confiables o locales
add chain=forward src-address=192.168.33.0/24 dst-address=192.168.0.0/16 action=drop comment="Isolate Honey subnet from LAN"


# ----------------- Container ----------------- # 

# Habilite el uso de contenedores
/system device-mode update container=no
# Habilite el paquete de contenedores
/system package enable container
# Instale un disco para los contenedores
# Farmatear disco: check MBR Partition Table, File System: ext4
# La particion que usamos es la usb1-part1

# Cramos una interface virtual para los contenedores
/interface veth add name=veth1 address=172.17.0.2/24 gateway=172.17.0.1
# Creamos un nuevo bridge para docker
/interface bridge add name=containers
# Ahora agregamos los puertos al bridge
/interface bridge port add bridge=containers interface=veth1
# Creamos una address para el bridge-docker
/ip address add address=172.17.0.1/24 interface=containers comment="Containers"

# Regla para el tráfico saliente de lcontainer
/ip firewall nat add chain=srcnat action=masquerade src-address=172.17.0.0/24 comment="NAT para contenedores"

# Apunta a registry para obtener imágenes de contenedores
/container config set registry-url=https://registry-1.docker.io tmpdir=usb1-part1/tmp

/container add remote-image=pihole/pihole interface=veth1 root-dir=usb1-part1/images/pihole name=pihole logging=yes

# Creamos mounts para cada contenedor especial
# En la pestaña Mounts de containers crear uno con dst=/opt/adguardhome/work src=/usb1-part1/adguardhome/work name=AdguardHomeWork
# Ahora otro para conf dst=/opt/adguardhome/conf src=/usb1-part1/adguardhome/conf name=AdguardHomeConf

# -------- SMB Storage ---------------- #
# List disks
/disk print
# Formatear disco para smb
/disk format usb1 file-system=fat32
# Crear un usuario administrado para montar la carpeta en los dispositivos
/ip smb users
add name=nio password=chocheman read-only=no
# Definir carpeta compartida
/ip smb shares
add name=shared directory=usb1 read-only=no \
    comment="Carpeta compartida para la red local" \
    require-encryption=yes valid-users=nio
# Habilitar el servicio SMB
/ip smb set enabled=yes comment="Servidor SMB Local" domain=WORKGROUP
# Verificar el servicio levantado
/ip smb print

# Esto es para añadir un almacenamiento remoto y ponerlo como SMB, no es necesario para el funcionamiento del router, pero puede ser útil para compartir archivos en la red local.
/disk
add type=smb slot=shared smb-address=192.168.88.1 smb-share=myshare smb-user=nio smb-password=chocheman