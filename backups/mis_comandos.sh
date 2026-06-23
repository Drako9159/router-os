# 2026-06-14 15:08:06 by RouterOS 7.23.1
# software id = AKL3-DLPU
#
# model = E50UG
# serial number = HMC0B13GB5Y
/interface bridge
add admin-mac=D0:EA:11:74:5A:F4 arp=reply-only auto-mac=no comment=defconf \
    name=bridge
/disk
set usb1 media-interface=bridge media-sharing=yes smb-sharing=yes
/interface list
add comment=defconf name=WAN
add comment=defconf name=LAN
/ip dhcp-server option
add code=6 name=dns-filtrado-cloud value="'1.1.1.3'"
/ip pool
add name=default-dhcp ranges=192.168.88.128-192.168.88.254
/ip dhcp-server
add add-arp=yes address-pool=default-dhcp interface=bridge lease-script="#####\
    ########## Alerta telegram para cada que un cliente solicita una IP al DCH\
    P, clientes din\C3\A1micos o no ###############\
    \n:local botToken \"8854615252:AAHVFRI8tGk43kfxpIBmh2lUxbhI8Cy8Xlc\"\
    \n:local chatId \"307490400\"\
    \n\
    \n:if (\$leaseBound = 1) do={\
    \n    :local leaseMac \$\"leaseActMAC\"\
    \n    :local leaseIp \$\"leaseActIP\"\
    \n    \
    \n    # Obtener el nombre del host de forma segura (Tu l\C3\B3gica exacta)\
    \n    :local hostName \"Desconocido\"\
    \n    :do {\
    \n        :set hostName [/ip dhcp-server lease get [find where active-mac-\
    address=\$leaseMac active-address=\$leaseIp] host-name]\
    \n    } on-error={:set hostName \"Desconocido\"}\
    \n    \
    \n    # Obtener el comentario de forma segura usando la misma estructura a\
    nidada\
    \n    :local leaseComment \"Sin-Comentario\"\
    \n    :do {\
    \n        :set leaseComment [/ip dhcp-server lease get [find where active-\
    mac-address=\$leaseMac active-address=\$leaseIp] comment]\
    \n    } on-error={:set leaseComment \"Sin-Comentario\"}\
    \n    \
    \n    # Si vienen vac\C3\ADos, asegurar un texto plano sin espacios\
    \n    :if ([:len \$hostName] = 0) do={:set hostName \"Dispositivo-sin-nomb\
    re\"}\
    \n    :if ([:len \$leaseComment] = 0) do={:set leaseComment \"Sin-Comentar\
    io\"}\
    \n    \
    \n    # Reemplazamos los espacios del hostName por guiones para proteger l\
    a URL\
    \n    :for i from=0 to=([:len \$hostName] - 1) do={\
    \n        :local char [:pick \$hostName \$i (\$i + 1)]\
    \n        :if (\$char = \" \") do={\
    \n            :set hostName ([:pick \$hostName 0 \$i] . \"-\" . [:pick \$h\
    ostName (\$i + 1) [:len \$hostName]])\
    \n        }\
    \n    }\
    \n    \
    \n    # Reemplazamos los espacios del leaseComment por guiones para proteg\
    er la URL\
    \n    :for i from=0 to=([:len \$leaseComment] - 1) do={\
    \n        :local char [:pick \$leaseComment \$i (\$i + 1)]\
    \n        :if (\$char = \" \") do={\
    \n            :set leaseComment ([:pick \$leaseComment 0 \$i] . \"-\" . [:\
    pick \$leaseComment (\$i + 1) [:len \$leaseComment]])\
    \n        }\
    \n    }\
    \n\
    \n    # Extraemos fecha y hora por separado para evitar caracteres extra\
    \C3\B1os\
    \n    :local date [/system clock get date]\
    \n    :local time [/system clock get time]\
    \n    \
    \n    # Construimos el mensaje incluyendo el campo del comentario (Alias)\
    \n    :local mensaje \"\F0\9F\9F\A2%20ONLINE:%20\$leaseIp%0A--------------\
    --------------------------%0A\F0\9F\91\A4%20DTECT:%20\$leaseComment%0A\F0\
    \9F\94\8D%20MAC:%20\$leaseMac%0A\F0\9F\92\BB%20NAME:%20\$hostName%0A\E2\8F\
    \B1%20DATE:%20\$date%20\$time\"\
    \n    \
    \n    # Ejecutamos la petici\C3\B3n HTTP limpia\
    \n    /tool fetch url=\"https://api.telegram.org/bot\$botToken/sendMessage\
    \?chat_id=\$chatId&text=\$mensaje\" keep-result=no check-certificate=no\
    \n}" name=defconf
