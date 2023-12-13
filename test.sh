#!/bin/bash 

cacheConfig=false

. job_pool.sh

function ctrl_c(){
        echo "**exiting on ctrl-c**"
        backup_exit
}

function backup_exit(){
        job_pool_shutdown
        exit
}

case $cacheConfig in
	'true')
		config=$(cat ./backup_hosts.yaml)
		parser="yq --argjson $config "
		configfile=''
		;;
	'false')
		configfile=./backup_hosts.yaml
		parser='yq'
		;;
esac

rsyncOptions=$($parser -r ".options" $configfile)
target=$($parser -r ".target" $configfile)
sshkey=$($parser -r ".sshkey" $configfile)
configPath=$($parser -r ".configpath" $configfile)
linExclude=$($parser -r ".linexclude" $configfile)
winExclude=$($parser -r ".winexclude" $configfile)
user=$($parser -r ".user" $configfile)

hosts=$($parser -r ".hosts|length" $configfile)

for i in $(seq 0 $[$hosts-1])
do
	hostName=$($parser -r ".hosts[$i].name" $configfile)
	hostOS=$($parser -r ".hosts[$i].OS" $configfile)
	hostIP=$($parser -r ".hosts[$i].address" $configfile)
	hostUser=$($parser -r ".hosts[$i].user" $configfile)
	hostSshKey=$($parser -r ".hosts[$i].sshkey" $configfile)
	hostExclude=$($parser -r ".hosts[$i].exclude" $configfile)
	if [ "$hostSshKey" != "null" ]; 
	then 
		sshkey=$hostSshKey
	fi

	echo $hostExclude
	if [ "$hostExclude" == "null" ]
	then 
		hostExclude=""	
	else
		hostExclude="--exclude-from $hostExclude"
	fi

	case $hostOS in
		'Linux')
			excludefile=$configPath$linExclude
			;;
		'Windows')
			excludefile=$configPath$winExclude
			;;
	esac

	if [ "$hostUser" == "null" ]
	then
		hostUser=$user
	fi
	echo "host $i $hostName, $hostOS, $hostIP, $excludefile"

	volumes=$($parser -r ".hosts[$i].volumes|length" $configfile)
	for j in $(seq 0 $[$volumes-1])
	do
		volName=$($parser -r ".hosts[$i].volumes[$j].name" $configfile)
		volPath=$($parser -r ".hosts[$i].volumes[$j].path" $configfile)
		volSudo=$($parser -r ".hosts[$i].volumes[$j].sudo" $configfile)

		case $volSudo in
			'true')
				rsyncSudo='--rsync-path "sudo rsync"'
				;;
			'false')
				rsyncSudo=''
				;;
			'null')
				rsyncSudo=''
				;;
		esac

		echo "job_pool_run rsync $rsyncOptions $rsyncSudo -e "ssh -i $sshkey" $hostUser@$hostIP:$volPath $target/$hostName --exclude-from $excludefile $hostExclude"
	done
done
