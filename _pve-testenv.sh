#!/usr/bin/env bash
basedir="/shared"

# Symlink /etc/hosts so no restart is required when it is changed
test -e "$basedir/hosts" && ln -sf "${basedir}/hosts" /etc/hosts

# No DNS resolving
rm -f /etc/resolv.conf

# Change path for root
sed -i '/^PATH=/d' /root/.bashrc
echo 'PATH=$PATH:/shared/scripts' >> /root/.bashrc

# Set routes
test -e "$basedir/routes-$HOSTNAME" && {
   while read route; do
      ip route add $route
   done < "$basedir/routes-$HOSTNAME"
}

# Enable forwarding when more than 1 interface
test $(ip -br a l | wc -l) -gt 2 && sysctl -q net.ipv4.conf.all.forwarding=1

# Disable start of sshd
systemctl mask ssh.socket
systemctl disable ssh.service
systemctl stop ssh.service

# Update neighbours arp cache
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
