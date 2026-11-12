#!/bin/bash
set -e
apt-get install -y apt-transport-https software-properties-common wget gnupg
mkdir -p /etc/apt/keyrings
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor --yes -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y grafana
grafana-cli plugins install alexanderzobnin-zabbix-app || grafana cli plugins install alexanderzobnin-zabbix-app
systemctl daemon-reload
systemctl enable grafana-server
systemctl restart grafana-server
GF="http://admin:admin@127.0.0.1:3000"
echo ">> Esperando a Grafana..."
until curl -s http://127.0.0.1:3000/api/health | grep -q ok; do sleep 3; done
curl -s -X POST -H "Content-Type: application/json" "$GF/api/plugins/alexanderzobnin-zabbix-app/settings" \
  -d '{"enabled":true,"pinned":true,"jsonData":{}}'; echo
curl -s -X POST -H "Content-Type: application/json" "$GF/api/datasources" -d '{
  "name":"Zabbix","uid":"zabbix","type":"alexanderzobnin-zabbix-datasource","access":"proxy",
  "url":"http://127.0.0.1/zabbix/api_jsonrpc.php","isDefault":true,
  "jsonData":{"authType":"userLogin","username":"Admin","trends":true},
  "secureJsonData":{"password":"zabbix"}}'; echo
