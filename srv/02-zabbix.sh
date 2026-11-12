#!/bin/bash
set -e
. /etc/os-release
DBPASS='Zabbix2026*'
cd /tmp
wget -q -O zabbix-release.deb "https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0+ubuntu${VERSION_ID}_all.deb"
dpkg -i zabbix-release.deb
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y zabbix-server-mysql zabbix-frontend-php \
  zabbix-apache-conf zabbix-sql-scripts zabbix-agent mysql-server fping
systemctl enable --now mysql
mysql -uroot <<SQL
CREATE DATABASE IF NOT EXISTS zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER IF NOT EXISTS 'zabbix'@'localhost' IDENTIFIED BY '${DBPASS}';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
SQL
if ! mysql -uroot -N -e "SHOW TABLES FROM zabbix LIKE 'users'" | grep -q users; then
  echo ">> Importando esquema (tarda 1-3 min)..."
  zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p"${DBPASS}" zabbix
fi
mysql -uroot -e "SET GLOBAL log_bin_trust_function_creators = 0;"
sed -i "s/^# DBPassword=.*/DBPassword=${DBPASS}/" /etc/zabbix/zabbix_server.conf
cat > /etc/zabbix/web/zabbix.conf.php <<PHP
<?php
\$DB['TYPE'] = 'MYSQL'; \$DB['SERVER'] = 'localhost'; \$DB['PORT'] = '0';
\$DB['DATABASE'] = 'zabbix'; \$DB['USER'] = 'zabbix'; \$DB['PASSWORD'] = '${DBPASS}';
\$DB['SCHEMA'] = ''; \$DB['ENCRYPTION'] = false; \$DB['KEY_FILE'] = ''; \$DB['CERT_FILE'] = '';
\$DB['CA_FILE'] = ''; \$DB['VERIFY_HOST'] = false; \$DB['CIPHER_LIST'] = '';
\$DB['VAULT'] = ''; \$DB['VAULT_URL'] = ''; \$DB['VAULT_PREFIX'] = ''; \$DB['VAULT_DB_PATH'] = '';
\$DB['VAULT_TOKEN'] = ''; \$DB['VAULT_CERT_FILE'] = ''; \$DB['VAULT_KEY_FILE'] = '';
\$DB['DOUBLE_IEEE754'] = true;
\$ZBX_SERVER_NAME = 'Redes II - Monitoreo';
\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
PHP
chown www-data:www-data /etc/zabbix/web/zabbix.conf.php
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2
echo ">> Zabbix listo"
