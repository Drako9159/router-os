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
# F. CAKE - Onlyone: Optimizado para colas de un solo host (ej. limitadores)
add cake-diffserv=diffserv4 kind=cake name=cake-diffserv4 flow-mode=flows

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



# Experimental
/queue tree
# --- PADRES (Contabilidad HTB) ---
add comment="Experimental QoS - Padre Descarga" max-limit=720M name=TOTAL-DOWNLOAD parent=bridge
add comment="Experimental QoS - Padre Subida" max-limit=720M name=TOTAL-UPLOAD parent=ether1

# --- HIJAS: Tráfico principal / FastTrack (CAKE) ---
add comment="Experimental QoS" max-limit=720M name=CAKE-DOWNLOAD packet-mark=no-mark parent=TOTAL-DOWNLOAD queue=cake-padre-download
add comment="Experimental QoS" max-limit=720M name=CAKE-UPLOAD packet-mark=no-mark parent=TOTAL-UPLOAD queue=cake-padre-upload

# --- HIJAS: Limitadores temporales por Address-List (fq-codel) ---
add comment="Experimental QoS" max-limit=4M name=EXP-LMT4M-DOWNLOAD packet-mark=LMT4M-DOWNLOAD parent=TOTAL-DOWNLOAD queue=fq-codel
add comment="Experimental QoS" max-limit=4M name=EXP-LMT4M-UPLOAD packet-mark=LMT4M-UPLOAD parent=TOTAL-UPLOAD queue=fq-codel

add comment="Experimental QoS" max-limit=2M name=EXP-LMT2M-DOWNLOAD packet-mark=LMT2M-DOWNLOAD parent=TOTAL-DOWNLOAD queue=fq-codel
add comment="Experimental QoS" max-limit=2M name=EXP-LMT2M-UPLOAD packet-mark=LMT2M-UPLOAD parent=TOTAL-UPLOAD queue=fq-codel

add comment="Experimental QoS" max-limit=32k name=EXP-LMT32KB-DOWNLOAD packet-mark=LMT32KB-DOWNLOAD parent=TOTAL-DOWNLOAD queue=fq-codel
add comment="Experimental QoS" max-limit=32k name=EXP-LMT32KB-UPLOAD packet-mark=LMT32KB-UPLOAD parent=TOTAL-UPLOAD queue=fq-codel

