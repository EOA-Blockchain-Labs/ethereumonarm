#!/bin/bash
#set -euxo pipefail
set -eo pipefail

RegVs='^rock.*(debian|ubuntu).* ^(Armbian).* ^(LibreELEC).* ^(Manjaro).* ^(slarm64).* ^(DietPi).*'


Version="Version 1.4"
function error { echo -e "[Error] $*"; echo "-= End Of Script $Version =-"; exit 1; }
function exitOK { echo -e '  -= All OK =-'; echo "-= End Of Script $Version =-"; exit 0; }
function warn  { echo -e "[Warning] $*"; }
ConfirmF() {
  while true; do
    echo "Type Y/y and then Enter to continue or Ctrl-C to abort."
    read CONFIRM
    if [ $CONFIRM = Y -o $CONFIRM = y ]; then
        break
    fi
  done
}
ConfirmEnterF() { echo "Type Enter key  to continue."; read CONFIRM; }

HelpF() {
 echo "Make partitions from OS image files for multi-boot purpose"
 echo
 echo "  To create a new GPT and flash u-boot Usage:"
 echo "make_multibot_dev.sh  --device /dev/(sd[a-z]|mmcblk[0-2]|nvme0n1) --uboot-file FILE"
 echo
 echo "  To flash OS image Usage:"
 echo "make_multibot_dev.sh  --device /dev/(sd[a-z]|mmcblk[0-2]|nvme0n1) --image-file FILE"
 echo 
 echo "Options:"
 echo "  -d, --device"
 echo "         used when boot-dev=root-dev or when uboot flashed"
 echo "  -b, --boot-dev"
 echo "         device for boot partition, ignore if used --device option"
 echo "  -n, --boot-part-num"
 echo "         boot partition number. Using an existing partition. New not create. device or boot-dev option need"
 echo "  -r, --root-dev"
 echo "         device for root partition, ignore if used --device option"
 echo "  -m, --root-part-num"
 echo "         root partition number. Using an existing partition. New not create. device or root-dev option need"
 echo "  -s, --boot-size"
 echo "         size of boot part, if empty - default set in 256MiB"
 echo "  -z, --root-size"
 echo "         size of root part, if empty - default set in 4096MiB"
 echo "  -i, --image-file"
 echo "         file with OS image. device or boot-dev and root-dev option need ... or no, if test."
 echo "  -p, --pause-before-umount"
 echo "         pause before umount partitions. You  can edit /tmp/1/extlinux/extlinux.conf and /tmp/2/etc/fstab." 
 echo "         Close all files and go from /tmp/* dir before push Enter! "
 echo "  -t, --test-image"
 echo "         test image file. Show partitions size, extlinux.conf, /etc/fstab ...etc" 
 echo "         image-file option need"
 echo "      --lock-space"
 echo "         with this option a small partition is created after the rootfs partition." 
 echo "         Prevents the growth of the OS on the entire device."
 echo "      --extlinux-conf-file"
 echo "         extlinux.conf file to replace default"
 echo "  -u, --uboot-file"
 echo "         here put OS image filename or filename of first 16Mib from OS image. This files contain u-boot."
 echo "         Or you can specify a block device, then the uboot will be copied from it"
 echo "         device option need and one of: create-new-gpt, backup-uboot, write-uboot"
 echo "  -c, --create-new-gpt"
 echo "         create new GPT and write uboot. if uboot-file not set, uboot area are zeroing'"  
 echo "         device option need"
 echo "      --backup-uboot"
 echo "         backup first 16Mib of device to file. if uboot-file not set, then default 'first16M_date_time.img'"  
 echo "         device option need"
 echo "      --write-uboot"
 echo "         write uboot from backup or image with uboot"
 echo "         device and uboot-file options need"
 echo "      --zeroing-uboot"
 echo "         device option need"
 echo "  -v, --version"
 echo "         show version"
 echo "  -h, --help"
 echo "        this help"
 echo "  -g, --debug-mode"
 echo "         debug mode"
 echo ""
 exit 0
 }

