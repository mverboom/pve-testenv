#!/usr/bin/env bash
basedir="/shared"
test -e "$basedir/hosts" && cp "$basedir/hosts" /etc/hosts
rm -f /etc/resolv.conf
test -e "$basedir/routes-$HOSTNAME" && {
   while read route; do
      ip route add $route
   done < "$basedir/routes-$HOSTNAME"
}
test $(ip -br a l | wc -l) -gt 2 && sysctl -q net.ipv4.conf.all.forwarding=1

while read if ip; do
   arping -q -w 0 -c 1 -U -I ${if/@*/} ${ip/\/*/}
done < <( ip -br a l | grep -v "^lo" | awk '{printf "%s %s\n",$1,$3}')

# Start services
while read -r line; do
   eval "$line &"
done < <( test -e "$basedir/services" && cat "$basedir/services" ; test -e "$basedir/services-$HOSTNAME" && cat "$basedir/services-$HOSTNAME" )

# Configure proxy
echo 'Acquire::http::Proxy "http://127.0.0.1:40000/";' > /etc/apt/apt.conf.d/01proxy
echo 'Acquire::https::Proxy "http://127.0.0.1:40000/";' >> /etc/apt/apt.conf.d/01proxy
socat tcp-listen:40000,fork,bind=127.0.0.1 unix-connect:"$basedir"/proxy
