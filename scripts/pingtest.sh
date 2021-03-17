#!/bin/sh

ALLDEST="google.com yahoo.com 8.8.8.8 1.1.1.1"
COUNT=1
while [ $COUNT -le 3 ]
do

        for DEST in $ALLDEST
        do
                echo  "PINGTEST: Pinging $DEST..." | logger
                ping -c1 $DEST >/dev/null 2>/dev/null
                if [ $? -eq 0 ]
                then
                        echo  "PINGTEST: Ping $DEST OK." | logger
                        exit 0
                fi
        done

        if [ $COUNT -le 1 ]
        then
                echo  "PINGTEST: All pings failed. Resetting WAN interface and waiting 30 seconds for restoration..." | logger
                /usr/local/sbin/pfSsh.php playback restartwan 2> /dev/null
                sleep 30
                echo "PINGTEST: Verifying internet connectivity after WAN reset..." | logger
                for DEST in $ALLDEST
                do
                        echo  "PINGTEST: Pinging $DEST..." | logger
                        ping -c1 $DEST >/dev/null 2>/dev/null
                done
                if [ $? -eq 0 ]
                then
                        MOMENT=`date +%d.%m.%Y@%H:%M:%Sh`
                        echo "PINGTEST: WAN interface has been reset successfully." | logger
                        printf "PINGTEST: WAN interface has been reset successfully.\n\nReconnected at $MOMENT" | /usr/local/bin/mail.php -s"pfSense - WAN Reconnected"
                        exit 0
                fi

        fi

        if [ $COUNT -le 2 ]
        then
                echo "PINGTEST: Some pings still failing after WAN interface reset. Now power cycling the modem." | logger
                echo "PINGTEST: Cutting power to the modem..." | logger
                ssh root@192.168.1.25 tuya-cli set --ip 192.168.1.250 --id [XXXXXXXX] --key [XXXXXXXX] --set false --dps 1
                if [ $? -eq 0 ]
                then
                        echo "PINGTEST: Successfully cut power to the modem!" | logger
                        echo "PINGTEST: Restoring modem power..." | logger
                        ssh root@192.168.1.25 tuya-cli set --ip 192.168.1.250 --id [XXXXXXXX] --key [XXXXXXXX] --set true --dps 1
                        if [ $? -eq 0 ]
                        then
                                echo "PINGTEST: Successfully restored power to the modem!" | logger
                                echo "PINGTEST: Waiting 60 seconds for modem to come back up..." | logger
                                sleep 60
                                echo  "PINGTEST: Resetting WAN interface and waiting 30 seconds for restoration..." | logger
                                /usr/local/sbin/pfSsh.php playback restartwan 2> /dev/null
                                sleep 30
                                echo "PINGTEST: Verifying internet connectivity after modem and WAN resets..." | logger
                                for DEST in $ALLDEST
                                do
                                        echo  "PINGTEST: Pinging $DEST..." | logger
                                        ping -c1 $DEST >/dev/null 2>/dev/null
                                done
                                if [ $? -eq 0 ]
                                then
                                        MOMENT=`date +%d.%m.%Y@%H:%M:%Sh`
                                        echo "PINGTEST: Both modem and WAN interface have been reset successfully." | logger
                                        printf "PINGTEST: Both modem and WAN interface have been reset successfully.\n\nReconnected at $MOMENT" | /usr/local/bin/mail.php -s"pfSense - Modem Reset, WAN Reconnected"
                                        exit 0
                                else
                                        echo "PINGTEST: Both modem and WAN interface resets have failed to restore internet connectivity!" | logger
                                        exit 1
                                fi
                        fi
                else
                        echo "PINGTEST: Failed to power off modem!" | logger
                        exit 1
                fi
        fi

COUNT=`expr $COUNT + 1`
