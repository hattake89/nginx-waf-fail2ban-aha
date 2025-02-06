#!/bin/bash

F2B_LOG_TARGET=${F2B_LOG_TARGET:-STDOUT}
F2B_LOG_LEVEL=${F2B_LOG_LEVEL:-INFO}
F2B_DB_PURGE_AGE=${F2B_DB_PURGE_AGE:-1d}
IPTABLES_MODE=${IPTABLES_MODE:-auto}

# Init
echo "Initializing files and folders..."
mkdir -p /data/db /data/action.d /data/filter.d /data/jail.d
#ln -sf /data/jail.d /etc/fail2ban/
ln -sf /fail2ban/jail.conf /data/jail.d/
ln -sf /fail2ban/paths-common.conf /data/jail.d/
ln -sf /fail2ban/paths-debian.conf /data/jail.d/
ln -sf /fail2ban/paths-overrides.local /data/jail.d/
ln -sf /fail2ban/jail.local /data/jail.d/
ln -sf /fail2ban/nginx-ddos.conf /data/filter.d/
ln -sf /fail2ban/defaults-debian.conf /data/

# Fail2ban conf
echo "Setting Fail2ban configuration..."
sed -i "s|logtarget =.*|logtarget = $F2B_LOG_TARGET|g" /etc/fail2ban/fail2ban.conf
sed -i "s/loglevel =.*/loglevel = $F2B_LOG_LEVEL/g" /etc/fail2ban/fail2ban.conf
sed -i "s/dbfile =.*/dbfile = \/data\/db\/fail2ban\.sqlite3/g" /etc/fail2ban/fail2ban.conf
sed -i "s/dbpurgeage =.*/dbpurgeage = $F2B_DB_PURGE_AGE/g" /etc/fail2ban/fail2ban.conf
sed -i "s/#allowipv6 =.*/allowipv6 = auto/g" /etc/fail2ban/fail2ban.conf

# default conf
rm -f "/etc/fail2ban/jail.d/defaults-debian.conf"
ln -sf "/data/defaults-debian.conf" "/etc/fail2ban/jail.d/"

# Check custom actions
echo "Checking for custom conf in /data/jail.d..."
confs=$(ls -l /data/jail.d | grep -E '^-' | awk '{print $9}')
for conf in ${confs}; do
  if [ -f "/etc/fail2ban/${conf}" ]; then
    echo "  WARNING: ${conf} already exists and will be overriden"
    rm -f "/etc/fail2ban/${conf}"
  fi
  echo "  Add custom conf ${conf}..."
  ln -sf "/data/jail.d/${conf}" "/etc/fail2ban/"
done

# Check custom actions
echo "Checking for custom actions in /data/action.d..."
actions=$(ls -l /data/action.d | grep -E '^-' | awk '{print $9}')
for action in ${actions}; do
  if [ -f "/etc/fail2ban/action.d/${action}" ]; then
    echo "  WARNING: ${action} already exists and will be overriden"
    rm -f "/etc/fail2ban/action.d/${action}"
  fi
  echo "  Add custom action ${action}..."
  ln -sf "/data/action.d/${action}" "/etc/fail2ban/action.d/"
done

# Check custom filters
echo "Checking for custom filters in /data/filter.d..."
filters=$(ls -l /data/filter.d | grep -E '^-' | awk '{print $9}')
for filter in ${filters}; do
  if [ -f "/etc/fail2ban/filter.d/${filter}" ]; then
    echo "  WARNING: ${filter} already exists and will be overriden"
    rm -f "/etc/fail2ban/filter.d/${filter}"
  fi
  echo "  Add custom filter ${filter}..."
  ln -sf "/data/filter.d/${filter}" "/etc/fail2ban/filter.d/"
done

iptables -V
nft -v

exec "$@"