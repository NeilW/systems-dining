#!/bin/sh
set -e
echo "Setting up philosophers container"

apt-get install -y systemd-container
machinectl pull-tar --verify=checksum https://github.com/NeilW/systemd-dining/releases/download/latest/philosophers.tar.xz
mkdir -p /etc/systemd/nspawn /etc/systemd/network/80-container-ve.network.d
cp /var/lib/machines/philosophers.nspawn /etc/systemd/nspawn/philosophers.nspawn
cat > /etc/systemd/network/80-container-ve.network.d/ipv6prefix.conf <<-END
[IPv6Prefix]
Prefix=fd00:$(hexdump -v -n2 -e' /1 "%02x"' /dev/urandom)::/64
Assign=true
END
