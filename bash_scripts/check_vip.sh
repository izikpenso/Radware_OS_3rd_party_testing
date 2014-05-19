#!/usr/bin/env bash


source $1

source ~/devstack/openrc admin demo

if [ -n "$VIP_FLOATING_IP" ]; then
        echo "Waiting for VIP - $VIP_FLOATING_IP to respond..."
        wget -q  --tries=1 --timeout=2 $VIP_FLOATING_IP
        PING_STATUS=$?
        COUNTER=0
        while [ $PING_STATUS -ne 0 ] && [ $COUNTER -lt 300 ]
        do
                echo "Sleeping for 2 seconds...($COUNTER)"
                sleep 2
                COUNTER=$[COUNTER + 1]
                wget -q  --tries=1 --timeout=2 $VIP_FLOATING_IP
                PING_STATUS=$?
        done
        if [ $PING_STATUS -ne 0 ]; then
                echo "ERROR:Could not connect to VIP - $VIP_FLOATING_IP after waiting 5 minutes "
                exit 1
        else
                echo "** VIP responded successfully. **"
        fi
fi
