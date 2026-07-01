/queue type
add kind=cake \
    name=cake-rx \
    cake-diffserv=besteffort \
    cake-flowmode=dual-dsthost \
    cake-rtt-scheme=regional \
    cake-nat=yes
add kind=cake \
    name=cake-tx \
    cake-ack-filter=filter \
    cake-diffserv=besteffort \
    cake-flowmode=dual-srchost \
    cake-rtt-scheme=regional \
    cake-nat=yes

/queue simple
add name=queue1 \
    max-limit=256M/24M \
    queue=cake-rx/cake-tx \
    target=ether1 \
    total-queue=default