/queue type
add kind=cake name=cake-sqm-residencial
add cake-ack-filter=filter cake-diffserv=diffserv4 cake-flowmode=dual-srchost \
    cake-nat=yes cake-rtt-scheme=internet kind=cake name=cake-upload
add cake-diffserv=diffserv4 cake-flowmode=dual-dsthost cake-nat=yes \
    cake-rtt-scheme=internet kind=cake name=cake-download
add kind=fq-codel name=fq-codel
/queue simple
add disabled=yes name=Monitoreo-88.11 queue=default/default target=\
    192.168.88.11/32
add disabled=yes max-limit=2M/2M name=limite-2mb queue=default/default \
    target=192.168.88.14/32
add disabled=yes max-limit=820M/820M name=cake-0to31-personal queue=\
    cake-sqm-residencial/cake-sqm-residencial target=192.168.88.0/27
add disabled=yes max-limit=50M/50M name=cake-32to63-family queue=\
    cake-sqm-residencial/cake-sqm-residencial target=192.168.88.32/27
add disabled=yes max-limit=50M/50M name=cake-64to127-clientes queue=\
    cake-sqm-residencial/cake-sqm-residencial target=192.168.88.64/26
add disabled=yes max-limit=50M/50M name=cake-128to254-temporales queue=\
    cake-sqm-residencial/cake-sqm-residencial target=192.168.88.128/25
/queue tree
add bucket-size=0.01 disabled=yes max-limit=720M name=sqm-cake-upload \
    packet-mark=no-mark parent=ether1 queue=cake-upload
add bucket-size=0.01 disabled=yes max-limit=720M name=sqm-cake-download \
    packet-mark=no-mark parent=bridge queue=cake-download
add bucket-size=0.01 max-limit=720M name=sqm-fq-codel-upload packet-mark=\
    no-mark parent=ether1 queue=fq-codel
add bucket-size=0.01 max-limit=720M name=sqm-fq-codel-download packet-mark=\
    no-mark parent=bridge queue=fq-codel
add disabled=yes max-limit=20M name=limite-dispositivo-download packet-mark=\
    dispositivo-limite parent=bridge queue=default
add disabled=yes max-limit=20M name=limite-dispositivo-upload packet-mark=\
    dispositivo-limite parent=ether1 queue=default
/disk settings
set auto-media-interface=bridge auto-media-sharing=yes auto-smb-sharing=yes
/interface bridge port
add bridge=bridge comment=defconf interface=ether2
add bridge=bridge comment=defconf interface=ether3
add bridge=bridge comment=defconf interface=ether4
add bridge=bridge comment=defconf interface=ether5
/ip neighbor discovery-settings
set discover-interface-list=LAN
/interface list member
add comment=defconf interface=bridge list=LAN
add comment=defconf interface=ether1 list=WAN
/ip address
add address=192.168.88.1/24 comment=defconf interface=bridge network=\
    192.168.88.0
/ip dhcp-client
add comment=defconf interface=ether1 name=client1
/ip dhcp-server lease
add address=192.168.88.10 client-id=1:24:95:2f:c9:fe:84 comment=phone-px7a-my \
    mac-address=24:95:2F:C9:FE:84 server=defconf
add address=192.168.88.14 client-id=1:2c:58:b9:d1:6:9c comment=pc-hpvictus-my \
    mac-address=2C:58:B9:D1:06:9C server=defconf
