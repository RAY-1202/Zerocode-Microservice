#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${MYSQL_PASSWORD:-}" || -z "${AI_API_KEY:-}" ]]; then
  echo "Required runtime secrets are missing" >&2
  exit 1
fi

install -d -o mysql -g mysql /run/mysqld
if [[ ! -d /var/lib/mysql/mysql ]]; then
  chown -R mysql:mysql /var/lib/mysql
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
fi
mariadbd --user=mysql --bind-address=127.0.0.1 &
until mariadb-admin ping --silent; do sleep 1; done

mariadb <<SQL
CREATE DATABASE IF NOT EXISTS zerocode_microservice CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'zerocode'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
ALTER USER 'zerocode'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON zerocode_microservice.* TO 'zerocode'@'localhost';
FLUSH PRIVILEGES;
SQL
mariadb zerocode_microservice < /app/schema.sql

redis-server --save '' --appendonly no --daemonize yes

(
  until (echo > /dev/tcp/127.0.0.1/8125) 2>/dev/null; do sleep 1; done
  java -jar /app/user.jar &
  exec java -jar /app/screenshot.jar
) &
exec java -jar /app/app.jar
