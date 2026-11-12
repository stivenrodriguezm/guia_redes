#!/bin/bash
# Servidor de monitoreo (secciones 09, 10 y 11 de la guia): descarga los scripts y los corre en segundo plano.
BASE=https://raw.githubusercontent.com/stivenrodriguezm/guia_redes/main/srv
for f in 01-base.sh 02-zabbix.sh 03-grafana.sh 04-zabbix-hosts.py run.sh; do
  curl -4 -fsSL --connect-timeout 15 --max-time 120 "$BASE/$f" -o "/root/$f" || { echo "No pude descargar $f (revisa Internet: ping -c2 8.8.8.8)"; exit 1; }
done
nohup bash /root/run.sh > /root/srv-todo.log 2>&1 < /dev/null &
sleep 2
echo "Instalando en segundo plano (unos 20 min). Ctrl+C sale de esta vista sin detener la instalacion."
echo "Para volver a ver el avance: tail -f /root/srv-todo.log"
echo
tail -f /root/srv-todo.log
