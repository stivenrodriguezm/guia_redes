#!/usr/bin/env python3
import json, sys, urllib.request
URL = "http://127.0.0.1/zabbix/api_jsonrpc.php"
USER, PASS, GRUPO = "Admin", "zabbix", "Redes2"
HOSTS = [  # nombre, IP de monitoreo, tipo
    ("R1-PAMPLONA",        "192.168.15.1",  "cisco"),
    ("R2-PAMPLONA",        "192.168.99.1",  "cisco"),
    ("R3-PAIPA",           "172.16.3.1",    "cisco"),
    ("R4-BUCARAMANGA",     "172.16.4.1",    "cisco"),
    ("R5-BARRANCABERMEJA", "172.16.5.1",    "cisco"),
    ("R6-CUCUTA",          "172.16.6.1",    "cisco"),
    ("R7-BOGOTA",          "172.16.7.1",    "cisco"),
    ("R8-MEDELLIN",        "192.168.50.1",  "cisco"),
    ("R9-TUNJA",           "192.168.5.1",   "cisco"),
    ("R10-DUITAMA",        "192.168.6.1",   "cisco"),
    ("R11-SOGAMOSO",       "192.168.7.1",   "mikrotik"),
    ("SW1",                "192.168.40.2",  "cisco"),
    ("SW2",                "192.168.40.3",  "cisco"),
    ("WEB-SERVER",         "192.168.30.2",  "cisco"),
    ("DNS1",               "192.168.20.3",  "cisco"),
    ("DHCP-SRV",           "192.168.10.2",  "cisco"),
    ("PC-MEDELLIN",        "192.168.50.10", "icmp"),
    ("PC-11",              "192.168.7.13",  "icmp"),
    ("CISCOIP-1",          "192.168.15.10", "icmp"),
]

def api(method, params, tok=None):
    body = json.dumps({"jsonrpc": "2.0", "method": method, "params": params, "id": 1}).encode()
    req = urllib.request.Request(URL, body, {"Content-Type": "application/json-rpc"})
    if tok:
        req.add_header("Authorization", "Bearer " + tok)
    res = json.load(urllib.request.urlopen(req, timeout=30))
    if "error" in res:
        raise RuntimeError(method + ": " + str(res["error"].get("data", res["error"])))
    return res["result"]

tok = api("user.login", {"username": USER, "password": PASS})
g = api("hostgroup.get", {"output": ["groupid"], "filter": {"name": [GRUPO]}}, tok)
gid = g[0]["groupid"] if g else api("hostgroup.create", {"name": GRUPO}, tok)["groupids"][0]

def plantilla(nombre):
    t = api("template.get", {"output": ["templateid"], "filter": {"host": [nombre]}}, tok)
    if not t:
        sys.exit("ERROR: no existe la plantilla " + nombre)
    return t[0]["templateid"]

T = {"icmp": plantilla("ICMP Ping"), "cisco": plantilla("Cisco IOS by SNMP"),
     "gen": plantilla("Network Generic Device by SNMP")}
TPL = {"cisco": ["icmp", "cisco"], "mikrotik": ["icmp", "gen"], "icmp": ["icmp"]}

for nombre, ip, tipo in HOSTS:
    if api("host.get", {"output": ["hostid"], "filter": {"host": [nombre]}}, tok):
        print("= ya existe:", nombre)
        continue
    if tipo == "icmp":
        iface = {"type": 1, "main": 1, "useip": 1, "ip": ip, "dns": "", "port": "10050"}
    else:
        iface = {"type": 2, "main": 1, "useip": 1, "ip": ip, "dns": "", "port": "161",
                 "details": {"version": 2, "bulk": 1, "community": "{$SNMP_COMMUNITY}"}}
    api("host.create", {"host": nombre, "groups": [{"groupid": gid}], "interfaces": [iface],
                        "templates": [{"templateid": T[x]} for x in TPL[tipo]],
                        "macros": [{"macro": "{$SNMP_COMMUNITY}", "value": "redes2"}]}, tok)
    print("+ creado:", nombre, ip)

def chequeo(host, key, tipo, nombre, desc):
    h = api("host.get", {"output": ["hostid"], "selectInterfaces": ["interfaceid"],
                         "filter": {"host": [host]}}, tok)
    if not h:
        print("! no existe el host", host)
        return
    api("host.update", {"hostid": h[0]["hostid"], "status": 0}, tok)
    try:
        api("item.create", {"name": nombre, "key_": key, "hostid": h[0]["hostid"], "type": tipo,
                            "value_type": 3, "delay": "1m",
                            "interfaceid": h[0]["interfaces"][0]["interfaceid"]}, tok)
        api("trigger.create", {"description": desc, "priority": 4,
                               "expression": "last(/%s/%s)=0" % (host, key)}, tok)
        print("+ chequeo de servicio:", nombre)
    except RuntimeError as e:
        print("= chequeo ya existente:", nombre, "-", e)

chequeo("WEB-SERVER", "net.tcp.service[http,192.168.30.2,80]", 3,
        "Servicio HTTP del servidor web", "Servicio WEB caido en WEB-SERVER")
chequeo("Zabbix server", "net.dns[192.168.20.3,www.redes2.local,A,2,1]", 0,
        "Resolucion DNS www.redes2.local", "Servicio DNS no responde en DNS1")
print("\nListo. Revisa Monitoring > Hosts (grupo Redes2). SNMP tarda 1-3 min en ponerse verde.")
