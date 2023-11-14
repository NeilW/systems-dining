#!/bin/sh
set -e
APT_GET="DEBIAN_FRONTEND=noninteractive NEEDRESTART_SUSPEND=1 apt-get -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -y"

echo "Adding required packages"
eval ${APT_GET} update
eval ${APT_GET} upgrade
eval ${APT_GET} install dma mailutils systemd-container finger

echo "Installing simulation"
install bin/* /usr/local/bin
install sbin/* /usr/local/sbin
cp -dR --preserve=mode skel /etc

echo "Adding Philosophers group"
getent group philosophers > /dev/null || addgroup philosophers

echo "Creating dining room"
install -Dd -g philosophers -m 755 /home/share/dining-room
install -d -g philosophers -m 1775 /home/share/dining-room/seats /home/share/dining-room/forks