[[ $# -eq 0 ]] && HelpF


Device=; BootDev=; RootDev=;BootSize=;RootSize=;NameFileOS=; NameUbootFile=; ExtlinuxConfFile=; 
LockSpace=0; ZeroingUboot=0;BackupUboot=0; WriteUboot=0; TestImage=0; BootPartNum=0; RootPartNum=0; PauseBeforeUmount=0
CreateNewGpt=0
while [[ $# -gt 0 ]]; do
    arg="$1"

    case $arg in
        -g|--debug--mode)
            set -euxo pipefail
            ;;
        -d|--device)  # use if boot-dev=root-dev or for uboot case
            Device=$2
            shift
            ;;
        -b|--boot-dev) # ignore if used --device
            BootDev=$2
            shift
            ;;
        -n|--boot-part-num)
            BootPartNum=$2
            shift
            ;;
        -r|--root-dev) # ignore if used --device
            RootDev=$2
            shift
            ;;
        -m|--root-part-num)
            RootPartNum=$2
            shift
            ;;
        -s|--boot-size) # default 256MiB
            BootSize=$2
            shift
            ;;
        -z|--root-size) # default 4096MiB
            RootSize=$2
            shift
            ;;
        -i|--image-file)  # file with OS image
            NameFileOS=$2
            shift
            ;;
        -p|--pause-before-umount) #  create small partition at the end of roootfs
            PauseBeforeUmount=1
            ;;           
        -t|--test-image) #  create small partition at the end of roootfs
            TestImage=1
            ;;
           --lock-space) #  create small partition at the end of roootfs
            LockSpace=1
            ;;
           --extlinux-conf-file)
            ExtlinuxConfFile=$2
            shift
            ;;             
        -u|--uboot-file)      # filename of OS image or filename of first 16Mib from OS image. This files contain u-boot
            NameUbootFile=$2  # device parted to new GPT and u-boot flashed
            shift             # if used this opt only --device opt need, other ignored
            ;;
        -c|--create-new-gpt) 
            CreateNewGpt=1
            ;;  
            --backup-uboot) 
            BackupUboot=1
            ;;  
           --write-uboot) 
            WriteUboot=1
            ;;    
           --zeroing-uboot) 
            ZeroingUboot=1
            ;;    
        -h|--help)  # file with OS image
            HelpF
            ;;   
        -v|--version) # show version
            echo $Version
            exit 0
            ;;     
        *)
            error "Unrecognized option $1"
            ;;
    esac
    shift
done

[ $(id -u) -ne 0 ] && error "This script requires root."
[ -n $ExtlinuxConfFile ] && [ -f $ExtlinuxConfFile ] || error "$ExtlinuxConfFile not found!"  

PhiDevices="/dev/mmcblk$((`uname -r | sed 's/^\([4-5]\).*/\1/'`-3)) /dev/mmcblk$((`uname -r | sed 's/^\([4-5]\).*/\1/'`-4)) /dev/nvme0n1"
NameOfDevices="emmc microsd nvme"
DeviceName=$(echo $Device| sed 's%/dev/%%')
DevicePhi=
DevicePhiF() {  
  DevicePhi=$1
  j=1
  for i in $NameOfDevices; do
    [ $i = $1 ] &&  DevicePhi=$(echo $PhiDevices | awk -v z=$j '{ print $z }') && break
    j=$(($j+1))
  done
  if [[ $2 -gt 0 ]]; then
    if echo $1 | grep -Eq "^/dev/sd"; then
      DevicePhi="${DevicePhi}${2}"
    else
      DevicePhi="${DevicePhi}p${2}"
    fi  
  fi
  [ -b  "$DevicePhi" ] || error "$DevicePhi isn't block device!"
}

if [ $TestImage -eq 0 ]; then 
  if [[ -n ${Device} ]]; then BootDev=$Device; RootDev=$Device; fi
  [ -z $Device ]  || DevicePhiF $Device 0; Device=$DevicePhi
  [ -z $BootDev ] || DevicePhiF $BootDev $BootPartNum; BootDev=$DevicePhi
  [ -z $RootDev ] || DevicePhiF $RootDev $RootPartNum ; RootDev=$DevicePhi
  
  [ -z ${BootSize} ] && BootSize=256; [ -z ${RootSize} ] && RootSize=4096
  BootSize=$((${BootSize}/16*16)); RootSize=$((${RootSize}/16*16))        # alignment multiple 16
  
