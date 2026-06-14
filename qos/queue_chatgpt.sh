
######################################
### SQM generado por ChatGPT Cake
/queue type
add name=CAKE-300M kind=cake cake-bandwidth=285M cake-diffserv=diffserv3 cake-flowmode=triple-isolate cake-nat=yes cake-rtt-scheme=internet
# diffserv3 → prioriza voz y tráfico interactivo.
# triple-isolate → evita que un dispositivo acapare el ancho de banda.
# nat=yes → importante si usas NAT (casi seguro que sí).
# internet → RTT adecuado para acceso a Internet general.
/queue simple
add name=SQM-CAKE target=ether1 max-limit=285M/285M queue=CAKE-300M/CAKE-300M
# Ahora con queue tree para mejor control:
/queue type
add name=cake-download kind=cake \
    cake-bandwidth=285M \
    cake-diffserv=diffserv3 \
    cake-flowmode=triple-isolate \
    cake-nat=yes \
    cake-rtt-scheme=internet
add name=cake-upload kind=cake \
    cake-bandwidth=285M \
    cake-diffserv=diffserv3 \
    cake-flowmode=triple-isolate \
    cake-nat=yes \
    cake-rtt-scheme=internet
# Marca únicamente el tráfico que viene de Internet:
/ip firewall mangle
add chain=forward \
    in-interface=ether1 \
    action=mark-packet \
    new-packet-mark=wan-download \
    passthrough=no
# All lo que sale por la WAN:
/queue tree
add name=Upload parent=ether1 packet-mark=no-mark queue=cake-upload
# All que entra desde Internet hacia la LAN:
/queue tree
add name=Download parent=bridge packet-mark=wan-download queue=cake-download

### SQM generado por ChatGPT FQ-CoDel
/queue type
add name=fqcodel-upload kind=fq-codel
add name=fqcodel-download kind=fq-codel

/ip firewall mangle
add chain=forward in-interface=ether1 action=mark-packet new-packet-mark=wan-download passthrough=no

/queue tree
add name=UPLOAD parent=ether1 packet-mark=no-mark max-limit=285M queue=fqcodel-upload
/queue tree
add name=DOWNLOAD parent=bridge packet-mark=wan-download max-limit=285M queue=fqcodel-download


#############
/queue type
add kind=fq-codel name=fqcodel

/queue tree
add name="SQM-UPLOAD" parent=ether1 max-limit=285M queue=fqcodel
/queue tree
add name="SQM-DOWNLOAD" parent=bridge in-interface=pppoe-out1 max-limit=285M queue=fqcodel
