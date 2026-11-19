
# 3. Create a new WireGuard interface
/interface wireguard
add listen-port=13231 mtu=1420 name=wireguard-inet private-key=”x=”

# 4. Add an IP address to the interface you just created:
/ip address
add address=10.2.0.2/30 interface=wireguard-inet network=10.2.0.0 

# 5. Add a WireGuard server as a peer
# Add the endpoint address, endpoint port, and public key from the WireGuard config file. Look for the lines starting PublicKey= and Endpoint=. 
# For example, if the config says Endpoint=103.107.197.2:51820, enter endpoint-address=103.107.197.2 and endpoint-port=51820

/interface wireguard peers
add allowed-address=0.0.0.0/0 endpoint-address=84.20.27.33 endpoint-port=51820 interface=wireguard-inet persistent-keepalive=25s public-key="x" 

# 6. Enable masquerade for that interface
# Note: This setup assumes that you are using the default local network address used by MikroTik. If you have changed this, use that address for scr-address=  instead.

/ip firewall nat
add action=masquerade chain=srcnat out-interface=wireguard-inet src-address=192.168.88.0/24

# 7. Redirect all internet traffic through WireGuard

/ip route
add disabled=no distance=1 dst-address=0.0.0.0/1 gateway=10.2.0.1 pref-src="" routing-table=main scope=30 suppress-hw-offload=no target-scope=10
add disabled=no distance=1 dst-address=128.0.0.0/1 gateway=10.2.0.1 pref-src="" routing-table=main scope=30 suppress-hw-offload=no target-scope=10

# 8. Configure DNS settings

/ip dns
set servers=10.2.0.1
/ip dhcp-client
set 0 use-peer-dns=no

# 9. Redirect the WireGuard IP address through main provider’s gateway
# Replace x.x.x.x with the endpoint address from the config file (Endpoint=). 

/ip route
add disabled=no dst-address=x.x.x.x/32 gateway=[/ip dhcp-client get [find interface=ether1] gateway] routing-table=main suppress-hw-offload=no
# If this doesn’t work, you’ll need to replace gateway=[/ip dhcp-client get [find interface=ether1] gateway] with gateway=x.x.x.x, where x.x.x.x is your own internet gateway address. Your internet service provider (ISP) should be able to provide this address.
# 10. Restart your router