fi
Count=$(($ZeroingUboot+$BackupUboot+$WriteUboot+$CreateNewGpt))
if [ $Count -gt 0 ]; then
 
  echo $Device | grep -Eq '^/dev/sd[a-z][0-9]|[0-9]p[0-9]' && error "$Device is a partition, not device!"
  if [ $ZeroingUboot -eq 1 ]; then
    echo "Do zeroing uboot on $Device ?"
    ConfirmF
    dd if=/dev/zero of=$Device seek=64 count=32704; sync
    exitOK
  fi
  if [ $BackupUboot -eq 1 ]; then
    [ $(hexdump -v -e '/1 "%02X"' -s 64b -n 4 $Device) = 3B8CDCFC ] || error "Wrong uboot signature on $Device"
    [ -z $NameUbootFile ] && NameUbootFile=first16M_${DeviceName}_$(date +%y%m%d-%H%M).img
    echo "Backup uboot to $NameUbootFile"
    dd if=$Device  of=$NameUbootFile bs=1M count=16; sync
    exitOK
  fi
  [ -z $NameUbootFile ] && [ $WriteUboot -eq 1 ] && error "--uboot-name option required"
  if [[ -n "$NameUbootFile" ]]; then
    [ -f "$NameUbootFile" -o -b "$NameUbootFile" ] || error "File ${NameUbootFile} not found!"
    [ $(hexdump -v -e '/1 "%02X"' -s 64b -n 4 $NameUbootFile) = 3B8CDCFC ] || error "File ${NameUbootFile} not contain uboot!"
    if [ $WriteUboot -eq 1 ]; then
      echo "Uboot on $Device rewrite from file $NameUbootFile !"
      ConfirmF
      dd of=$Device  if=$NameUbootFile seek=64 skip=64 count=32704; sync
      exitOK
    fi
  fi  
  if grep -q "${Device}" /proc/mounts; then
    warn "Partitions on device ${Device} is mounted! umount it?"
    ConfirmF
    for i in $(grep  "${Device}" /proc/mounts | awk '{ print $1 }'); do
      umount $i || error "Partitions $i isn't umounted!"
    done
  fi 
  [ -z $NameUbootFile ] && warn "--uboot-file is not set, uboot area are zeroing! "
  warn "---===  All data on device $Device will be deleted !!!  ===---"
  ConfirmF
  dd if=/dev/zero of=$Device bs=1M count=16;sync   
  parted -m $Device mktable gpt;sync  
  parted -ma none $Device mkpart idbloader ext2 64s 8063s
  parted -m $Device mkpart uboot ext2 16384s 24575s;sync 
  parted -m $Device mkpart trust ext2 24576s 32767s;sync
  [[ -n $NameUbootFile ]] && dd if=$NameUbootFile of=$Device seek=64 skip=64 count=32704; sync
  exitOK
fi

NameOS=
PartedStringFromImg=$(parted -m $NameFileOS unit s print)
echo "$NameFileOS" | grep -q "/" && error "Run this script only from directory with image file!"
[ -f "$NameFileOS" ] || error "File ${NameFileOS} not found!"
#NumsOsParts=$(parted -m $NameFileOS print |awk -F: '{ print $1 }'|tail -n1) 
NumsOsParts=$(echo $PartedStringFromImg | awk -F "; " '{ print $NF }' | awk -F ":" '{ print $1 }')
[ $NumsOsParts -le 5 ] || error "$NameFileOS this is wrong image file!"

[ $TestImage -eq 1 ] && DevLoop=/dev/mapper/$(kpartx -av $NameFileOS | sed  's%.*\(loop[0-9]*p\).*%\1%' | tail -n1) && mkdir -p /tmp/{1..2}
SizeFromImage=0
SizeFromImageF() {
  SizeFromImage=$(echo $PartedStringFromImg |  awk -F "; ${1}:" '{ print $2 }' | awk -F ":" '{ print $3 }'|sed 's/\(^[0-9]*\).*/\1/')
  }
