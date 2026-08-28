#### Configuración para ISP Orbith con modem en modo bridge y RouterOS v7 ####
### Primero deshabilita DHCP client ####
/ip dhcp-client disable [find interface=ether1]

### Luego asigna la IP pública a la interfaz ether1 ###
/ip address add address=172.16.7.168/12 interface=ether1 comment="IP Orbith Bridge"

### Añade la ruta por defecto para salir a Internet ###
/ip route add dst-address=0.0.0.0/0 gateway=172.16.0.1 comment="Ruta por defecto hacia Orbith"

### Asegura la salida a internet esté activa ###
/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade