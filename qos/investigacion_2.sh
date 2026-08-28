# SQM 
# CAKE
/queue type
add name=cake-upload kind=cake cake-flowmode=dual-srchost cake-nat=yes cake-rtt-scheme=internet cake-diffserv=diffserv4 cake-ack-filter=filter
add name=cake-download kind=cake cake-flowmode=dual-dsthost cake-nat=yes cake-rtt-scheme=internet cake-diffserv=diffserv4
# cake-flowmode=dual-srchost/dsthost → Aísla flujos por IP de origen/destino, perfecto con NAT.
# cake-diffserv=diffserv4 → Prioriza VoIP, video, web sobre bulk (torrents).
# Crea las colas y asigna a interfaces
/queue tree
add name=sqm-cake-upload parent=ether1 queue=cake-upload max-limit=285M packet-mark=no-mark bucket-size=0.01
add name=sqm-cake-download parent=bridge queue=cake-download max-limit=285M packet-mark=no-mark bucket-size=0.01
# bucket-size=0.01 → Reduce el buffer interno, mejora la latencia bajo carga.
# Si tu enlace es asimétrico (ej. 300 down / 50 up), ajusta cada max-limit por separado: 
# max-limit=285M para bajada y max-limit=47M para subida.

# FQ-CoDel (opcional, para comparación)
/queue type
add name=fq-codel kind=fq-codel
/queue tree
add name=sqm-fq-codel-upload parent=ether1 queue=fq-codel max-limit=285M packet-mark=no-mark bucket-size=0.01
add name=sqm-fq-codel-download parent=bridge queue=fq-codel max-limit=285M packet-mark=no-mark bucket-size=0.01





# Aplica un límite con Mengle para marcar el tráfico que viene de Internet, y luego usa esa marca en el queue tree para aplicar CAKE solo a ese tráfico.
/ip firewall mangle
add chain=forward \
    dst-address=192.168.88.100 \
    action=mark-packet \
    new-packet-mark=dispositivo-limite \
    passthrough=no \
    comment="Marca bajada dispositivo"

/ip firewall mangle
add chain=forward \
    src-address=192.168.88.100 \
    action=mark-packet \
    new-packet-mark=dispositivo-limite \
    passthrough=no \
    comment="Marca subida dispositivo"

/queue tree
add name=limite-dispositivo-upload \
    parent=ether1 \
    packet-mark=dispositivo-limite \
    max-limit=20M
    
/queue tree
add name=limite-dispositivo-download \
    parent=bridge \
    packet-mark=dispositivo-limite \
    max-limit=20M






/queue type
add kind=cake name=cake-upload cake-bandwidth=XXM \
    cake-diffserv=diffserv4 \
    cake-flowmode=dual-srchost \
    cake-nat=yes

add kind=cake name=cake-download cake-bandwidth=YYM \
    cake-diffserv=besteffort \
    cake-flowmode=dual-dsthost \
    cake-nat=yes