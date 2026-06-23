
# Regla para bloquear el acceso local a otro dispositivo específico (por ejemplo, una Smart TV) en la red local
/ip firewall filter
add chain=forward action=drop src-address=192.168.88.0/24 dst-address=192.168.88.50 comment="Bloquear acceso local HACIA otro dispositivo"

# Regla para bloquear el acceso a internet a un dispositvo o lista
/ip firewall filter
add chain=forward action=drop src-address-list=dispositivos_bloqueados comment="Bloquear acceso a internet a dispositivos"