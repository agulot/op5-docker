#!/bin/bash

PROGNAME=${0##*/}
SCRIPT=`basename ${BASH_SOURCE[0]}`
ARGS=$(getopt -o n: --name $PROGNAME  -- "$@")

function usage {

echo -e \\t "${SCRIPT} requires the -n option."
echo -e \\t "${SCRIPT} -n <hostname>"
exit 1
} 

eval set -- "$ARGS"

while true ; do
    case "$1" in
        -n|--name) NODE_HOSTNAME=$2; shift; shift ;;
        -h|--help) usage ;;
        --) shift ; break ;;
        *)
    esac
done

if [ -z "$NODE_HOSTNAME" ]; then
	echo "Failed to get Hostname. Exiting"
	exit 1
fi

docker run -i --env-file /tmp/op5.env -p 80:80 -p 443:443 -p 2222:22 -p 5666:5666 -p 15551:15551 -p 162:162 -p 162:162/udp $NODE_HOSTNAME
