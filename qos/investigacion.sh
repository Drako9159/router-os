# Foro mikrotik 2022 anserk
/queue type
add cake-ack-filter=filter cake-flowmode=dual-srchost cake-mpu=64 cake-nat=yes cake-overhead=18 cake-overhead-scheme=docsis kind=cake name=cake-up
add cake-diffserv=besteffort cake-flowmode=dual-dsthost cake-mpu=64 cake-overhead=18 cake-overhead-scheme=docsis kind=cake name=cake-down
/queue tree
add bucket-size=0.01 max-limit=118M name=download packet-mark=no-mark parent=bridge1 queue=cake-down
add bucket-size=0.01 max-limit=11M name=upload packet-mark=no-mark parent=ether1 queue=cake-up
########
/queue type
add fq-codel-limit=1000 fq-codel-quantum=300 fq-codel-target=12ms kind=fq-codel name=fq-codel
/queue tree
add bucket-size=0.01 max-limit=118M name=download packet-mark=no-mark parent=bridge1 queue=fq-codel
add bucket-size=0.01 max-limit=11M name=upload packet-mark=no-mark parent=ether1 queue=fq-codel
######
/queue type
add cake-ack-filter=filter cake-flowmode=dual-srchost cake-mpu=64 cake-nat=yes cake-overhead=22 kind=cake name=cake-up
add cake-diffserv=besteffort cake-flowmode=dual-dsthost cake-mpu=64 cake-overhead=22 kind=cake name=cake-down
/queue tree
add bucket-size=0.01 max-limit=118M name=download packet-mark=no-mark parent=bridge1 queue=cake-down
add bucket-size=0.01 max-limit=11M name=upload packet-mark=no-mark parent=ether1 queue=cake-up



# SQM configuration - Foro animmouse.com feb 2023
# Controlado por Flujo justo (FQ-CoDel)
# Add FQ-CoDel queue type
/queue type
add kind=fq-codel name=fq-codel
# Add queue tree upstream from router to internet, specify WAN interface in parent,
# My WAN is ether1, set max-limit to upstream bandwidth, and set queue to fq-codel
/queue tree
add max-limit=249M name=queue-upload packet-mark=no-mark parent=ether1 queue=fq-codel
# Add queue tree downstream from router to LAN, specify LAN bridge in parent,
# My LAN bridge is bridge1, set max-limit to downstream bandwidth, and set queue to fq-codel
/queue tree
add max-limit=249M name=queue-download packet-mark=no-mark parent=bridge queue=fq-codel
# Check queue bufferbloat with ping, and adjust max-limit if necessary
# Controlado por CAKE
# Add CAKE queue type for upstream and downstream
/queue type
add kind=cake name=cake
/queue tree
add max-limit=249M name=cake-upload packet-mark=no-mark parent=ether1 queue=cake
/queue tree
add max-limit=249M name=cake-download packet-mark=no-mark parent=bridge queue=cake



/queue type
add cake-flowmode=dual-srchost cake-nat=yes kind=cake name=cake-upload-ips1
add cake-flowmode=dual-dsthost cake-nat=yes kind=cake name=cake-download-ips1
/queue tree
add bucket-size=0.01 max-limit=300M name=download packet-mark=no-mark parent=bridge queue=cake-download-ips1
add bucket-size=0.01 max-limit=300M name=upload packet-mark=no-mark parent=ether1-wan queue=cake-upload-ips1



# Foro reddit
/queue tree
    # CAKE type with bandwidth setting detected, configure traffic limits within queue itself
    add bucket-size=0.01 name="Upload from Lan" packet-mark=wan_egress_default \
    parent=ether1-wan queue=Cake_25mbit_UP
    # CAKE type with bandwidth setting detected, configure traffic limits within queue itself
    add bucket-size=0.01 name=Download_From_Wan packet-mark=wan_ingress_default \
    parent=bridge queue=Cake_250mbit_Down
/queue type
    add cake-bandwidth=245.0Mbps cake-diffserv=besteffort cake-memlimit=48.0MiB \
    cake-mpu=84 cake-overhead=38 cake-overhead-scheme=ethernet cake-rtt=50ms \
    cake-wash=yes kind=cake name=Cake_250mbit_Down
    add cake-ack-filter=filter cake-bandwidth=24.5Mbps cake-diffserv=diffserv4 \
    cake-memlimit=48.0MiB cake-mpu=84 cake-nat=yes cake-overhead=38 \
    cake-overhead-scheme=ethernet cake-rtt=50ms kind=cake name=Cake_25mbit_UP
