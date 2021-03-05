#! /bin/sh
#Check config var streamboost_enable every hour
update_count=0
while :; do
	sleep 60
	update_count=$(($update_count + 1))
	if [ $update_count = 3 ]; then
		update_count=0
		if [ "x`/bin/config get enable_circle_plc`" = "x1" -a "x`/bin/config get ap_mode`" = "x0" ]; then
			/bin/config set "save_circle_info=1"
			killall -SIGUSR1 net-scan
		fi
	fi

#	if [ "$update_count" = "1" ]; then
#		new_whatchdog_value=`cat /tmp/soapclient/watchdog_time`
#		if [ "$(cat /tmp/orbi_type)" = "Base" ] && [ "$new_whatchdog_value" = "$old_whatchdog_value" ]; then
#			echo "********soap_agent watchdog restarting*********" 
#			killall -9 soap_agent
#			time=`date '+%Y-%m-%dT%H:%M:%SZ'`
#			echo "Watchdog Restart soap_agent:$time" >> /var/log/soapclient/soap_agent_restart
#			/usr/sbin/soap_agent &
#		fi
#		old_whatchdog_value=$new_whatchdog_value
#	fi
	
	detcable_status=`ps | grep detcable | grep -v grep`
	if [ -z "$detcable_status" ] && [ "$(cat /tmp/orbi_type)" = "Base" ];then
		killall detcable
		time=`date '+%Y-%m-%dT%H:%M:%SZ'`
		echo "Restart detcable:$time" >> /tmp/restart_process_list
		/usr/bin/detcable 2 Base &
	fi
	
	dnsmasq_status=`ps | grep dnsmasq | grep -v grep`
	if [ -z "$dnsmasq_status" ] && [ "$(cat /tmp/orbi_type)" = "Base" ];then
		killall dnsmasq
		time=`date '+%Y-%m-%dT%H:%M:%SZ'`
		echo "Restart dnsmasq:$time" >> /tmp/restart_process_list
		/etc/init.d/dnsmasq start&
	fi

#	netscan_status=`ps | grep net-scan | grep -v grep | grep -v killall`
#	if [ -z "$netscan_status" ];then
#		killall -9 net-scan
#		time=`date '+%Y-%m-%dT%H:%M:%SZ'`
#		echo "Restart net-scan:$time" >> /tmp/restart_process_list
#		/usr/sbin/net-scan
#	fi

#	orbi_type=`cat /tmp/orbi_type`
#	fing_status=`ps | grep fing-devices | grep -v grep | grep -v killall`
#	if [ -z "$fing_status" -a "$orbi_type" = "Base" ];then
#		killall -9 fing-devices
#		time=`date '+%Y-%m-%dT%H:%M:%SZ'`
#		echo "Restart fing-devices:$time" >> /tmp/restart_process_list
#		/usr/sbin/fing-devices 2> /dev/null
#	fi

	log_size=`wc -c /tmp/dnsmasq.log |awk '{print $1}'`
	if [ $log_size -gt 1048576 ]; then
		echo -n > /tmp/dnsmasq.log
	fi
	if [ "x`/bin/config get wan_proto`" != "xmulpppoe1" ];then
		pppdv4_ps_count=`ps  |grep "pppd call dial-provider updetach" | grep -v grep |wc -l`
		pppdv6_ps_count=`ps  |grep "pppd call pppoe-ipv6 updetach" | grep -v grep |wc -l`
		if [ $pppdv4_ps_count -gt "1" -o $pppdv6_ps_count -gt "1" ] ;then
			killall pppd
			if [ $pppdv4_ps_count -gt "0" ];then
				pppd call dial-provider updetach
			fi
			if [ $pppdv6_ps_count -gt "0" ];then
                                /usr/sbin/pppd call pppoe-ipv6 updetach
                        fi
		fi
	fi

	if [ "x`/bin/config get lan_dhcp`" != "x0" ];then
		dhcpd_count=`ps | grep "udhcpd /tmp/udhcpd.conf" | grep -v grep | wc -l`
		if [ $dhcpd_count -gt "1" ]; then
			killall udhcpd
			echo "Find multiple udhcpd process, killall & restart!!!" >/dev/console
			time=`date '+%Y-%m-%dT%H:%M:%SZ'`
			echo "Restart net-lan:$time" >> /tmp/restart_process_list
			/etc/init.d/net-lan restart
		fi
	fi

	pingntgr_count=`ps | grep "/sbin/ping-netgear" | grep -v grep | wc -l`
	if [ "$pingntgr_count" != "1" ] && [ "$(cat /tmp/orbi_type)" = "Base" ]; then
		killall ping-netgear
		echo "Restart ping-netgear process!!!" > /dev/console
		/sbin/ping-netgear &
	fi

	pinggate_count=`ps | grep "/sbin/ping-gateway" | grep -v grep | wc -l`
	if [ "$pinggate_count" != "1" ] && [ "$(cat /tmp/orbi_type)" = "Base" ]; then
		killall ping-gateway
		echo "Restart ping-gateway process!!!" > /dev/console
		/sbin/ping-gateway &
	fi

	tail_count=`ps | grep "tail -F /tmp/cloud_backend_log" | grep -v grep | wc -l`
	if [ "x`/bin/config get enable_tail_cfu`" = "x1" ] && [ "$(cat /tmp/orbi_type)" = "Base" ] && [ "$tail_count" != "1" ]; then
		killall tail -F /tmp/cloud_backend_log
		echo "Restart tail -F /tmp/cloud_backend_log process!!!" > /dev/console
		tail -F /tmp/cloud_backend_log &
	elif [ "x`/bin/config get enable_tail_cfu`" != "x1" ] && [ "$tail_count" != "0" ];then
		killall tail -F /tmp/cloud_backend_log
		echo "Restart tail -F /tmp/cloud_backend_log process!!!" > /dev/console
	fi

done

