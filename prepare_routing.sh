#!/bin/bash

. .env

# добавление маршрутов в таблицу для удобства.

grep -q 101 rt_tables || echo "101     primary" >> /etc/iproute2/rt_tables
grep -q 102 rt_tables || echo "102     backup" >> /etc/iproute2/rt_tables

ip route add $LAN_NET dev $LAN_IF table primary
ip route add $BACKUP_NET dev $BACKUP_IF table primary
ip route add $PRIMARY_NET dev $PRIMARY_IF table primary
ip route add default via $PRIMARY_ADDR dev $PRIMARY_IF table primary


ip route add $LAN_NET dev $LAN_IF table backup
ip route add $BACKUP_NET dev $BACKUP_IF table backup
ip route add $PRIMARY_NET dev $PRIMARY_IF table backup
ip route add default via $BACKUP_ADDR dev $BACKUP_IF table backup

ip rule add from $PRIMARY_GW table primary
ip rule add from $BACKUP_GW table backup


