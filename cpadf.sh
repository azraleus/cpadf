#!/bin/bash

umount_all_adfs () {
  for fs in $(mount | grep affs | awk '{print $3}'); do 
    echo $fs
    sudo umount $fs
  done
}

copy_adf () {
  set -e
  ls $1 >/dev/null
  umount_all_adfs
  sudo mkdir -p /mnt/amiga$2
  echo "Mounting ADF.."
  if [[ ! -d /tmp/adf ]]
  then
    mkdir -p /tmp/adf
  fi
  sudo cp $script_dir/blank.adf /tmp/adf/blank$2.adf
  sudo mount -t affs /tmp/adf/blank$2.adf /mnt/amiga$2 -o loop
  echo "Copying file to ADF.."
  sudo cp $1 /mnt/amiga$2
  sudo umount /mnt/amiga$2
  echo "Syncing ADF to pendrive"
  cp /tmp/adf/blank$2.adf /media/$USER/$share_id/
  sudo rm /tmp/adf/blank$2.adf
}

main () {
  echo "Cleaning pendrive..."
  if [[ -f /media/$USER/$share_id/blank* ]]
  then
    sudo rm /media/$USER/$share_id/blank*
  fi
  sudo mkdir -p /tmp/split
  umount_all_adfs
  file_size=$(ls -s $1 | awk '{print $1}')
  if [ $file_size -lt 728 ]
  then
    copy_adf $(pwd)/$1 1
  else
    echo "Creating multiple ADFs"
    no_ext=$(echo $1 | sed 's/\.[^.]*$//')
    sudo split -b 745472 -d $1 /tmp/split/$no_ext.
    num="1"
    for splitfile in $(find /tmp/split/ -iname '*.0*'); do
     echo $splitfile $num
     copy_adf $splitfile $num
     num=$((num+1))
    done
    sudo rm /tmp/split/*
  fi
  sudo umount /media/$USER/$share_id/
}

script_dir=$(dirname "$0")
if [ $# -ne 1 ]
  then
    echo "No or too many arguments.."
else
  share=$(mount | grep vfat | grep -v efi | awk {'print $3'})
  if [ -z "$share" ]; 
  then 
    echo "Can't detect vfat FS. Exiting.."; 
  else 
    share_id=$(echo $share | awk -F"/" '{print $4}')
    read -r -p "Is it your USB drive [Y/n]? "$share" : " input
    case $input in
          [yY][eE][sS]|[yY])
                main $1 $share_id $script_dir
                ;;
          [nN][oO]|[nN])
                echo "Exiting.."
                ;;
          *)
                echo "Invalid input..."
                exit 1
                ;;
    esac
  fi
fi
