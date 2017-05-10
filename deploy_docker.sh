#!/bin/bash

PROGNAME=${0##*/}
SCRIPT=`basename ${BASH_SOURCE[0]}`
NORM="\e[0m"
BOLD="\e[1m"
REV="\e[7m"

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function usage {
	echo -e \\t "Help documentation for ${BOLD}${SCRIPT}.${NORM}"
	echo -e \\t "${REV}Basic usage:${NORM} ${BOLD}$SCRIPT {options} ${NORM}"
	echo -e \\n \\t "****************************************************************************"
	echo -e \\t "This script is designed to build the op5.env file, copy all files needed"
	echo -e \\t "to build docker container to the host location, build the container,"
	echo -e \\t "execute the docker run command, join the new OP5 docker container to the"
	echo -e \\t "op5 cluster, and verify the new OP5 node status."
	echo -e \\n \\t "This script makes certain assumptions. First, this docker containers "
	echo -e \\t "public key has been added to the master's root users autherized keys so"
	echo -e \\t "that this docker container can ssh via keys to complete the cluster join."
	echo -e \\t "Second, it assumes the master has been set to connect to OP5 Docker via"
	echo -e \\t "ssh port 2222. Last, that all network firewalls are open on ports 2222 "
	echo -e \\t "and port 15551 as both ports are required to complete OP5 cluster join."
	echo -e \\t "****************************************************************************"	
	echo -e \\n \\t "Commandline Options: "
	echo -e \\t \\t "  ( ALL OPTIONS ARE REQUIRE UNLESS SPECIFIED)"
	echo -e \\t \\t "-i|--hostip            # REQUIRED: Ip address of the host running docker"
	echo -e \\t \\t "-n|--name		# REQUIRED: Hostname for the Docker container or OP5 instance"
	echo -e \\t \\t "-r|--role		# REQUIRED: OP5 role. poller or peer only options"
	echo -e \\t \\t "-s|--site		# REQUIRED: Site or hostgroup this OP5 instance will belong to"
	echo -e \\t \\t "-m|--masters		# REQUIRED: List of masters FQDN and IP addesses seperated by comma"
	echo -e \\t \\t "				(example: master1.op5.com,1.1.1.1,master2.op5.com,2.2.2.2)"
	echo -e \\t \\t "				(this script olny supports 1 or 2 masters)"
	echo -e \\t \\t "-u|--user          	# user for ssh access. If not specified centos is assumed" 
	echo -e \\t \\t "-h|--help		# This usage information"
	exit 0
}
	

# read the options
TEMP=`getopt -o r:s:n:i:m:h --long role:,site:,name:,hostip:,masters:,help --name $PROGNAME  -- "$@"`

if [[ $# -eq 0 ]]; then
    usage
    exit 3
fi

eval set -- "$TEMP"

SSH_USER="centos"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -r|--role) OP5_ROLE=$2; shift; shift ;;
        -s|--site) OP5_SITE=$2; shift; shift ;;
        -n|--name) MY_HOSTNAME=$2; shift; shift ;;
	-i|--hostip) MY_IPADDR=$2; shift; shift ;;
	-m|--masters) ALL_MASTERS=$2; shift; shift ;;
	-u|--user) SSH_USER=$2; shift; shift ;;
	-h|--help) shift; usage ;;
        --) shift ; break ;;
        *) 
    esac
done

echo "Verifying Required information is present."

if [ -z "$OP5_ROLE" ]; then
  echo "OP5_ROLE not defined as Poller or Peer"
  exit 1
fi
if [ -z "$OP5_SITE" ]; then
  echo "OP5_SITE not defind. This should be the default Hostgroup used for this $OP5_ROLE."
  exit 1
fi
if [ -z "$ALL_MASTERS" ]; then
  echo "No master defined. try again."
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

echo "Building op5.env file based on information provided"

cat > op5.env << EOF
OP5_ROLE=$OP5_ROLE
OP5_SITE=$OP5_SITE
MY_HOSTNAME=$MY_HOSTNAME
MY_IPADDR=$MY_IPADDR
EOF

cat > op5_hosts << EOF
#### Added via docker_deploy script ###

EOF

IFS="," read -r -a all_masters <<< "$ALL_MASTERS"
cnt=1
for index in "${!all_masters[@]}"
do
	
	if valid_ip ${all_masters[index]}; then
		echo "OP5_MASTER0$((cnt))_IP=${all_masters[index]}" >> op5.env
		op5_hosts_ip=${all_masters[index]}
	else
		echo "OP5_MASTER0$((cnt))=${all_masters[index]}" >> op5.env
		op5_hosts_name=${all_masters[index]}
		if [ "$cnt" == 1 ]; then
			OP5_MASTER01="${all_masters[index]}"
		fi
	fi
	t_rnd=$((index % 2))
	if [ "$t_rnd" == 1 ]; then
		((cnt++))
		echo "$op5_hosts_ip $op5_hosts_name" >> op5_hosts
	fi
done

cat >> op5_hosts << EOF

#### End Host additions via docker_deploy script  ###

EOF

if [ -z "$OP5_MASTER01" ]; then
  echo "OP5_MASTER Option was invaild or was in wrong format. Please specify as:"
  echo " master.op5.com,1.1.1.1,master2.op5.com,2.2.2.2 "
  exit 1
fi


### At this point we ahve all files and everything we shoudl need to copy and build the docker container 
echo "Copying files to $MY_HOSTNAME."

scp Dockerfile id_rsa op5.env authorized_keys op5_sync.sh op5_hosts start.sh run_op5.sh add_node.sh $SSH_USER@$MY_IPADDR:/tmp

if (($? > 0)); then
	echo -e "${REV}${BOLD}The scp command to $MY_IPADDR failed!!${NORM}"
	echo "Exiting now"
	exit 1
fi

ssh $SSH_USER@$MY_IPADDR "cd /tmp; sudo docker build -t $MY_HOSTNAME ."

if (($? > 0)); then
        echo "The Docker Build Failed!!!"
        echo "Exiting now"
        exit 1
fi


ssh $SSH_USER@$MY_IPADDR "cd /tmp; sudo chmod +x /tmp/run_op5.sh; sudo nohup /tmp/run_op5.sh -n $MY_HOSTNAME &"

if (($? > 0)); then
        echo "The docker run command failed!!!"
        echo "Exiting now"
        exit 1
fi

