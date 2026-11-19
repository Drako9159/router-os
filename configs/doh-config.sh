### Configuración de DNS sobre HTTPS (DoH) en MikroTik RouterOS
### Obtener los certificados de CA para validar el servidor DoH
/tool fetch url=https://curl.se/ca/cacert.pem
### Importar el certificado de CA en el router
/certificate import file-name=cacert.pem
### Retirar los SERVER DNS actual para evitar conflictos
/ip dns set servers=
### Añadir estaticos para inicializar la resolución de nombres de dominio y evitar problemas de DNS Leak
/ip dns static add name=dns.nextdns.io address=45.90.28.0 type=A
/ip dns static add name=dns.nextdns.io address=45.90.30.0 type=A
/ip dns static add name=dns.nextdns.io address=2a07:a8c0:: type=AAAA
/ip dns static add name=dns.nextdns.io address=2a07:a8c1:: type=AAAA
### Establecer el servidor DoH y habilitar la verificación del certificado
/ip dns set use-doh-server=“https://dns.nextdns.io/fe4232” verify-doh-cert=yes
### Marcar permitir solicitudes remotas
### Evitar que el router haga consultas DNS a través de la WAN física, lo que podría causar problemas de DNS Leak y CDN Mismatch
/ip dns set allow-remote-requests=yes
/ip firewall nat add chain=dstnat action=redirect protocol=tcp dst-port=53 
/ip firewall nat add chain=dstnat action=redirect protocol=udp dst-port=53 