#!/usr/bin/env bash

# Check if the user is root
if [ "$(id -u)" != "0" ]; then
   # If the user is not root, print an error message and exit
   echo -e "Error: \033[31mYou must be Root to run this script\033[0m. please run sudo eoa_check.sh" 
   exit 1
fi

consensus_layer="geth erigon besu nethermind"
execution_layer="prysm-beacon teku lighthouse-beacon nimbus"
readonly consensus_layer execution_layer

consensus_is_running=false
execution_is_running=false

if id "ethereum" >/dev/null 2>&1
then
	echo "User ethereum exists"
else
	echo -e "\033[31mUser ethereum does not exist, installation failed\033[0m"

for c in ${consensus_layer} 
do
	if (systemctl is-active --quiet $c)
	then
		echo "$c service is running"
		consensus_is_running=true
		continue		
	fi
done

for e in ${execution_layer} 
do
	if (systemctl is-active --quiet $e)
	then
		echo "$e service is running"
		execution_is_running=true
		continue		
	fi
done

fi

if [ "${consensus_is_running}" = false ]
then
	echo -e "\033[31mNo Consensus Client is running\033[0m"
	exit 0
fi

if [ "${execution_is_running}" = false ]
then
	echo -e "\033[31mNo Execution Client is running\033[0m"
	exit 0
fi

# Check JWT file
if test -s "/etc/ethereum/jwtsecret"; then
    echo "The file /etc/ethereum/jwtsecret exists and is not empty"
else
    echo -e "\033[31mThe file /etc/ethereum/jwtsecret does not exist or it is empty\033[0m"
fi

# Check 8551 port
if nc -z localhost 8551; then
    echo "Port 8551 is listening and accepting connections"
else
    echo -e "\033[31mPort 8551 is not open. Execution Layer and Consensus Layer cannot communicate between\033[0m"
fi

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""

lsblk

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""

if [ -e "/dev/sda" ]
then
	echo "The /dev/sda disk model is `smartctl -a /dev/sda | grep "Model Number" | awk '{ $1=$2="";$0=$0;} NF=NF'`"
fi
if [ -e "/dev/nvme0n1" ]
then
	echo "The /dev/nvme0n1 disk model is `smartctl -a /dev/nvme0n1 | grep "Model Number" | awk '{ $1=$2="";$0=$0;} NF=NF'`"
fi

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""

top -bcn 1

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""

ss -tunlp

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""

curl ifconfig.co/port/30303
curl ifconfig.co/port/9000

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

tail -n 100 /var/log/syslog