#!/usr/bin/env bash

consensus_layer="geth erigon besu nethermind"
execution_layer="prysm-beacon teku lighthouse-beacon nimbus"
readonly consensus_layer execution_layer

consensus_is_running=false
execution_is_running=false


for c in ${consensus_layer} 
do
	if (systemctl is-active --quiet $c)
	then
		echo "$c is running"
		consensus_is_running=true
		continue		
	fi
done

for e in ${execution_layer} 
do
	if (systemctl is-active --quiet $e)
	then
		echo "$e is running"
		execution_is_running=true
		continue		
	fi
done


if [ "${consensus_is_running}" = false ]
then
	echo "No consensus client running"
	exit 0
fi

if [ "${execution_is_running}" = false ]
then
	echo "No execution client running"
	exit 0
fi

if test -s "/etc/ethereum/jwtsecret"; then
    echo "The file /etc/ethereum/jwtsecret exists and is not empty"
else
    echo "The file /etc/ethereum/jwtsecret does not exist or is empty"
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
	echo "The /dev/sda disk is `smartctl -a /dev/sda | grep "Model Number" | awk '{ $1=$2="";$0=$0;} NF=NF'`"
fi
if [ -e "/dev/nvme0n1" ]
then
	echo "The /dev/nvme0n1 disk is `smartctl -a /dev/nvme0n1 | grep "Model Number" | awk '{ $1=$2="";$0=$0;} NF=NF'`"
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
