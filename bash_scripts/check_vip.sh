#!/usr/bin/env bash


source $1

source ~/devstack/openrc admin demo


if [ -n "$VIP_FLOATING_IP" ]; then
        echo "Waiting for VIP - $VIP_FLOATING_IP status to be ACTIVE..."
        VIP_STATUS=$(neutron lb-vip-show $VIP_ID | grep " status " | get_field 2)
        COUNTER=0
        while [ $VIP_STATUS != 'ACTIVE' ] && [ $COUNTER -lt 300 ]
        do
                echo "Sleeping for 10 seconds...($COUNTER)"
                sleep 10
                COUNTER=$[COUNTER + 1]
                VIP_STATUS=$(neutron lb-vip-show $VIP_ID | grep " status " | get_field 2)
        done
        if [ $VIP_STATUS != 'ACTIVE' ]; then
                echo "ERROR: VIP - $VIP_FLOATING_IP status is not ACTIVE after waiting for 5 minutes "
                exit 1
        else
                echo "** VIP status is ACTIVE. **"
        fi
fi


if [ -n "$VIP_FLOATING_IP" ] && [ $VIP_STATUS = 'ACTIVE' ]; then
        echo "Waiting for VIP - $VIP_FLOATING_IP to respond to wget..."
        wget -q  --tries=1 --timeout=2 $VIP_FLOATING_IP
        PING_STATUS=$?
        COUNTER=0
        while [ $PING_STATUS -ne 0 ] && [ $COUNTER -lt 60 ]
        do
                echo "Sleeping for 2 seconds...($COUNTER)"
                sleep 2
                COUNTER=$[COUNTER + 1]
                wget -q  --tries=1 --timeout=2 $VIP_FLOATING_IP
                PING_STATUS=$?
        done
        if [ $PING_STATUS -ne 0 ]; then
                echo "ERROR:Could not connect to VIP - $VIP_FLOATING_IP with wget after waiting 1 minute from status changed to ACTIVE "
                exit 1
        else
                echo "** VIP responded successfully. **"
        fi
fi

