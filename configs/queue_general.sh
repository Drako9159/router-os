# =====================================================================
# CONFIGURACIÓN GENERAL DE QOS (ROUTEROS V7)
# =====================================================================
# Este script define los Queue Types optimizados para CAKE y FQ-CoDel, 
# y la estructura del Queue Tree para el límite global de la red (720M).
# =====================================================================

# =====================================================================
# 1. DEFINICIÓN DE QUEUE TYPES (TIPOS DE COLA)
# =====================================================================
/queue type
# A. FQ-CoDel: Algoritmo alternativo liviano para bajo consumo de CPU
add kind=fq-codel name=fq-codel
# B. CAKE - General / Simple Queues: Optimizado para aislar hosts y flujos
add cake-nat=yes kind=cake name=cake-v7-default
# C. CAKE - Descarga Principal: Optimizado para la cola padre de bajada
add cake-flowmode=dual-dsthost cake-nat=yes kind=cake name=\
    cake-padre-download
# D. CAKE - Subida Principal: Optimizado para la cola padre de subida
add cake-ack-filter=filter cake-flowmode=dual-srchost cake-nat=yes kind=cake \
    name=cake-padre-upload
# E. CAKE - Gaming / Prioritario: Optimizado para juegos e interactivos
add cake-diffserv=diffserv4 cake-nat=yes kind=cake name=cake-diffserv4



# =====================================================================
# 2. QUEUE TREE PRINCIPAL (720M SIMÉTRICOS)
# =====================================================================
# NOTA: Para que estas colas padres apliquen control de latencia real
# a toda la red, se debe desactivar FastTrack (o hacerle bypass total).
# Si FastTrack sigue activo, estas colas solo verán tráfico residual.
# =====================================================================
/queue tree
# Cola de subida colgada del puerto WAN (ether1)
add max-limit=720M name=cake-v7-upload packet-mark=no-mark parent=ether1 \
    queue=cake-padre-upload
# Cola de bajada colgada del Bridge local
add max-limit=720M name=cake-v7-download packet-mark=no-mark parent=bridge \
    queue=cake-padre-download



