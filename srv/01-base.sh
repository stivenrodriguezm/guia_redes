#!/bin/bash
set -e
IF=$(ip -o -4 route show to default | awk '{print $5}' | head -1)
[ -z "$IF" ] && IF=$(ls /sys/class/net | grep -v '^lo$' | head -1)
echo ">> Interfaz detectada: $IF"
hostnamectl set-hostname srv-mon
mkdir -p /etc/cloud/cloud.cfg.d /root/netplan-bak
echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
mv /etc/netplan/*.yaml /root/netplan-bak/ 2>/dev/null || true
cat > /etc/netplan/01-redes2.yaml <<NETPLAN
network:
  version: 2
  ethernets:
    $IF:
      dhcp4: false
      addresses: [192.168.99.10/24]
      routes:
        - to: 0.0.0.0/0
          via: 192.168.99.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
NETPLAN
chmod 600 /etc/netplan/01-redes2.yaml
netplan apply
rm -f /etc/resolv.conf
printf 'nameserver 8.8.8.8\nnameserver 1.1.1.1\n' > /etc/resolv.conf
timedatectl set-timezone America/Bogota || true
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget gnupg ca-certificates fping snmp jq python3 locales
locale-gen es_ES.UTF-8 en_US.UTF-8
echo ">> Base lista"
