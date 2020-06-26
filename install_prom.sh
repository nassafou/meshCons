#!/bin/bash

## install master consul

IP=$(hostname -I | awk '{print $2}')
echo "START - install prom - "$IP

echo "[1]: install utils and prometheus/grafana"
apt-get update -qq >/dev/null
apt-get install -qq -y wget unzip prometheus >/dev/null

echo "[2]: prometheus conf"
echo "
global:
  scrape_interval:     5s 
  evaluation_interval: 5s 
  external_labels:
    monitor: 'codelab-monitor'
rule_files:
scrape_configs:
  - job_name: Consul
    consul_sd_configs:
      - server: '192.168.58.10:8500'
        datacenter: 'mydc'
    relabel_configs:
      - source_labels: [__meta_consul_tags]
        regex: .*,metrics,.*
        action: keep
      #- source_labels: ['__address__']
        #separator:     ':'
        #regex:         '(.*):(.*)'
        #target_label:  '__address__'
        # The first regex result is used for the replacement rule, which
        # is the host address without port. 9100 is appended to the address
        #replacement:   '${1}:8080'
      - source_labels: [__meta_consul_service]
        target_label: job
      - source_labels: [__meta_consul_node]
        target_label: instance
" >/etc/prometheus/prometheus.yml
service prometheus restart


echo "[3]: install grafana"
curl -s https://packages.grafana.com/gpg.key | sudo apt-key add - >/dev/null
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
apt-get update -qq >/dev/null
apt-get install -qq -y grafana >/dev/null


echo "END - install prometheus"