cat > /root/dashboard-redes2.json <<'JSON'
{
 "dashboard": {
  "uid": "redes2",
  "title": "Redes II - Estado de la red",
  "tags": [
   "redes2"
  ],
  "timezone": "browser",
  "schemaVersion": 39,
  "refresh": "30s",
  "time": {
   "from": "now-1h",
   "to": "now"
  },
  "panels": [
   {
    "id": 1,
    "type": "stat",
    "title": "Estado ICMP por equipo",
    "gridPos": {
     "x": 0,
     "y": 0,
     "w": 24,
     "h": 8
    },
    "datasource": {
     "type": "alexanderzobnin-zabbix-datasource",
     "uid": "zabbix"
    },
    "targets": [
     {
      "refId": "A",
      "datasource": {
       "type": "alexanderzobnin-zabbix-datasource",
       "uid": "zabbix"
      },
      "queryType": "0",
      "group": {
       "filter": "Redes2"
      },
      "host": {
       "filter": "/.*/"
      },
      "application": {
       "filter": ""
      },
      "itemTag": {
       "filter": ""
      },
      "item": {
       "filter": "ICMP ping"
      },
      "functions": [],
      "options": {
       "showDisabledItems": false,
       "skipEmptyValues": false
      }
     }
    ],
    "options": {
     "reduceOptions": {
      "calcs": [
       "lastNotNull"
      ],
      "fields": "",
      "values": false
     },
     "colorMode": "background",
     "graphMode": "none",
     "textMode": "value_and_name",
     "orientation": "auto",
     "justifyMode": "auto"
    },
    "fieldConfig": {
     "defaults": {
      "mappings": [
       {
        "type": "value",
        "options": {
         "0": {
          "text": "CAÍDO",
          "color": "red",
          "index": 0
         },
         "1": {
          "text": "EN LÍNEA",
          "color": "green",
          "index": 1
         }
        }
       }
      ],
      "thresholds": {
       "mode": "absolute",
       "steps": [
        {
         "color": "red",
         "value": null
        },
        {
         "color": "green",
         "value": 1
        }
       ]
      }
     },
     "overrides": []
    }
   },
   {
    "id": 2,
    "type": "alexanderzobnin-zabbix-triggers-panel",
    "title": "Problemas activos (Zabbix)",
    "gridPos": {
     "x": 0,
     "y": 8,
     "w": 12,
     "h": 10
    },
    "datasource": {
     "type": "alexanderzobnin-zabbix-datasource",
     "uid": "zabbix"
    },
    "targets": [
     {
      "refId": "A",
      "datasource": {
       "type": "alexanderzobnin-zabbix-datasource",
       "uid": "zabbix"
      },
      "queryType": "5",
      "group": {
       "filter": "/.*/"
      },
      "host": {
       "filter": "/.*/"
      },
      "application": {
       "filter": ""
      },
      "itemTag": {
       "filter": ""
      },
      "proxy": {
       "filter": ""
      },
      "trigger": {
       "filter": ""
      },
      "tags": {
       "filter": ""
      },
      "showProblems": "problems",
      "options": {
       "minSeverity": 0,
       "acknowledged": 2,
       "sortProblems": "default",
       "limit": 100,
       "hostsInMaintenance": false
      }
     }
    ]
   },
   {
    "id": 3,
    "type": "timeseries",
    "title": "Latencia ICMP",
    "gridPos": {
     "x": 12,
     "y": 8,
     "w": 12,
     "h": 10
    },
    "datasource": {
     "type": "alexanderzobnin-zabbix-datasource",
     "uid": "zabbix"
    },
    "targets": [
     {
      "refId": "A",
      "datasource": {
       "type": "alexanderzobnin-zabbix-datasource",
       "uid": "zabbix"
      },
      "queryType": "0",
      "group": {
       "filter": "Redes2"
      },
      "host": {
       "filter": "/.*/"
      },
      "application": {
       "filter": ""
      },
      "itemTag": {
       "filter": ""
      },
      "item": {
       "filter": "ICMP response time"
      },
      "functions": [],
      "options": {
       "showDisabledItems": false,
       "skipEmptyValues": false
      }
     }
    ],
    "fieldConfig": {
     "defaults": {
      "unit": "s"
     },
     "overrides": []
    }
   },
   {
    "id": 4,
    "type": "timeseries",
    "title": "Tráfico de R2 (borde / NAT)",
    "gridPos": {
     "x": 0,
     "y": 18,
     "w": 12,
     "h": 9
    },
    "datasource": {
     "type": "alexanderzobnin-zabbix-datasource",
     "uid": "zabbix"
    },
    "targets": [
     {
      "refId": "A",
      "datasource": {
       "type": "alexanderzobnin-zabbix-datasource",
       "uid": "zabbix"
      },
      "queryType": "0",
      "group": {
       "filter": "Redes2"
      },
      "host": {
       "filter": "R2-PAMPLONA"
      },
      "application": {
       "filter": ""
      },
      "itemTag": {
       "filter": ""
      },
      "item": {
       "filter": "/Bits (received|sent)/"
      },
      "functions": [],
      "options": {
       "showDisabledItems": false,
       "skipEmptyValues": false
      }
     }
    ],
    "fieldConfig": {
     "defaults": {
      "unit": "bps"
     },
     "overrides": []
    }
   },
   {
    "id": 5,
    "type": "bargauge",
    "title": "Pérdida de paquetes ICMP",
    "gridPos": {
     "x": 12,
     "y": 18,
     "w": 12,
     "h": 9
    },
    "datasource": {
     "type": "alexanderzobnin-zabbix-datasource",
     "uid": "zabbix"
    },
    "targets": [
     {
      "refId": "A",
      "datasource": {
       "type": "alexanderzobnin-zabbix-datasource",
       "uid": "zabbix"
      },
      "queryType": "0",
      "group": {
       "filter": "Redes2"
      },
      "host": {
       "filter": "/.*/"
      },
      "application": {
       "filter": ""
      },
      "itemTag": {
       "filter": ""
      },
      "item": {
       "filter": "ICMP loss"
      },
      "functions": [],
      "options": {
       "showDisabledItems": false,
       "skipEmptyValues": false
      }
     }
    ],
    "options": {
     "reduceOptions": {
      "calcs": [
       "lastNotNull"
      ],
      "fields": "",
      "values": false
     },
     "orientation": "horizontal",
     "displayMode": "gradient"
    },
    "fieldConfig": {
     "defaults": {
      "unit": "percent",
      "min": 0,
      "max": 100,
      "thresholds": {
       "mode": "absolute",
       "steps": [
        {
         "color": "green",
         "value": null
        },
        {
         "color": "orange",
         "value": 20
        },
        {
         "color": "red",
         "value": 50
        }
       ]
      }
     },
     "overrides": []
    }
   }
  ]
 },
 "overwrite": true
}
JSON
curl -s -X POST -H "Content-Type: application/json" "$GF/api/dashboards/db" -d @/root/dashboard-redes2.json; echo
echo ">> Grafana listo: dashboard /d/redes2"
