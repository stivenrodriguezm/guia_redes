#!/bin/bash
set -e
echo "== 1/4 Red permanente y paquetes base"; bash /root/01-base.sh
echo "== 2/4 Zabbix 7.0"; bash /root/02-zabbix.sh
echo "== 3/4 Grafana + plugin + dashboard"; bash /root/03-grafana.sh
echo "== 4/4 Equipos en Zabbix"; sleep 20; python3 /root/04-zabbix-hosts.py
echo "== TODO LISTO =="
