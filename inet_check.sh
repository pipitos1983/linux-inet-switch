#!/bin/bash

. .env

date +%Y%m%d-%H:%M >> $LOG

# Параллельная проверка каналов
function chan_check {

/bin/ping -c 10 -I $PRIMARY_ADDR $CHECK_HOST |grep transmitted|awk '{print $4}' > /tmp/primary_status &
PRIMARY_PID=$!

/bin/ping -c 10 -I $BACKUP_ADDR $CHECK_HOST |grep transmitted|awk '{print $4}' > /tmp/backup_status &
BACKUP_PID=$!

# Ожидание завершения фоновых задач
wait $PRIMARY_PID $BACKUP_PID

PRIMARY_STATUS=$(cat /tmp/primary_status)
BACKUP_STATUS=$(cat /tmp/backup_status)

}

chan_check

# проверяем текущий основной канал и выполняем переключение если необходимо.
CURRENT_GW=$(/bin/ip route | grep default | awk '{print $3}')


if [ "$CURRENT_GW" == "$PRIMARY_GW" ] && (( $BACKUP_STATUS > $PRIMARY_STATUS )); then
 	echo "PRIMARY PACKAGES: $PRIMARY_STATUS" >> $LOG
    echo "BACKUP  PACKAGES: $BACKUP_STATUS" >> $LOG
	echo "SECOND CHECK..."
	# Дополнительная проверка 
	chan_check
 	echo "PRIMARY PACKAGES: $PRIMARY_STATUS" >> $LOG
    echo "BACKUP  PACKAGES: $BACKUP_STATUS" >> $LOG

	if [ $BACKUP_STATUS -gt $PRIMARY_STATUS ]; then 
		echo "change default gateway to backup" >> $LOG
 		/usr/sbin/ip route replace default scope global nexthop via $BACKUP_GW dev $BACKUP_IF;
	fi
    exit 0
fi

if [ "$CURRENT_GW" == "$BACKUP_GW" ] && (( $BACKUP_STATUS <= $PRIMARY_STATUS )); then
 	echo "PRIMARY PACKAGES: $PRIMARY_STATUS" >> $LOG
    echo "BACKUP  PACKAGES: $BACKUP_STATUS" >> $LOG

 	echo "change default gateway to primary" >> $LOG
 	/usr/sbin/ip route replace default scope global nexthop via $PRIMARY_GW dev $PRIMARY_IF;
    exit 0
fi

echo "no actions" >> $LOG
