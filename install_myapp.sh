#!/bin/bash

IP=$(hostname -I | awk '{print $2}')

echo "START - Install myapp"


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
    "192.168.58.10"
    ]
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
systemctl enable consul
service consul start

#echo "[7]: add user xavki / psswd= password"
#useradd -m -s /bin/bash -p sa3tHJ3/KuYvI -U xavki
#echo "%xavki ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/xavki

echo "[7] - install myapp "

pip install -q prometheus_client
mkdir /var/myapp/
echo "#!/usr/bin/python
from flask import Flask,request,Response
from prometheus_client import (generate_latest,CONTENT_TYPE_LATEST )
import socket
app = Flask(__name__)


@app.route('/')
def hello_world():
    hostname = socket.gethostname()
    message = 'Bonjour, je suis ' + hostname + '\n'
    return message


@app.route('/metrics')
def metrics():
    return Response(generate_latest(),mimetype=CONTENT_TYPE_LATEST)


if __name__ == '__main__':
  app.run(host='0.0.0.0', port=80)
">/var/myapp/myapp.py
chmod 755 /var/myapp/myapp.py

echo "[8] - install myapp service systemd "

echo '[Unit]
Description=MyApp service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/var/myapp/myapp.py \ 
ExecReload=/bin/kill -HUP $KillSignal=SIGINT
TimeoutStopSec=5
Restart=on-failure
SyslogIdentifier=myapp

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/myapp.service

systemctl enable myapp
service myapp start

echo '
{"service":
 {
 "name": "myapp",
 "tags": ["myapp","python","metrics","url:myapp.localhost"],
 "port": 80,
 "check": {
    "http": "http://localhost:80/",
    "interval": "3s"
   }
 }
}
' >/etc/consul.d/service_myapp.json
consul reload

echo "END - install myapp $IP"
