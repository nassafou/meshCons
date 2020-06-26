#!/bin/bash

IP=$(hostname -I | awk '{print $2}')

echo "START - Install consulm"


echo "[1]  - Install consul"

apt-get -qq update >/dev/null

apt-get -qq install -y wget unzip dnsutils python-pip python-flask >/dev/null

wget https://releases.hashicorp.com/consul/1.5.3/consul_1.5.3_linux_amd64.zip
unzip consul_1.5.3_linux_amd64.zip
mv consul /usr/local/bin/ 
groupadd --system consul
useradd -s /sbin/nologin --system -g consul consul 
mkdir -p /var/lib/consul 
chown -R consul:consul /var/lib/consul 
chmod -R 775 /var/lib/consul 
mkdir /etc/consul.d 
chown -R consul:consul /etc/consul.d

echo "[2] - install configuration"

echo '{
    "advertise_addr": "'$IP'",
    "bind_addr": "'$IP'",
    "bootstrap_expect": 1,
    "client_addr": "0.0.0.0",
    "datacenter": "mydc",
    "data_dir": "/var/lib/consul",
    "domain": "consul",
    "enable_script_checks": true,
    "dns_config": {
        "enable_truncate": true,
        "only_passing": true
    },
    "enable_syslog": true,
    "encrypt": "TeLbPpWX41zMM3vfLwHHfQ==",
    "leave_on_terminate": true,
    "log_level": "INFO",
    "rejoin_after_leave": true,
    "retry_join": [
        "'$IP'"
    ],
    "server": true,
    "start_join": [
        "'$IP'"
    ],
    "ui": true
}' > /etc/consul.d/config.json

echo "[5]: consul create service systemd"
echo '[Unit]
Description=Consul Service Discovery Agent
Documentation=https://www.consul.io/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent \
  -node='$IP' \
  -config-dir=/etc/consul.d

ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
TimeoutStopSec=5
Restart=on-failure
SyslogIdentifier=consul

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/consul.service

echo "[6]: consul start service"
#systemctl enable consul
#service consul start

#echo "[7]: add user xavki / psswd= password"
#useradd -m -s /bin/bash -p sa3tHJ3/KuYvI -U xavki
#echo "%xavki ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/xavki

######################## CONSUL TEMPLATE #######################################################

apt-get update
apt-get install -y wget unzip net-tools
wget https://releases.hashicorp.com/consul-template/0.19.5/consul-template_0.19.5_linux_amd64.zip
unzip consul-template_0.19.5_linux_amd64.zip
mv consul-template /usr/local/bin
chown consul:consul /usr/local/bin/consul-template
chmod 755 /usr/local/bin/consul-template
mkdir /etc/consul-template
chown consul:consul /etc/consul-template
chmod 775 /etc/consul-template

###################### systemd consul-template ##################

echo '
[Unit]
Description=Consul Template adon to consul
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=consul
ExecStart=/usr/local/bin/consul-template \
  -consul-addr 127.0.0.1:8500 \
  -template "/etc/consul-template/haproxy.tmpl:/etc/haproxy/haproxy.cfg:service haproxy reload"

ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
TimeoutStopSec=5
Restart=on-failure
SyslogIdentifier=consul

[Install]
WantedBy=multi-user.target
' >/etc/systemd/system/consul-template.service


############################# TEMPLATE #########################################################

echo '
# template consul template pour haproxy

global
        daemon
        maxconn 256

    defaults
        mode http
        timeout connect 5000ms
        timeout client 50000ms
        timeout server 50000ms

frontend monservice
        bind :80
        mode http
        default_backend monservice

backend monservice
        mode http
        cookie LBN insert indirect nocache
        option httpclose
        option forwardfor
        balance roundrobin {{ range service monservice }}
        server {{ .Node }} {{.Address }}:{{ .Port }} {{ end }}
' >/etc/consul-template/haproxy.tmpl


echo "END - install cmaster"