add address=192.168.88.13 comment=tv-tcl-my mac-address=28:7E:80:52:53:CC \
    server=defconf
add address=192.168.88.11 client-id=1:90:df:7d:48:c8:63 comment=\
    phone-rmgt2p-my mac-address=90:DF:7D:48:C8:63 server=defconf
add address=192.168.88.12 client-id=1:84:d6:8:5c:4c:a6 comment=\
    phone-revvl6-my mac-address=84:D6:08:5C:4C:A6 server=defconf
/ip dhcp-server network
add address=192.168.88.0/24 comment=defconf dns-server=192.168.88.1 gateway=\
    192.168.88.1
/ip dns
set allow-remote-requests=yes verify-doh-cert=yes
/ip dns adlist
add disabled=yes url="https://raw.githubusercontent.com/Drako9159/router-os/re\
    fs/heads/master/blacklist/vpns.txt"
/ip dns static
add address=192.168.88.1 comment=defconf name=router.lan type=A
add address=127.0.0.1 disabled=yes match-subdomain=yes name=pornhub.com type=\
    A
add address=127.0.0.1 disabled=yes match-subdomain=yes name=xvideos.com type=\
    A
add address=127.0.0.1 disabled=yes match-subdomain=yes name=hentaila.com \
    type=A
/ip firewall address-list
add address=192.168.88.10 disabled=yes list=block-list
add address=192.168.88.10-192.168.88.31 disabled=yes list=skip-fasttrack-list
add address=192.168.88.10 disabled=yes list=dnsfamily-list
add address=151.243.141.158 disabled=yes list=blackvpn-list
add address=169.150.204.44 disabled=yes list=blackvpn-list
add address=195.242.214.2 disabled=yes list=blackvpn-list
add address=135.136.39.34 disabled=yes list=blackvpn-list
add address=18.195.213.112 disabled=yes list=blackvpn-list
add address=95.173.217.225 disabled=yes list=blackvpn-list
add address=192.168.88.10-192.168.88.31 disabled=yes list=nextdns-list
/ip firewall filter
add action=drop chain=forward comment=blacklist-ip disabled=yes \
    src-address-list=block-list
add action=drop chain=forward comment=blacklist-vpn-fordnsfamily disabled=yes \
    dst-address-list=blackvpn-list src-address-list=dnsfamily-list
add action=accept chain=input comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=input comment="defconf: drop invalid" connection-state=\
    invalid
add action=accept chain=input comment="defconf: accept ICMP" protocol=icmp
add action=accept chain=input comment=\
    "defconf: accept to local loopback (for CAPsMAN)" dst-address=127.0.0.1
add action=drop chain=input comment="defconf: drop all not coming from LAN" \
    in-interface-list=!LAN
add action=accept chain=forward comment="defconf: accept in ipsec policy" \
    ipsec-policy=in,ipsec
add action=accept chain=forward comment="defconf: accept out ipsec policy" \
    ipsec-policy=out,ipsec
add action=fasttrack-connection chain=forward comment="defconf: fasttrack" \
    connection-state=established,related dst-address-list=\
    !skip-fasttrack-list src-address-list=!skip-fasttrack-list
add action=accept chain=forward comment=\
    "defconf: accept established,related, untracked" connection-state=\
    established,related,untracked
add action=drop chain=forward comment="defconf: drop invalid" \
    connection-state=invalid
add action=drop chain=forward comment=\
    "defconf: drop all from WAN not DSTNATed" connection-nat-state=!dstnat \
    connection-state=new in-interface-list=WAN
/ip firewall mangle
add action=mark-packet chain=forward comment="Marca bajada de dispositivo" \
    disabled=yes dst-address=192.168.88.14 new-packet-mark=dispositivo-limite \
    passthrough=no
add action=mark-packet chain=forward comment="Marca subida de dispositivo" \
    disabled=yes new-packet-mark=dispositivo-limite passthrough=no \
    src-address=192.168.88.14
