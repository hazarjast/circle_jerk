#!/bin/sh

ALLDEST="google.com cloudflare.com"
LOCKCELL="1,[EARCFN],[PCID]"
INTERVAL=900
CELLFAIL=0
LOG="/var/log/cell_lock_failsafe"

# Added below 2 minute wait before first run for those calling the script from 'rc.local'
# If not running on device startup, you can comment out this sleep command.
sleep 120

pinger ()
{
CONNECTED=0
for DEST in $ALLDEST
do
  if [ $CONNECTED -eq 0 ]
  then
      echo  "$(date) -  Checking Internet connectivity by pinging $DEST..." >> $LOG
      ping -c1 $DEST >/dev/null 2>/dev/null
      if [ $? -eq 0 ]
      then
          CONNECTED=1
      fi
  fi
done
}

while true
do
  pinger
  
  if [ $CONNECTED -eq 1 ]
  then
      echo  "$(date) -  Internet connectivity OK." >> $LOG
      if [ $CELLFAIL -eq 0 ]
      then
          echo  "$(date) -  Checking if cell is locked..." >> $LOG
          if echo -ne "AT+QNWLOCK=\"common/4g\"\r\n" | microcom -X -t 1000 /dev/ttyUSB2 | grep -q '"common/4g",0'
          then
	      echo  "$(date) -  Cell not locked. Setting lock to $LOCKCELL..." >> $LOG
	      echo -ne "AT+QNWLOCK=\"common/4g\",$LOCKCELL\r\n" | microcom -X -t 1000 /dev/ttyUSB2 >/dev/null 2>/dev/null
              echo  "$(date) -  Cell locked, waiting 30 seconds for reconnect..." >> $LOG
	      sleep 30
	      pinger
              if [ $CONNECTED -eq 1 ]
              then
                  echo  "$(date) -  Internet reachable, cell lock successful!" >> $LOG
	      else
	          CELLFAIL=`expr $CELLFAIL + 1`    
              fi  
          else
	      echo  "$(date) -  Cell is already locked." >> $LOG
          fi  
      fi  
  fi
	
  if [ $CONNECTED -eq 0 ]
  then
      echo "$(date) -  No Internet connectivity. Removing cell lock..." >> $LOG
      echo -ne "AT+QNWLOCK=\"common/4g\",0\r\n" | microcom -X -t 1000 /dev/ttyUSB2 >/dev/null 2>/dev/null
      echo "$(date) -  Cell lock removed, waiting one minute for reconnect..." >> $LOG
      sleep 60
      pinger
      if [ $CONNECTED -eq 1 ]
      then
          echo "$(date) -  Internet is accessible again!" >> $LOG
	  if [ $CELLFAIL -ge 2 ]
	  then
              MIDNIGHT=`echo $(($(date -d 23:59:59 +%s) - $(date +%s) + 1))`
	      echo  "$(date) -  Locking to selected cell disrupted Internet connectivity twice in the last hour." >> $LOG
	      echo  "$(date) -  Waiting until tomorrow before attempting to lock the preferred cell again." >> $LOG
	      sleep $MIDNIGHT
	      CELLFAIL=0
	  fi
      else
          echo "$(date) -  Internet connectivity could not be restored!" >> $LOG
      fi
  fi

sleep $INTERVAL
echo "$(tail -1000 $LOG)" > $LOG

done