MountTestF() {
  if [ $TestImage -eq 1 ]; then
    mount ${DevLoop}${1} /tmp/2
    if [ $2 -gt 0 ]; then
      mount ${DevLoop}${2} /tmp/1
    else
      mount -o bind /tmp/2/boot /tmp/1
    fi
  fi
}
case $NumsOsParts in
         1)
            BootSizeFromImageS=0
            SizeFromImageF 1; RootSizeFromImageS=$SizeFromImage
            MountTestF 1 0 
            ;;
         2)
            SizeFromImageF 1; BootSizeFromImageS=$SizeFromImage
            SizeFromImageF 2; RootSizeFromImageS=$SizeFromImage
            MountTestF 2 1
            ;;
         5)
            SizeFromImageF 4; BootSizeFromImageS=$SizeFromImage
            SizeFromImageF 5; RootSizeFromImageS=$SizeFromImage
            MountTestF 5 4
            ;;
         *)
            error "Unrecognized numbers of partition in img file!"
            ;;
esac
PrintPartSizeF() {
  if [ $2 -gt 0  ]; then
    local S; S=$3
    echo "Size of image $1 partition is $(($2/2048)) MiB"
    if [ $TestImage -eq 0 ];then
    [ $4 -gt 0 ] && S=$(($(lsblk -nbo SIZE $5)/512/2048))
    echo "it flash into partition with size $S MiB"
    fi
  fi  
  }
