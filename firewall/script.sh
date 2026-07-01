# ==============================================================================
# MIKROTIK FIREWALL FILTER CONFIGURATION (SEGURIDAD Y CONTROL DE DISPOSITIVOS)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. BLOQUEO DE DISPOSITIVOS (DOS NIVELES DE RESTRICCIÓN)
# ------------------------------------------------------------------------------

# Nivel A: BLOQUEO TOTAL (Sin Internet y Sin Acceso Local a otras subredes/VLANs)
# Bloquea todo el tráfico en 'forward' originado por los dispositivos en esta lista.
# Útil para aislar por completo un dispositivo de cualquier otra subred interna.
/ip firewall filter add chain=forward action=drop src-address-list=dispositivos_aislados_total \
    comment="Bloqueo TOTAL: Sin acceso a internet ni a otras subredes locales"

# Nivel B: BLOQUEO DE INTERNET SOLAMENTE (Permite acceso a recursos locales en otras subredes)
# Solo bloquea si el destino final es la interfaz WAN. Permite imprimir o acceder a servidores locales.
/ip firewall filter add chain=forward action=drop src-address-list=dispositivos_sin_internet \
    out-interface-list=WAN \
    comment="Bloqueo parcial: Sin internet, pero con acceso a red local/inter-vlan"


# ------------------------------------------------------------------------------
# 2. REGLAS ADICIONALES DE SEGURIDAD (CADENA INPUT)
# ------------------------------------------------------------------------------

# Bloquear acceso de dispositivos aislados a la administración del propio Router
/ip firewall filter add chain=input action=drop src-address-list=dispositivos_aislados_total \
    comment="Bloquear acceso de dispositivos aislados a la administracion del Router"

# Bloquear intentos de fuerza bruta SSH / Winbox
/ip firewall filter add chain=input action=drop protocol=tcp dst-port=22,8291 \
    src-address-list=black_list \
    comment="Bloquear accesos de lista negra a puertos de administracion"