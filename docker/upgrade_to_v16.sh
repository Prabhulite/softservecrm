#!/bin/bash
# One-off: move the bench from Frappe v15 to Frappe develop (v16) so it matches
# crm's `frappe>=16.0.0-dev` requirement. Run inside the frappe container.
set -e
cd /home/frappe/frappe-bench

PY=/home/frappe/.pyenv/versions/3.14.8/bin/python

echo "== Swapping apps/frappe to develop =="
rm -rf apps/frappe
git clone --depth 1 -b develop https://github.com/frappe/frappe.git apps/frappe

echo "== Recreating virtualenv with Python 3.14 =="
rm -rf env
$PY -m venv env
env/bin/pip install --quiet --upgrade pip
env/bin/pip install --quiet -e apps/frappe
env/bin/pip install --quiet -e apps/crm

echo "== JS deps + assets =="
(cd apps/frappe && yarn install --check-files)
bench build --app frappe

echo "== Recreating site =="
printf 'frappe\ncrm\n' > sites/apps.txt
bench new-site crm.localhost --force --mariadb-root-password 123 --admin-password admin --mariadb-user-host-login-scope='%'
bench --site crm.localhost install-app crm
bench --site crm.localhost set-config developer_mode 1
bench --site crm.localhost set-config mute_emails 1
bench --site crm.localhost set-config ignore_csrf 1
bench --site crm.localhost set-config server_script_enabled 1
bench --site crm.localhost clear-cache
bench use crm.localhost
echo "== UPGRADE DONE =="