echo
PrintPartSizeF "BOOT" $BootSizeFromImageS $BootSize $BootPartNum $BootDev
PrintPartSizeF "ROOT" $RootSizeFromImageS $RootSize $RootPartNum $RootDev
echo
PrintInfoF() {
  echo "---------/boot/*Env.txt :"
  [ -f /tmp/1/*Env.txt ] && cat /tmp/1/*Env.txt
  echo "---------found Rock 5B fdt files :"
#  ls -R /tmp/1/* |grep -E '.*rock-*5b.dtb$'
  find /tmp/1 -regex '.*rock-*5b.dtb$' | sed 's%^/tmp/1\(.*\)%\1%g'
  echo "--------- extlinux.conf :"
  [ -f /tmp/1/extlinux/extlinux.conf ] && cat /tmp/1/extlinux/extlinux.conf
  echo "---------- /etc/fstab :"
  [ -f /tmp/2/etc/fstab ] && cat /tmp/2/etc/fstab
  echo
 
}

if [ $TestImage -eq 1 ]; then
  PrintInfoF
  [[ $PauseBeforeUmount -eq 1 ]] && ConfirmEnterF
  set +e
  umount /tmp/{1..2}; rmdir /tmp/{1..2}
  kpartx -d $NameFileOS  >/dev/null 2>&1
  exit 0
fi
#[ $RootSizeFromImageS -gt $(($RootSize*2048)) ] && error "Increase --root-size !" # need patch  PrintPartSizeF
ConfirmF

for RegV in ${RegVs}; do 
     NameOS=$(echo ${NameFileOS} | sed -E "s/${RegV}/\1/1")
     [ "$NameOS" = "$NameFileOS" ] || break
done
UnknownOs=
#[ "$NameOS" = "$NameFileOS" ] &&  error "This filename from unknown OS !"
if [ "$NameOS" = "$NameFileOS" ]; then
  NameOS=$(echo "$NameFileOS" | sed 's%^\([0-9a-zA-Z]*\).*%\1%')
  UnknownOs=1
fi

Partitions=
function errorPM {
  set +e
  echo -e "[Error] $*"
  [[ -n  $Partitions ]] && for i in $Partitions; do
    parted -m $(echo $i | sed -e 's%\(.*[a-z]\)[0-9]*%\1%' -e 's%\(^/dev/[^s][^d].*[0-9]\)p%\1%') rm $(echo $i | sed 's%.*[a-z]\([0-9]*\)%\1%')
  done
  echo '-= End Of Script =-'
  exit 1
  }


MakePartition() {
  local Dev OSname Size TypeFS
  Dev=$1; Size=$2; OSname=$3; TypeFS=$4; CurrentDevice=; 
  if  echo $Dev | grep -Eq '^/dev/sd[a-z][0-9]|[0-9]p[0-9]'; then
      CurrentPart=$Dev
      CurrentDevice=$(echo $Dev | sed -e 's%\(.*[a-z]\)[0-9]*%\1%' -e 's%\(.*[0-9]*\)p%\1%')
    if grep -q "${CurrentPart} " /proc/mounts; then
      warn "Partition ${CurrentPart} is mounted! umount it?"
      ConfirmF
      umount ${CurrentPart} || error "Partition ${CurrentPart} isn't umounted!"
    fi 
    warn "---===  All data on $CurrentPart will be deleted !!!  ===---"
    ConfirmF
    parted -m $(echo $Dev | sed -e 's%\(.*[a-z]\)[0-9]*%\1%' -e 's%\(^/dev/[^s][^d].*[0-9]\)p%\1%') name $(echo $CurrentPart | sed 's%.*[a-z]\([0-9]*\)%\1%') "$OSname" || errorPM "Can not rename partition on device $Dev !"
  else 
    LastSect=$(fdisk -l $Dev|awk '{ print $3 }'|tail -n1)  
    parted -m $Dev mkpart "$OSname" $TypeFS $(($LastSect+1))s $(($LastSect+2048*$Size))s || errorPM "Can not create partition on device $Dev !"
    sync
    CurrentPart=$(fdisk -l $Dev |awk '{ print $1 }'|tail -n1)
    Partitions="${Partitions} ${CurrentPart}"
  fi
  sync
  mkfs.${TypeFS} -FL "$OSname" $CurrentPart > /dev/null 2>&1 || error "Not make filesystem on $CurrentPart !"
  sync
  CurrentUUID=$(blkid $CurrentPart | sed -e s%'.* \(UUID="[a-zA-Z0-9.-]*\)".*%\1%' -e 's%"%%g')
  CurrentPARTUUID=$(blkid $CurrentPart | sed -e s%'.* \(PARTUUID="[a-zA-Z0-9.-]*\)".*%\1%' -e 's%"%%g')
}




echo "Work with partitions  ..."
MakePartition $BootDev $BootSize boot_${NameOS} ext2
#MakePartition $BootDev $BootSize boot_TEMPORARY ext2
BootUUID=$CurrentUUID; BootPARTUUID=$CurrentPARTUUID; BootPart=$CurrentPart
[[ -n $CurrentDevice ]] && BootDev=$CurrentDevice
parted -m $BootDev set $(echo $BootPart | sed 's%.*[a-z]\([0-9]*\)%\1%') boot on  

MakePartition $RootDev $RootSize root_${NameOS} ext4
#MakePartition $RootDev $RootSize root_TEMPORARY ext4
RootUUID=$CurrentUUID; RootPARTUUID=$CurrentPARTUUID; RootPart=$CurrentPart
if [[ -n $CurrentDevice ]]; then 
  RootDev=$CurrentDevice
else
  sync
  if [ $LockSpace -eq 1 ] ; then
      LastSect=$(fdisk -l $RootDev|awk '{ print $3 }'|tail -n1)  
      parted -m $RootDev mkpart border ext4 $(($LastSect+1))s $(($LastSect+2048*16))s || errorPM "Can not create border partition on device $RootDev !"
      CurrentPart=$(fdisk -l $RootDev |awk '{ print $1 }'|tail -n1)
      Partitions="${Partitions} ${CurrentPart}"
  fi
fi  

echo ++++++++++++++++++++++++++++++++++++++++++++++++++++
echo "Attention! If the program does not end with the phrase 'End Of Script' then manually do 'umount /tmp/{1..4}', 'rmdir /tmp/{1..4}'"
[[ -n $Partitions ]] && echo "and remove partions: $Partitions"
echo ++++++++++++++++++++++++++++++++++++++++++++++++++++

NUM=4; [ $NumsOsParts -eq 1 ] && NUM=3
for i in `seq $NUM`; do mkdir /tmp/$i; done 
mount $BootPart /tmp/1; mount $RootPart /tmp/2

function errorAM {
  set +e
  echo -e "[Error] $*"
  for i in `seq $NUM`; do umount /tmp/$i; sync; done
  for i in `seq $NUM`; do rmdir /tmp/$i; sync; done
  kpartx -d $NameFileOS
  [[ -n  $Partitions ]] && for i in $Partitions; do
    parted -m $(echo $i | sed -e 's%\(.*[a-z]\)[0-9]*%\1%' -e 's%\(^/dev/[^s][^d].*[0-9]\)p%\1%') rm $(echo $i | sed 's%.*[a-z]\([0-9]*\)%\1%') 
  done
  echo '-= End Of Script =-'
  exit 1
  }

DevLoop=/dev/mapper/$(kpartx -arv $NameFileOS | sed  's%.*\(loop[0-9]*p\).*%\1%' | tail -n1) || errorAM "kpartx not create devices!" 
echo "Files are copied, wait ..."
case $NumsOsParts in
         1)
            mount ${DevLoop}1 /tmp/3 >/dev/null 2>&1 || errorAM "mount ${DevLoop}1"
            cp -a /tmp/3/boot/* /tmp/1 || errorAM "Copy to /tmp/1"
            cp -a /tmp/3/* /tmp/2 || errorAM "Copy to /tmp/2"
            rm -r /tmp/2/boot/*
            ;;
         2)
            mount ${DevLoop}1 /tmp/3 >/dev/null 2>&1 || errorAM "mount ${DevLoop}1"
            mount ${DevLoop}2 /tmp/4 >/dev/null 2>&1 || errorAM "mount ${DevLoop}2"
            cp -a /tmp/3/* /tmp/1 || errorAM "Copy to /tmp/1"
            cp -a /tmp/4/* /tmp/2 || errorAM "Copy to /tmp/2"
            ;;
         5)
            mount ${DevLoop}4 /tmp/3 > /dev/null 2>&1 || errorAM "mount ${DevLoop}4"
            mount ${DevLoop}5 /tmp/4 > /dev/null 2>&1 || errorAM "mount ${DevLoop}4"
            cp -a /tmp/3/* /tmp/1 || errorAM "Copy to /tmp/1"
            cp -a /tmp/4/* /tmp/2 || errorAM "Copy to /tmp/2"
            ;;
         *)
            errorAM "Unrecognized numbers of partition in img file!"
            ;;
esac
sync

ExtCfg=/tmp/1/extlinux/extlinux.conf
EtcFstab=/tmp/2/etc/fstab

exitOKAM() {
  set +e
  PrintInfoF
  [[ $PauseBeforeUmount -eq 1 ]] && ConfirmEnterF
  [ -f /tmp/1/boot.scr ] && mv /tmp/1/boot.scr /tmp/1/boot.scr.bak
  [ -f $ExtCfg ] && cp $ExtCfg ${ExtCfg}.bak
  [ -f $EtcFstab ] && cp $EtcFstab ${EtcFstab}.bak
  sync
  for i in `seq $NUM`; do umount /tmp/$i; sync; done
  for i in `seq $NUM`; do rmdir /tmp/$i; sync; done
  kpartx -d $NameFileOS 
  exitOK
}

FstabAddF() {
  if [ -f FilesToNewOS/etc/fstab.add ] && [ -f $EtcFstab ];  then
    cat FilesToNewOS/etc/fstab.add >> $EtcFstab
    for i in $(cat FilesToNewOS/etc/fstab.add | awk '{ print $2 }'); do mkdir -p /tmp/2/$i ; done
  fi
}

[[ -d /tmp/1/extlinux ]] || mkdir /tmp/1/extlinux
[[ -n $ExtlinuxConfFile ]] && cp -f $ExtlinuxConfFile $ExtCfg

[ -d FilesToNewOS/etc/ssh ] && [ -d /tmp/2/etc ] && mkdir -p /tmp/2/etc/ssh && cp -a FilesToNewOS/etc/ssh/* /tmp/2/etc/ssh
[ -d FilesToNewOS/usr/local/sbin ] && [ -d /tmp/2/usr ] && mkdir -p /tmp/2/usr/local/sbin && cp -a FilesToNewOS/usr/local/sbin/* /tmp/2/usr/local/sbin


# ------------------- radxa ubuntu and debian  rock rock
if [ $NameOS = debian -o $NameOS = ubuntu ]; then  # OS from radxa
  sed -i "s%root=[-=/_0-9a-zA-Z]*%root=${RootPARTUUID}%g" $ExtCfg
  if ! grep -q " fdt " $ExtCfg;then  sed -i "s%\(/dtbs/.*\)%\1\n    fdt \1/rockchip/rock-5b-linux.dtb%g" $ExtCfg; fi
  ExtSh=/tmp/2/usr/local/sbin/return_my_root_to_extlinux.sh
  echo '#!/bin/bash' > $ExtSh
#  echo sed -i "s%root=PARTUUID=B921B045-1DF0-41C3-AF44-4C6F280D3FAE%root=${RootPARTUUID}%g" /boot/extlinux/extlinux.conf >> $ExtSh
  echo sed -i "s%root=[-=/_0-9a-zA-Z]*%root=${RootPARTUUID}%g" /boot/extlinux/extlinux.conf >> $ExtSh
  echo 'if ! grep -q " fdt " /boot/extlinux/extlinux.conf;then  sed -i "s%\(/dtbs/.*\)%\1\n    fdt \1/rockchip/rock-5b-linux.dtb%g" /boot/extlinux/extlinux.conf; fi' >>$ExtSh 
  chmod +x  $ExtSh
  sed -i 's/# UNCONFIGURED FSTAB FOR BASE SYSTEM//g' $EtcFstab
  echo "$BootPARTUUID  /boot   ext2    defaults        0       2"  >> $EtcFstab 
  [ -f /tmp/2/etc/FIRST_BOOT ] && rm /tmp/2/etc/FIRST_BOOT
  FstabAddF
  exitOKAM
fi



if [ -f $ExtCfg ]; then
    grep -q "boot=" $ExtCfg && sed -i "s%boot=[-=/_0-9a-zA-Z]*%boot=${BootUUID}%g" $ExtCfg
    grep -q "root=" $ExtCfg && sed -i "s%root=[-=/_0-9a-zA-Z]*%root=${RootUUID}%g" $ExtCfg
    grep -q "disk=" $ExtCfg && sed -i "s%disk=[-=/_0-9a-zA-Z]*%disk=${RootUUID}%g" $ExtCfg
    
fi
#------------------------ LibreELEC  root libreelec
if [ $NameOS = LibreELEC ]; then
  if ! [ -f $ExtCfg ]; then
    echo "LABEL LibreELEC" > $ExtCfg
    echo "  LINUX /KERNEL" >> $ExtCfg
    echo "  FDT /dtb/rockchip/rk3399-rock-pi-4.dtb" >> $ExtCfg
#   echo "  APPEND boot=$BootUUID disk=$RootUUID console=tty0 no_console_suspend consoleblank=0 quiet coherent_pool=2M cec.debounce_ms=5000" >> $ExtCfg
    echo "  APPEND boot=$BootUUID disk=$RootUUID quiet console=uart8250,mmio32,0xff1a0000 console=tty0 systemd.debug_shell=ttyS2 " >> $ExtCfg
  fi
  [ -f  /tmp/2/.please_resize_me ] && rm /tmp/2/.please_resize_me
  [ -d FilesToNewOS/etc/ssh ] && mkdir -p /tmp/2/.cache/ssh && cp -a FilesToNewOS/etc/ssh/ssh_host* /tmp/2/.cache/ssh
  exitOKAM
fi  

[ -f $EtcFstab ] || errorAM  " No /etc/fstab  file!"
sed -Ei "s%^[^#][-=/_0-9a-zA-Z]*.*[[:blank:]]/[[:blank:]]+[0-9a-zA-Z]+([[:blank:]].*$)%${RootUUID}  / ext4 \1%g" $EtcFstab
sed -Ei "s%^[^#][-=/_0-9a-zA-Z]*.*[[:blank:]]/boot[[:blank:]]+[0-9a-zA-Z]+([[:blank:]].*$)%${BootUUID}  /boot ext2 \1%g" $EtcFstab
grep -Eq '^[^#].*[[:blank:]]/[[:blank:]]' $EtcFstab || echo "${RootUUID} / ext4 defaults 0 0" >> $EtcFstab
grep -Eq '^[^#].*[[:blank:]]/boot[[:blank:]]' $EtcFstab || echo "${BootUUID} /boot ext2 defaults 0 0" >> $EtcFstab
FstabAddF

#----------------------- Armbian root 1234
if [ $NameOS =  Armbian ]; then

  if ! [ -f $ExtCfg ]; then
    i=$(find /tmp/1 -regex '.*rock-*pi-*4.*.dtb$' | awk -F"/" '{ print $NF }'|tail -n1) || errorAM  "FDT file NOT found!"
    echo "LABEL Armbian" > $ExtCfg
    echo "  LINUX /Image" >> $ExtCfg
    echo "  INITRD /uInitrd" >> $ExtCfg
    echo "  FDT /dtb/rockchip/$i" >> $ExtCfg
    echo "  APPEND root=$RootUUID rootflags=data=writeback rw console=uart8250,mmio32,0xff1a0000 console=tty0 no_console_suspend consoleblank=0 fsck.fix=yes fsck.repair=yes net.ifnames=0" >> $ExtCfg    
  fi
  exitOKAM
fi
#----------------------- DietPi root 1234
if [ $NameOS =  DietPi ]; then

  if ! [ -f $ExtCfg ]; then
    i=$(find /tmp/1 -regex '.*rock-*pi-*4.*.dtb$' | awk -F"/" '{ print $NF }'|tail -n1) || errorAM  "FDT file NOT found!"
    echo "LABEL DietPi" > $ExtCfg
    echo "  LINUX /Image" >> $ExtCfg
    echo "  INITRD /uInitrd" >> $ExtCfg
    echo "  FDT /dtb/rockchip/$i" >> $ExtCfg
    echo "  APPEND root=$RootUUID rootflags=data=writeback rw console=uart8250,mmio32,0xff1a0000 console=tty0 no_console_suspend consoleblank=0 fsck.fix=yes fsck.repair=yes net.ifnames=0" >> $ExtCfg    
  fi
  exitOKAM
fi
  #---------------------------------- Manjaro root root
if [ $NameOS = Manjaro ]; then
  
  if ! [ -f $ExtCfg ]; then
    echo "LABEL Manjaro" > $ExtCfg
    echo "  LINUX /Image" >> $ExtCfg
    echo "  INITRD /initramfs-linux.img" >> $ExtCfg
    echo "  FDT /dtbs/rockchip/rk3399-rock-pi-4.dtb" >> $ExtCfg
    echo "  APPEND root=${RootUUID} rw rootwait console=ttyS2,1500000  bootsplash.bootfile=bootsplash-themes/manjaro/bootsplash" >> $ExtCfg
  fi
  exitOKAM
fi
#----------------------------- slarm64 root password
if [ $NameOS = slarm64 ]; then
  echo "#!/bin/sh" > /tmp/2/tmp/firstboot
  echo "usermod -p '\$1\$s1anIFwo\$O2EqFQQRljpZrD1y4noyX.' root" >> /tmp/2/tmp/firstboot 
  if ! [ -f $ExtCfg ]; then
    i=$(find /tmp/1 -regex '.*rock-*pi-*4.*.dtb$' | awk -F"/" '{ print $NF }'|tail -n1) || errorAM  "FDT file NOT found!"
    echo "LABEL slarm64" > $ExtCfg
    echo "  LINUX /Image" >> $ExtCfg
    echo "  FDT /dtb/${i}" >> $ExtCfg
#    echo "  APPEND root=${RootPARTUUID} rw rootwait console=ttyS2,1500000  " >> $ExtCfg
    echo "  APPEND root=${RootPARTUUID} ro rootwait console=ttyS2,1500000 consoleblank=0 earlyprintk console=tty1 loglevel=4" >> $ExtCfg    
  fi
  exitOKAM
fi
if ! [ -f $ExtCfg ]; then
  errorAM "Unknown OS without extlinux.conf file"
else
  exitOKAM
fi
errorAM "Unknown error"