/ip firewall mangle
    add action=mark-connection chain=prerouting in-interface-list=WAN \
    new-connection-mark=wan_connection passthrough=yes
    add action=mark-packet chain=prerouting in-interface-list=WAN \
    new-packet-mark=wan_ingress_default passthrough=no
    add action=mark-connection chain=postrouting new-connection-mark=\
    Outbound_conn out-interface=ether1-wan passthrough=yes
    add action=mark-packet chain=postrouting connection-mark=Outbound_conn \
    new-packet-mark=wan_egress_default out-interface=ether1-wan passthrough=\
    no
/ipv6 firewall mangle
    add action=mark-connection chain=prerouting in-interface=ether1-wan \
    new-connection-mark=wan_connection passthrough=yes
    add action=mark-packet chain=prerouting in-interface=ether1-wan \
    new-packet-mark=wan_ingress_default passthrough=no
    add action=mark-connection chain=postrouting new-connection-mark=\
    outbound_wan_connection out-interface=ether1-wan passthrough=yes
    add action=mark-packet chain=postrouting connection-mark=\
    outbound_wan_connection new-packet-mark=wan_egress_default out-interface=\
    ether1-wan passthrough=no
    add action=change-mss chain=forward new-mss=clamp-to-pmtu out-interface=\
    ether1-wan passthrough=yes protocol=tcp tcp-flags=syn



# Foro mikrotik Jun 2025
/interface list
add name=local
/interface list member
add interface=vlan101 list=local
add interface=vlan102 list=local
/ip firewall mangle
add action=mark-packet chain=forward comment=inter-vlan in-interface-list=local new-packet-mark=intervlan out-interface-list=local passthrough=no
/ip firewall filter
add action=fasttrack-connection chain=forward comment="fasttrack for established,related" connection-state=established,related hw-offload=yes packet-mark=no-mark


# Foro mikroik Jan 2024
# La primera usó mayor cantidad de CPU con simple queue
/queue type
    add cake-ack-filter=filter cake-diffserv=diffserv4 cake-mpu=84 cake-nat=yes cake-overhead=44 kind=cake name=CAKE_UP
    add cake-diffserv=diffserv4 cake-mpu=84 cake-overhead=44 kind=cake name=CAKE_DOWN
/queue simple
    add bucket-size=0.001/0.001 disabled=yes max-limit=960M/55M name=CAKE queue=CAKE_DOWN/CAKE_UP target=pppoe-ADSL
# La segunda usó menor cantidad de CPU con queue tree
/queue type
    add cake-ack-filter=filter cake-diffserv=diffserv4 cake-mpu=84 cake-nat=yes cake-overhead=44 kind=cake name=CAKE_UP
    add cake-diffserv=diffserv4 cake-mpu=84 cake-overhead=44 kind=cake name=CAKE_DOWN
/queue tree
    add bucket-size=0.001 disabled=yes limit-at=55M max-limit=55M name=UP packet-mark=no-mark parent=ether1 priority=3 queue=CAKE_UP
    add bucket-size=0.001 disabled=yes limit-at=940M max-limit=940M name=DOWN packet-mark=no-mark parent=bridge priority=4 queue=CAKE_DOWN
# Extra
/queue simple
    add bucket-size=0.001/0.001 disabled=yes name=CAKE_SHAPE queue=CAKE_DL/CAKE_UL target=pppoe-ADSL


# Foro reddit, no recomendado
/queue type
add name=cake-up kind=cake cake-bandwidth=900M cake-diffserv=diffserv4 cake-nat=yes cake-rtt-scheme=internet
add name=cake-dn kind=cake cake-bandwidth=900M cake-diffserv=diffserv4 cake-rtt-scheme=internet

/queue interface
# WAN
set ether1 queue=cake-up
# LAN
set ether2 queue=cake-dn
set ether3 queue=cake-dn




# SQM generado por Gemini Cake
/queue type
add name=Cake-Download kind=cake cake-flow-isolation=triple-isolate cake-memlimit=32M
add name=Cake-Upload kind=cake cake-flow-isolation=triple-isolate cake-memlimit=32M

/queue simple
add name="SQM-Cake" target=bridge max-limit=285M/285M queue=Cake-Upload/Cake-Download total-queue=default

/ip firewall filter
add chain=forward action=fasttrack-connection connection-state=established,related queue=!SQM-Cake comment="Fasttrack bypass para SQM"


