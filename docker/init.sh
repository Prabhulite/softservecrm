#!/bin/bash
set -e

cd /home/frappe/frappe-bench

# Ensure sites/apps.txt exists
cat << 'EOF' > /home/frappe/frappe-bench/sites/apps.txt
frappe
crm
EOF

# Use containers instead of localhost
bench set-mariadb-host mariadb
bench set-redis-cache-host redis://redis:6379
bench set-redis-queue-host redis://redis:6379
bench set-redis-socketio-host redis://redis:6379

# Remove redis, watch, and socketio from Procfile
sed -i '/redis/d' ./Procfile
sed -i '/watch/d' ./Procfile
sed -i '/socketio/d' ./Procfile

if [ ! -d "/home/frappe/frappe-bench/sites/crm.localhost" ]; then
    echo "Waiting for MariaDB to be ready on port 3306..."
    python3 -c '
import socket, time
while True:
    try:
        s = socket.socket()
        s.settimeout(2)
        s.connect(("mariadb", 3306))
        s.close()
        print("Connected to MariaDB successfully!")
        break
    except Exception:
        time.sleep(1)
'
    echo "Creating crm.localhost site..."
    bench new-site crm.localhost \
        --force \
        --mariadb-root-password 123 \
        --admin-password admin \
        --mariadb-user-host-login-scope='%'

    bench --site crm.localhost install-app crm
    bench --site crm.localhost set-config developer_mode 1
    bench --site crm.localhost set-config mute_emails 1
    bench --site crm.localhost set-config ignore_csrf 1
    bench --site crm.localhost set-config server_script_enabled 1
    bench --site crm.localhost clear-cache
    bench use crm.localhost
fi

echo "Starting bench..."
bench start