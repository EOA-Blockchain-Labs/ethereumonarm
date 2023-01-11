#!/usr/bin/env bash

red='\033[0;91m'
green='\033[0;92m'
nc='\033[0m'
disks=0
nvme_disk=false
usb_disk=false

execution_layer="geth erigon besu nethermind"
consensus_layer="prysm-beacon teku lighthouse-beacon nimbus"
readonly consensus_layer execution_layer

consensus_is_running=false
execution_is_running=false

# Check if the user is root
if [ "$(id -u)" != "0" ]; then
	# If the user is not root, print an error message and exit
	echo -e "Error: ${red}You must be Root to run this script${nc}. please run sudo eoa_check.sh"
	exit 1
fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

# Check Ethereum user
if id "ethereum" >/dev/null 2>&1; then
	echo -e "Ethereum user check ${green}✓${nc} ethereum user exists"
else
	echo -e "${red}User ethereum does not exist, installation failed${nc}. Please see /var/log for more info"
fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

for c in ${consensus_layer}; do
	if (systemctl is-active --quiet "$c"); then
		echo -e "Consensus Layer check ${green}✓${nc} $c service is running"
		consensus_is_running=true
		continue
	fi
done

for e in ${execution_layer}; do
	if (systemctl is-active --quiet "$e"); then
		echo -e "Execution Layer check ${green}✓${nc} $e service is running"
		execution_is_running=true
		continue
	fi
done

if [ "${consensus_is_running}" = false ]; then
	echo -e "Error: ${red}No Consensus Client is running${nc}. Please, start a Consensus Layer client"
	exit 0
fi

if [ "${execution_is_running}" = false ]; then
	echo -e "${red}No Execution Client is running${nc}. Please, start an Execution Layer client"
	exit 0
fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

# Check JWT file
if test -s "/etc/ethereum/jwtsecret"; then
	echo -e "JWT secret file check ${green}✓${nc} File exists and it is not empty"
else
	echo -e "${red}The file /etc/ethereum/jwtsecret does not exist or it is empty${nc}"
fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

# Check 8551 port
if nc -z localhost 8551; then
	echo -e "Port 8551 check ${green}✓${nc} Port is listening and accepting connections"
else
	echo -e "${red}Port 8551 is not open. Execution Layer and Consensus Layer cannot communicate between${nc}"
fi

# Check if device '/dev/sda' exists
if [ -e "/dev/sda" ]; then
	disks=$((disks + 1))
	usb_disk=true
fi

# Check if device '/dev/nvme0n1' exists
if [ -e "/dev/nvme0n1" ]; then
	disks=$((disks + 1))
	nvme_disk=true
fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

if [ $disks -eq 0 ]; then
	echo -e "${red}Error: There are no SSD disks present or mounted${nc}. Please review your set up or /etc/fstab config."
	exit 1
else
	echo -e "Disk check ${green}✓${nc} External disk detected"
fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

lsblk

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

if [[ $usb_disk == true ]]; then
	echo -e "The USB SSD disk model is $(smartctl -a /dev/sda | grep "Model Number" | awk '{ $1=$2="";$0=$0;} NF=NF')"
fi
if [[ $nvme_disk == true ]]; then
	echo -e "The NVME Disk model is $(smartctl -a /dev/nvme0n1 | grep "Model Number" | awk '{ $1=$2="";$0=$0;} NF=NF')"
fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

top -bcn 1

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

ss -tunlp

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

curl ifconfig.co/port/30303 -w "\n"
curl ifconfig.co/port/9000 -w "\n"

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

tail -n 100 /var/log/syslog

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

grep -hoP '(?<=Package: ).+' /var/lib/apt/lists/apt.ethraspbian.com_dists_focal_* | tr '\n' ' '

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

awk '{printf ("%0.2f\n",$1/172.41); }' < /sys/devices/iio_sysfs_trigger/subsystem/devices/iio\:device0/in_voltage6_raw

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

cat /sys/class/thermal/thermal_zone0/temp