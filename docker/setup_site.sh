#!/bin/bash
set -e

# Disable SSL requirement for MariaDB client
cat << 'EOF' > /home/frappe/.my.cnf
[client]
skip-ssl
EOF

cd /home/frappe/frappe-bench

echo "Creating crm.localhost site..."
bench new-site crm.localhost \
    --force \
    --mariadb-root-password 123 \
    --admin-password admin \
    --mariadb-user-host-login-scope='%'

echo "Installing CRM app..."
bench --site crm.localhost install-app crm
bench --site crm.localhost set-config developer_mode 1
bench --site crm.localhost set-config mute_emails 1
bench --site crm.localhost set-config ignore_csrf 1
bench --site crm.localhost set-config server_script_enabled 1
bench --site crm.localhost clear-cache
bench use crm.localhost

echo "Site setup completed successfully!"