/ip firewall nat
add action=masquerade chain=srcnat comment="defconf: masquerade" \
    ipsec-policy=out,none out-interface-list=WAN
add action=dst-nat chain=dstnat comment=dnsfamily-udp disabled=yes \
    dst-address=!1.1.1.3 dst-port=53 protocol=udp src-address-list=\
    dnsfamily-list to-addresses=1.1.1.3
add action=dst-nat chain=dstnat comment=dnsfamily-tcp disabled=yes \
    dst-address=!1.1.1.3 dst-port=53 protocol=tcp src-address-list=\
    dnsfamily-list to-addresses=1.1.1.3
/ipv6 firewall address-list
add address=::/128 comment="defconf: unspecified address" list=bad_ipv6
add address=::1/128 comment="defconf: lo" list=bad_ipv6
add address=fec0::/10 comment="defconf: site-local" list=bad_ipv6
add address=::ffff:0.0.0.0/96 comment="defconf: ipv4-mapped" list=bad_ipv6
add address=::/96 comment="defconf: ipv4 compat" list=bad_ipv6
add address=100::/64 comment="defconf: discard only " list=bad_ipv6
add address=2001:db8::/32 comment="defconf: documentation" list=bad_ipv6
add address=2001:10::/28 comment="defconf: ORCHID" list=bad_ipv6
add address=3ffe::/16 comment="defconf: 6bone" list=bad_ipv6
/ipv6 firewall filter
add action=accept chain=input comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=input comment="defconf: drop invalid" connection-state=\
    invalid
add action=accept chain=input comment="defconf: accept ICMPv6" protocol=\
    icmpv6
add action=accept chain=input comment="defconf: accept UDP traceroute" \
    dst-port=33434-33534 protocol=udp
add action=accept chain=input comment=\
    "defconf: accept DHCPv6-Client prefix delegation." dst-port=546 protocol=\
    udp src-address=fe80::/10
add action=accept chain=input comment="defconf: accept IKE" dst-port=500,4500 \
    protocol=udp
add action=accept chain=input comment="defconf: accept ipsec AH" protocol=\
    ipsec-ah
add action=accept chain=input comment="defconf: accept ipsec ESP" protocol=\
    ipsec-esp
add action=accept chain=input comment=\
    "defconf: accept all that matches ipsec policy" ipsec-policy=in,ipsec
add action=drop chain=input comment=\
    "defconf: drop everything else not coming from LAN" in-interface-list=\
    !LAN
add action=fasttrack-connection chain=forward comment="defconf: fasttrack6" \
    connection-state=established,related
add action=accept chain=forward comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=forward comment="defconf: drop invalid" \
    connection-state=invalid
add action=drop chain=forward comment=\
    "defconf: drop packets with bad src ipv6" src-address-list=bad_ipv6
add action=drop chain=forward comment=\
    "defconf: drop packets with bad dst ipv6" dst-address-list=bad_ipv6
add action=drop chain=forward comment="defconf: rfc4890 drop hop-limit=1" \
    hop-limit=equal:1 protocol=icmpv6
add action=accept chain=forward comment="defconf: accept ICMPv6" protocol=\
    icmpv6
add action=accept chain=forward comment="defconf: accept HIP" protocol=139
add action=accept chain=forward comment="defconf: accept IKE" dst-port=\
    500,4500 protocol=udp
add action=accept chain=forward comment="defconf: accept ipsec AH" protocol=\
    ipsec-ah
add action=accept chain=forward comment="defconf: accept ipsec ESP" protocol=\
    ipsec-esp
add action=accept chain=forward comment=\
    "defconf: accept all that matches ipsec policy" ipsec-policy=in,ipsec
add action=drop chain=forward comment=\
    "defconf: drop everything else not coming from LAN" in-interface-list=\
    !LAN
/ipv6 nd
set [ find default=yes ] advertise-dns=yes
/system clock
set time-zone-name=America/Mexico_City
/tool mac-server
set allowed-interface-list=LAN
/tool mac-server mac-winbox
set allowed-interface-list=LAN
