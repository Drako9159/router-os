

### SQM generado por Claude Cake
/queue type
add name=cake-upload kind=cake cake-flowmode=dual-srchost cake-nat=yes cake-diffserv=diffserv4
# cake-flowmode=dual-srchost/dsthost → Aísla flujos por IP de origen/destino, perfecto con NAT.
# cake-diffserv=diffserv4 → Prioriza VoIP, video, web sobre bulk (torrents).
add name=cake-download kind=cake cake-flowmode=dual-dsthost cake-nat=yes cake-diffserv=diffserv4

/queue tree
add name=sqm-upload parent=ether1 queue=cake-upload max-limit=285M packet-mark=no-mark bucket-size=0.01
# bucket-size=0.01 → Reduce el buffer interno, mejora la latencia bajo carga.
# Si tu enlace es asimétrico (ej. 300 down / 50 up), ajusta cada max-limit por separado: 
# max-limit=285M para bajada y max-limit=47M para subida.
add name=sqm-download parent=bridge queue=cake-download max-limit=285M packet-mark=no-mark bucket-size=0.01
### SQM generado por Claude FQ-CoDel
/queue type
add name=fq-codel kind=fq-codel
/queue tree
add name=sqm-upload parent=ether1 queue=fq-codel max-limit=285M packet-mark=no-mark bucket-size=0.01
add name=sqm-download parent=bridge queue=fq-codel max-limit=285M packet-mark=no-mark bucket-size=0.01

# FastTrack hace que los flujos bypaseen el CPU, 
# lo cual es malo para CAKE ya que corre puramente en el kernel de Linux del router. 
# La solución es usar Queue Tree con parent en la interfaz WAN/LAN directamente, 
# en lugar de global, y configurar packet-mark=no-mark. 
# Los paquetes sin marca irán al queue tree sin necesidad de deshabilitar FastTrack.