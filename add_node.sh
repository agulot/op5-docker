#!/bin/bash


PROGNAME=${0##*/}
ARGS=$(getopt -o n: --name $PROGNAME  -- "$@")

eval set -- "$ARGS"

while true ; do
    case "$1" in
        -n|--name) OP5_MASTER=$2; shift; shift ;;
        -h|--help) usage ;;
        --) shift ; break ;;
        *)
    esac
done

if [ -z "$OP5_MASTER" ]; then
	echo "Failed to get Master Name. Exiting"
	exit 1
fi


ssh -o StrictHostKeyChecking=no root@$OP5_MASTER "ssh-keygen -R [$MY_HOSTNAME]:2222; sed -i '/$MY_HOSTNAME/d' /opt/monitor/.ssh/known_hosts"
ssh -o StrictHostKeyChecking=no root@$OP5_MASTER "ssh-keygen -R $MY_HOSTNAME"

if (($? > 0)); then
        echo "Remove old key attempt failed. This is not becuase the key doesn't exist."
        exit 1
fi
ssh -o StrictHostKeyChecking=no root@$OP5_MASTER "sed -i '/$MY_HOSTNAME/d' /etc/hosts"

if (($? > 0)); then
        echo "Remove old hosts file entry attempt failed. This is not becuase the entry doesn't exist."
        exit 1
fi

echo "####### Begin Adding Node to $OP5_MASTER #######"

## OP5 Master configurations might be better of in a sperate script and called from here
## Configure 1st OP5 master with this containers information
ssh -o StrictHostKeyChecking=no root@$OP5_MASTER << EOF
echo "$MY_IPADDR $MY_HOSTNAME" >> /etc/hosts
scp -o StrictHostKeyChecking=no /root/test.txt root@$MY_HOSTNAME:/test.txt
su monitor -c "scp -o StrictHostKeyChecking=no /opt/monitor/test.txt monitor@$MY_HOSTNAME:/test2.txt"
mon node add $MY_HOSTNAME type=$OP5_ROLE hostgroup=$OP5_SITE takeover=no
mon sshkey push $MY_HOSTNAME
asmonitor mon sshkey push $MY_HOSTNAME
mon node ctrl $MY_HOSTNAME mon node add $OP5_MASTER type=master connect=no
EOF

scp  -o StrictHostKeyChecking=no /op5_sync.sh root@$OP5_MASTER:/root/op5_sync.sh
ssh -o StrictHostKeyChecking=no root@$OP5_MASTER 'chmod +x /root/op5_sync.sh'

exit 0
