#!/bin/sh
set -e
echo "Setting up philosophers container"

DEBIAN_FRONTEND=noninteractive NEEDRESTART_SUSPEND=1 apt-get install -y systemd-container
machinectl pull-tar --verify=checksum https://github.com/NeilW/systemd-dining/releases/download/latest/philosophers.tar.xz
mkdir -p /etc/systemd/nspawn /etc/systemd/network/80-container-ve.network.d
[ ! -e /var/lib/machines/philosophers.nspawn ] || cp /var/lib/machines/philosophers.nspawn /etc/systemd/nspawn/philosophers.nspawn
cat > /etc/systemd/network/80-container-ve.network.d/ipv6prefix.conf <<-END
[IPv6Prefix]
Prefix=fd00:$(hexdump -v -n2 -e' /1 "%02x"' /dev/urandom)::/64
Assign=true
END

echo "Installing terminal routing software"
DEBIAN_FRONTEND=noninteractive NEEDRESTART_SUSPEND=1 apt-get install -y socat
if [ ! -e /usr/local/bin/websocat ]
then
    curl -L -o /usr/local/bin/websocat https://github.com/vi/websocat/releases/download/v1.12.0/websocat_max.x86_64-unknown-linux-musl
    chmod a+x /usr/local/bin/websocat
fi

echo "Setting up login units"

mkdir -p /etc/sysusers.d
cat > /etc/sysusers.d/tlssh.conf <<-USERS
g gatekeeper - -
u tlssh - "Philosophers secure login" /nonexistent
m tlssh gatekeeper
USERS
systemd-sysusers
mkdir -p /etc/polkit-1/rules.d
cat > /etc/polkit-1/rules.d/10-gatekeeper-login.rules <<-POLKIT
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.machine1.login" &&
        subject.isInGroup("gatekeeper")) {
        return polkit.Result.YES;
    }
});
POLKIT
fqdn=$(hostname -f)
terminal_dir=/usr/local/share/terminal
snap install certbot
if host "public.${fqdn}" >/dev/null 2>&1
then
    domains="public.${fqdn},ipv6.${fqdn}"
else
    domains="ipv6.${fqdn}"
fi
certbot certonly -q -n --register-unsafely-without-email --expand --agree-tos --standalone -d "${domains}"
chgrp -R gatekeeper /etc/letsencrypt/live /etc/letsencrypt/archive
chmod -R g+r /etc/letsencrypt/live /etc/letsencrypt/archive
chmod g+x /etc/letsencrypt/live /etc/letsencrypt/archive

mkdir -p "${terminal_dir}"
curl -L -o "${terminal_dir}/index.html" https://raw.githubusercontent.com/newwayland/terminal/v0.0.1/index.html
cat > /etc/systemd/system/tlssh.service <<-UNIT
[Unit]
Description=TLS secure login server
After=network.target auditd.service

[Service]
Restart=on-failure
ExecStart=/usr/bin/socat -T 300 OPENSSL-LISTEN:8000,pf=ip6,fork,reuseaddr,verify=0,cert=/etc/letsencrypt/live/ipv6.${fqdn}/fullchain.pem,key=/etc/letsencrypt/live/ipv6.${fqdn}/privkey.pem EXEC:"/usr/bin/machinectl login philosophers",pty,ctty,setsid,stderr
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
cat > /etc/systemd/system/wsssh.service <<-WSS
[Unit]
Description=WSS secure login server
After=network.target auditd.service tlssh.service
Wants=tlssh.service

[Service]
AmbientCapabilities=CAP_NET_BIND_SERVICE
Restart=on-failure
ExecStart=/usr/bin/socat -T 300 OPENSSL-LISTEN:443,pf=ip6,fork,reuseaddr,verify=0,cert=/etc/letsencrypt/live/ipv6.${fqdn}/fullchain.pem,key=/etc/letsencrypt/live/ipv6.${fqdn}/privkey.pem EXEC:'/usr/local/bin/websocat -E --tls-domain ipv6.${fqdn} --restrict-uri=/ws -F=/\\\\:text/html\\\\:${terminal_dir}/index.html --binary ws-u\\\\:asyncstdio\\\\: ssl\\\\:tcp\\\\:[::]\\\\:8000'
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
WSS
systemctl enable --now wsssh.service tlssh.service
