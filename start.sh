#!/usr/bin/env bash

## Add OP5 Masters to hosts file to verify resolution
cat /op5_hosts >> /etc/hosts

#sleep infinity
#exit 0

hostname $MY_HOSTNAME

## Verify we have all the info we need to add container to cluster
if [ -z "$OP5_ROLE" ]; then
  echo "OP5_ROLE not defined as Poller or Peer"
  exit -1
fi

if [ -z "$OP5_SITE" ]; then
  echo "OP5_SITE not defind. This shoulod be the defualt Hostgroup used for $OP5_SITE."
  exit 1
fi

if [ -z "$OP5_MASTER01" ]; then
  echo "OP5_MASTER01 not defined. Set OP5_MASTER01 and try again."
  exit 1
fi

op5_site_exists=`ssh -o StrictHostKeyChecking=no root@$OP5_MASTER01 mon query ls hostgroups -c name name=$OP5_SITE`

if [ -z "$op5_site_exists" ]; then
  echo "$OP5_SITE is not yet a valid hostgroup. Create hostgroup and try again."
  exit 1
fi

if [ -z "$MY_HOSTNAME" ]; then
  echo "Hostname for this container is unknown. Set hostanme and try again."
  exit 1
fi

if [ -z "$MY_IPADDR" ]; then
  echo "External IP Address is unknown. Set Extrenal IP and try again."
  exit 1
fi



## Start the services that are needed fro OP5
service mysqld start
sleep 10
service merlind start
service naemon start
service httpd start
service sshd start
service nrpe start
service processor start
service rrdcached start
service synergy start
service smsd start
service collector start


#sleep infinity
#exit 0

## Make sure that if this host was ever added before, it has now been removed
ssh -o StrictHostKeyChecking=no root@$OP5_MASTER01 "mon node ctrl --self --type=peer mon node remove $MY_HOSTNAME"
ssh -o StrictHostKeyChecking=no root@$OP5_MASTER01 "mon node ctrl --self --type=peer mon restart"

if (($? > 0)); then
        echo "Remove Node attempt failed. This is not becuase the node doesn't exist."
        exit 1
fi


/add_node.sh -n $OP5_MASTER01

echo "###### Checking for a Master02 at $OP5_MASTER02 ######"
## IF a second master is defined add new node to that master
if [ -n "$OP5_MASTER02" ]; then
	echo "####### Master02 found. Adding node to Master02 now. ######"

	/add_node.sh -n $OP5_MASTER02
fi

echo "####### Syncing masters and pushing Node the config #######"

## Only on one master, Syncronize the configurations and force this container to update with new config

ssh -o StrictHostKeyChecking=no root@$OP5_MASTER01 "/root/op5_sync.sh -n $MY_HOSTNAME"

echo "##### Go To Sleep ######"
sleep infinity

exit 0
