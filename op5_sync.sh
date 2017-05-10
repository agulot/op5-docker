#!/bin/bash

PROGNAME=${0##*/}
ARGS=$(getopt -o n: --name $PROGNAME  -- "$@")

eval set -- "$ARGS"

while true ; do
    case "$1" in
        -n|--name) NODENAME=$2; shift; shift ;;
        -h|--help) usage ;;
        --) shift ; break ;;
        *)
    esac
done

if [ -z "$NODENAME" ]; then
        echo "Failed to get node name. Exiting"
        exit 1
fi


/bin/systemctl restart  naemon.service
asmonitor mon oconf push $NODENAME
mon node ctrl $NODENAME mon restart
mon node ctrl --self --type=peer mon restart

exit 0
