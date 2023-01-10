#!/usr/bin/env bash

RED='\033[0;91m'
GREEN='\033[0;92m'
NC='\033[0m'
DISKS=0
NVME_DISK=false
USB_DISK=false

execution_layer="geth erigon besu nethermind"
consensus_layer="prysm-beacon teku lighthouse-beacon nimbus"
readonly consensus_layer execution_layer

consensus_is_running=false
execution_is_running=false

# Check if the user is root
if [ "$(id -u)" != "0" ]; then
   # If the user is not root, print an error message and exit
   echo -e "Error: ${RED}You must be Root to run this script${NC}. please run sudo eoa_check.sh" 
   exit 1
fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

# Check Ethereum user
if id "ethereum" >/dev/null 2>&1
then
	echo -e "Ethereum user check ${GREEN}✓${NC} ethereum user exists"
else
	echo -e "${RED}User ethereum does not exist, installation failed${NC}. Please see /var/log for more info"
fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

for c in ${consensus_layer} 
do
	if (systemctl is-active --quiet $c)
	then
		echo -e "Consensus Layer check ${GREEN}✓${NC} $c service is running"
		consensus_is_running=true
		continue		
	fi
done

for e in ${execution_layer} 
do
	if (systemctl is-active --quiet $e)
	then
		echo -e "Execution Layer check ${GREEN}✓${NC} $e service is running"
		execution_is_running=true
		continue		
	fi
done

if [ "${consensus_is_running}" = false ]
then
	echo -e "Error: ${RED}No Consensus Client is running${NC}. Please, start a Consensus Layer client"
	exit 0
fi

if [ "${execution_is_running}" = false ]
then
	echo -e "${RED}No Execution Client is running${NC}. Please, start an Execution Layer client"
	exit 0
fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

# Check JWT file
if test -s "/etc/ethereum/jwtsecret"; then
    echo -e "JWT secret file check ${GREEN}✓${NC} File exists and it is not empty"
else
    echo -e "${RED}The file /etc/ethereum/jwtsecret does not exist or it is empty${NC}"
fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

# Check 8551 port
if nc -z localhost 8551; then
    echo -e "Port 8551 check ${GREEN}✓${NC} Port is listening and accepting connections"
else
    echo -e "${RED}Port 8551 is not open. Execution Layer and Consensus Layer cannot communicate between${NC}"
fi

# Check if device '/dev/sda' exists
if [ -e "/dev/sda" ]; then
  DISKS=$((DISKS+1))
  USB_DISK=true
fi

# Check if device '/dev/nvme0n1' exists
if [ -e "/dev/nvme0n1" ]; then
  DISKS=$((DISKS+1))
  NVME_DISK=true
fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

if [ $DISKS -eq 0 ]; then
  echo -e "${RED}Error: There are no SSD disks present or mounted${NC}. Please review your set up or /etc/fstab config."
  exit 1
else
  echo -e "Disk check ${GREEN}✓${NC} External disk detected"
fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

lsblk

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

if [[ $USB_DISK == true ]]
then
	echo -e "The USB SSD disk model is `smartctl -a /dev/sda | grep "Model Number" | awk '{ $1=$2="";$0=$0;} NF=NF'`"
fi
if [[ $NVME_DISK == true ]]
then
	echo -e "The NVME Disk model is `smartctl -a /dev/nvme0n1 | grep "Model Number" | awk '{ $1=$2="";$0=$0;} NF=NF'`"
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