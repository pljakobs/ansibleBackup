#!/bin/bash
#uses job pool from 
# https://github.com/vincetse/shellutils/blob/master/job_pool.sh

. job_pool.sh
. /etc/backup/options

function ctrl_c(){
	echo "**exiting on ctrl-c**"
	backup_exit
}

function backup_exit(){
	job_pool_shutdown
	exit
}

echo "using rsync options: $rsync-options"

trap ctrl_c INT

# create btrfs snapshots. 
# these are not necessarily dependent on the actual backup run time
#/usr/local/sbin/btrfs-snp /share/backup hourly  24 3600
/usr/local/sbin/btrfs-snp /share hourly   6 14400
/usr/local/sbin/btrfs-snp /share daily    7 86400
/usr/local/sbin/btrfs-snp /share weekly   4 604800
/usr/local/sbin/btrfs-snp /share monthly 12 2592000

backupBase=/share/backup/

if [ ! -f /tmp/backup.fil ]
then
	touch /tmp/backup.fil

	job_pool_init $(nproc) 0 # use number of system installed cores as max job number

	#fhem2
	BackupHost=fhem2
	if [ ! -d $backupBase$BackupHost ] 
	then
		mkdir $backupBase$BackupHost
	fi
	job_pool_run rsync $rsyncOptions --rsync-path "sudo rsync" -e "ssh -i /home/pjakobs/.ssh/id_rsa" pjakobs@$hostname:/etc /share/backup/$BackupHost --exclude-from /etc/backup/lin-excludes.txt
	job_pool_run rsync $rsyncOptions --rsync-path "sudo rsync" -e "ssh -i /home/pjakobs/.ssh/id_rsa" pjakobs@$hostname:/opt/docker /share/backup/$BackupHost --exclude-from /etc/backup/lin-excludes.txt
	job_pool_run rsync $rsyncOptions --rsync-path "sudo rsync" -e "ssh -i /home/pjakobs/.ssh/id_rsa" pjakobs@$hostname:/opt/fhem /share/backup/$BackupHost --exclude-from /etc/backup/lin-excludes.txt

	#labpc
	BackupHost=labpc
	if [ ! -d $backupBase$BackupHost ] 
	then
		mkdir $backupBase$BackupHost
	fi
	job_pool_run rsync $rsyncOptions --rsync-path "sudo rsync" -e "ssh -i /home/pjakobs/.ssh/id_rsa" pjakobs@$hostname:/etc /share/backup/$BackupHost --exclude-from /etc/backup/lin-excludes.txt
	job_pool_run rsync $rsyncOptions                           -e "ssh -i /home/pjakobs/.ssh/id_rsa" pjakobs@$hostname:/home/pjakobs /share/backup/$BackupHost --exclude-from /etc/backup/lin-excludes.txt

	#fotopc
	BackupHost=fotopc
	if [ ! -d $backupBase$BackupHost ] 
	then
		echo "making directory $backupBase$BackupHost"
		mkdir $backupBase$BackupHost
	fi
	job_pool_run rsync $rsyncOptions                           -e "ssh -i /home/pjakobs/.ssh/id_rsa" fotopc:/cygdrive/c/Users/cn-0f27dt-f1167-1bi- /share/backup/$BackupHost/c --exclude-from /etc/backup/win-excludes.txt
	job_pool_run rsync $rsyncOptions                           -e "ssh -i /home/pjakobs/.ssh/id_rsa" fotopc:/cygdrive/d /share/backup/$BackupHost/d
	job_pool_run rsync $rsyncOptions                           -e "ssh -i /home/pjakobs/.ssh/id_rsa" fotopc:/cygdrive/e /share/backup/$BackupHost/e

	#nasbox
	BackupHost=nasbox
	if [ ! -d $backupBase$BackupHost ] 
	then
		mkdir $backupBase$BackupHost
	fi

	job_pool_run rsync $rsyncOptions --rsync-path "sudo rsync"                                       /etc           /share/backup/$BackupHost --exclude-from /etc/backup/lin-excludes.txt
	job_pool_run rsync $rsyncOptions /usr/local/bin                                                  /share/backup/$BackupHost --exclude-from /etc/backup/lin-excludes.txt
	job_pool_run rsync $rsyncOptions /home/pjakobs                                                   /share/backup/$BackupHost --exclude-from /etc/backup/lin-excludes.txt

	#bigbox
	BackupHost=bigbox
	if [ ! -d $backupBase$BackupHost ] 
	then
		mkdir $backupBase$BackupHost
	fi
	job_pool_run rsync $rsyncOptions --rsync-path "sudo rsync" -e "ssh -i /home/pjakobs/.ssh/id_rsa" pjakobs@192.168.29.15:/etc /share/backup/$BackupHost --exclude-from /etc/backup/lin-excludes.txt
	job_pool_run rsync $rsyncOptions --rsync-path "sudo rsync" -e "ssh -i /home/pjakobs/.ssh/id_rsa" pjakobs@192.168.29.15:/home/pjakobs /share/backup/$BackupHost --exclude-from /etc/backup/lin-excludes.txt
	job_pool_run rsync $rsyncOptions --rsync-path "sudo rsync" -e "ssh -i /home/pjakobs/.ssh/id_rsa" pjakobs@192.168.29.15:/home/media /share/backup/$BackupHost --exclude-from /etc/backup/lin-excludes.txt

	#ThinkPad
	BackupHost=ThinkPad
	if [ ! -d $backupBase$BackupHost ] 
	then
		mkdir $backupBase$BackupHost
	fi
	job_pool_run rsync $rsyncOptions --rsync-path "sudo rsync" -e "ssh -i /home/pjakobs/.ssh/id_rsa" pjakobs@pjakobs.fritz.box:/home/pjakobs /share/backup/$BackupHost --exclude-from /etc/backup/lin-excludes.txt
	rm /tmp/backup.fil

	#T460
	BackupHost=T460
	if [ ! -d $backupBase$BackupHost ] 
	then
		mkdir $backupBase$BackupHost
	fi
	job_pool_run rsync $rsyncOptions --rsync-path "sudo rsync" -e "ssh -i /home/pjakobs/.ssh/id_rsa" pjakobs@$BackupHost.fritz.box:/home/pjakobs /share/backup/$BackupHost --exclude-from /etc/backup/lin-excludes.txt

	#devbox
	BackupHost=devbox
	if [ ! -d $backupBase$BackupHost ]
	then
		mkdir $backupBase$BackupHost
	fi
	job_pool_run rsync $rsyncOptions --rsync-path "sudo rsync" -e "ssh -i /home/pjakobs/.ssh/id_rsa" pjakobs@$BackupHost.fritz.box:/home/pjakobs /share/backup/$BackupHost --exclude-from /etc/backup/lin-excludes.txt
	job_pool_run rsync $rsyncOptions --rsync-path "sudo rsync" -e "ssh -i /home/pjakobs/.ssh/id_rsa" pjakobs@$BackupHost.fritz.box:/opt/sming /share/backup/$BackupHost --exclude-from /etc/backup/lin-excludes.txt



	job_pool_shutdown
else
	echo "backup already running, skipping for now"
fi

