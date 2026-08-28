/disk settings
set auto-media-interface=bridge


/ip neighbor discovery-settings
set discover-interface-list=LAN


/system ntp client
set enabled=yes
/system ntp client servers
add address=time.google.com

