/ip firewall raw
# Facebook & Instagram CDN
add action=add-dst-to-address-list address-list=Bloqueo_Redes address-list-timeout=1d chain=prerouting dst-port=443 protocol=tcp tls-host=*facebook.com
add action=add-dst-to-address-list address-list=Bloqueo_Redes address-list-timeout=1d chain=prerouting dst-port=443 protocol=tcp tls-host=*fbcdn.net
add action=add-dst-to-address-list address-list=Bloqueo_Redes address-list-timeout=1d chain=prerouting dst-port=443 protocol=tcp tls-host=*instagram.com

# TikTok y servidores de contenido (ByteDance)
add action=add-dst-to-address-list address-list=Bloqueo_Redes address-list-timeout=1d chain=prerouting dst-port=443 protocol=tcp tls-host=*tiktok.com
add action=add-dst-to-address-list address-list=Bloqueo_Redes address-list-timeout=1d chain=prerouting dst-port=443 protocol=tcp tls-host=*tiktokcdn.com
add action=add-dst-to-address-list address-list=Bloqueo_Redes address-list-timeout=1d chain=prerouting dst-port=443 protocol=tcp tls-host=*byteoversea.com
add action=add-dst-to-address-list address-list=Bloqueo_Redes address-list-timeout=1d chain=prerouting dst-port=443 protocol=tcp tls-host=*ibytedtos.com
