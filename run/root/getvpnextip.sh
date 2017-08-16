#!/bin/bash

# define name servers to connect to in order to get external ip address
google_ip_ns="216.239.32.10"
opendns_ip_ns="208.67.222.222"
retry_count=30

# remove previous run output file
rm -f /home/nobody/vpn_external_ip.txt

# wait for vpn tunnel to come up before proceeding
source /home/nobody/getvpnip.sh

while true; do

	echo "[info] Attempting to get external IP from Google NS..."
	external_ip="$(dig -b ${vpn_ip} TXT +short o-o.myaddr.l.google.com @${google_ip_ns} | tr -d '"')"

	# if error then try secondary name server
	if [[ ! "${external_ip}" ]]; then

		echo "[warn] Failed to get external IP from Google NS, trying OpenDNS..."
		external_ip="$(dig -b ${vpn_ip} +short myip.opendns.com @${opendns_ip_ns})"

		if [[ ! "${external_ip}" ]]; then

			if [ "${retry_count}" -eq "0" ]; then

				external_ip="0.0.0.0"

				echo "[warn] Cannot determine external IP address, exausted retries setting to ${external_ip}"
				break

			else

				retry_count=$((retry_count-1))
				echo "[warn] Cannot determine external IP address, retrying..."
				sleep 1s

			fi

		else

			echo "[info] Successfully retrieved external IP address ${external_ip}"
			break

		fi

	else

		echo "[info] Successfully retrieved external IP address ${external_ip}"
		break

	fi

done

# write external ip address to text file, this is then read by the downloader script
echo "${external_ip}" > /home/nobody/vpn_external_ip.txt

# chmod file to prevent restrictive umask causing read issues for user nobody (owner is user root)
chmod +r /home/nobody/vpn_external_ip.txt
