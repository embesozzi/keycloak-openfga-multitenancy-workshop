#!/usr/bin/env bash

set -e


function help () {
    prog=$(basename $0)
    err=$2

    cat <<EOF
        Usage:
        $prog [OPTIONS] COMMAND <TARGET> <REV>

        Tool for managing the multitenancy workshop.

        OPTIONS:
            -h|--help          : display usage and exit
            up                 : startup demo
            down               : destroy demo
EOF

    if [ ! -z "$err" ] ; then
        echo "ERROR: $err"
        echo
    fi

}    

case $1 in
    up) docker compose -f idp.yaml -f fga.yaml -f apps.yaml -f imports.yaml up 
    ;;
    down) docker compose -f idp.yaml -f fga.yaml -f apps.yaml -f imports.yaml down --volumes
    ;;
    help|-h) help 
    ;;
    *) help 
    ;;
esac