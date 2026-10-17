#!/bin/bash
# Finish the v16 upgrade: crm requires the whatsapp app, so install it before crm.
set -e
cd /home/frappe/frappe-bench

[ -d apps/whatsapp ] || git clone --depth 1 https://github.com/frappe/whatsapp.git apps/whatsapp
env/bin/pip install -q -e apps/whatsapp
printf 'frappe\nwhatsapp\ncrm\n' > sites/apps.txt

echo "== Recreating site =="
bench new-site crm.localhost --force --mariadb-root-password 123 --admin-password admin --mariadb-user-host-login-scope='%'
bench --site crm.localhost install-app whatsapp
bench --site crm.localhost install-app crm
bench --site crm.localhost set-config developer_mode 1
bench --site crm.localhost set-config mute_emails 1
bench --site crm.localhost set-config ignore_csrf 1
bench --site crm.localhost set-config server_script_enabled 1
bench --site crm.localhost clear-cache
bench use crm.localhost
echo "== UPGRADE DONE =="
