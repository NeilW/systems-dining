#!/bin/sh
set -e
echo "Setting up philosophers container"

DEBIAN_FRONTEND=noninteractive NEEDRESTART_SUSPEND=1 apt-get install -y systemd-container socat
machinectl pull-tar --verify=checksum https://github.com/NeilW/systemd-dining/releases/download/latest/philosophers.tar.xz
mkdir -p /etc/systemd/nspawn /etc/systemd/network/80-container-ve.network.d
[ ! -e /var/lib/machines/philosophers.nspawn ] || cp /var/lib/machines/philosophers.nspawn /etc/systemd/nspawn/philosophers.nspawn
cat > /etc/systemd/network/80-container-ve.network.d/ipv6prefix.conf <<-END
[IPv6Prefix]
Prefix=fd00:$(hexdump -v -n2 -e' /1 "%02x"' /dev/urandom)::/64
Assign=true
END

echo "Setting up login units"

mkdir -p /etc/sysusers.d
cat > /etc/sysusers.d/tlssh.conf <<-USERS
g gatekeeper - -
u tlssh - "Philosophers secure login" /nonexistent
m tlssh gatekeeper
USERS
systemd-sysusers
cat > /etc/polkit-1/rules.d/10-gatekeeper-login.rules <<-POLKIT
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.machine1.login" &&
        subject.isInGroup("gatekeeper")) {
        return polkit.Result.YES;
    }
});
POLKIT
cat > /etc/systemd/system/tlssh.service <<-UNIT
[Unit]
Description=TLS secure login server
After=network.target auditd.service

[Service]
Restart=on-failure
ExecStart=/usr/bin/socat -T 300 TCP6-L:8000,fork,reuseaddr EXEC:"/usr/bin/machinectl login philosophers",pty,ctty,setsid,stderr
SuccessExitStatus=143
DynamicUser=yes
User=tlssh
Group=gatekeeper
KillMode=process
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
ProtectHostname=yes
ProtectClock=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectKernelLogs=yes
UMask=077

[Install]
WantedBy=multi-user.target
UNIT
systemctl enable --now tlssh
