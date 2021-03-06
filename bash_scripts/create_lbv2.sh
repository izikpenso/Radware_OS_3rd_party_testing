#!/usr/bin/env bash

LB_NAME=""
VIP_SUBNET_ID=""
SERVER_SUBNET_ID=""
SERVER_ADDRESSES=""
PUBLIC_NETWORK=""
HTTPS=""
CERTIFICATE_NAME=""


function helpmenu {
        echo ""
        echo "Usage: $0 [ --help | -h ]"
        echo ""
        echo "  --name                     LOADBALANCER_NAME"
        echo "  [--https]                  CERTIFICATE_NAME, When flag in use both HTTP and HTTPS listeners will be created for VIP"
        echo "  --vip_subnet_id            VIP_SUBNET_ID"
        echo "  --server_subnet_id         SERVER_SUBNET_ID"
        echo "  --server_address           SERVER_IP - This flag can be used number of times for multiple servers IPs"
        echo "  [--public_network]         PUBLIC_NETWORK_NAME - This flag is optional, when in use it will associate floating ip address to VIP"
        echo ""
        echo "Example:"
        echo "$0 --name <LOADBALANCER_NAME> --https <CERTIFICATE_NAME> --vip_subnet_id <VIP_SUBNET_ID> --server_subnet_id <SERVER_SUBNET_ID> /"
        echo "--server_address <IP1> --server_address <IP2> --public_network <PUBLIC_NETWORK_NAME>"
        echo ""
}

function wait_for_lb_provisioning_status {
        TIMEOUT=120 # 2 Min
        START=$(date +%s);
        NOW=$START;
        STATUS="PENDING_UPDATE"
        STATUS=$(neutron lbaas-loadbalancer-show $LB_ID | grep provisioning_status | cut -d "|" -f 3 | tr -d '[[:space:]]')
        while [ $STATUS != "ACTIVE" ] && [ $((NOW-START)) -lt $TIMEOUT ]
        do
                STATUS=$(neutron lbaas-loadbalancer-show $LB_ID | grep provisioning_status | cut -d "|" -f 3 | tr -d '[[:space:]]')
                echo "Waiting for LB status to be ACTIVE, Current LB status is $STATUS"
                if [ $STATUS = "ERROR" ]; then
                        echo " LB status is ERROR, somthing went wrong. exiting script ..."
                        exit 0
                fi
                sleep 3
                NOW=$(date +%s);
        done
}

function error_check {
        if [ "$?" -ne 0 ]; then echo ""; echo "ERROR: $0 failed"; exit 1; fi
}

function check_cmd {
        if [[ $ARG == --* ]]; then
                echo ""
                echo "Error: option $CMD missing argument"
                helpmenu
                exit
        fi
}

function create_listener {

        LISTENER_NAME="$LB_NAME"-"$PROTOCOL"-listener
        POOL_NAME="$LB_NAME"-"$PROTOCOL"-pool
        echo ""
        echo "  LISTENER_NAME = $LISTENER_NAME"
        echo "  POOL_NAME = $POOL_NAME"
        echo "  PROTOCOL = $PROTOCOL"
        echo "  PROTOCOL_PORT = $PROTOCOL_PORT"
        echo "  SERVER_ADDRESSES =$SERVER_ADDRESSES"
        echo " "
        echo "Starting $PROTOCOL Configuration....."
        echo ""

        if [ $PROTOCOL = "TERMINATED_HTTPS" ]; then
                LISTENER_ID=$(neutron lbaas-listener-create --name $LISTENER_NAME --loadbalancer $LB_ID --protocol $PROTOCOL --protocol-port $PROTOCOL_PORT --default-tls-container-ref=$CERTIFICATE_NAME | grep " id " | cut -d "|" -f 3 | tr -d '[[:space:]]')
        else
                LISTENER_ID=$(neutron lbaas-listener-create --name $LISTENER_NAME --loadbalancer $LB_ID --protocol $PROTOCOL --protocol-port $PROTOCOL_PORT | grep " id " | cut -d "|" -f 3 | tr -d '[[:space:]]')
        fi

        echo "  Listener ID = $LISTENER_ID"

        wait_for_lb_provisioning_status

        POOL_ID=$(neutron lbaas-pool-create --lb-algorithm ROUND_ROBIN --listener $LISTENER_ID --protocol HTTP --name $POOL_NAME | grep " id " | cut -d "|" -f 3 | tr -d '[[:space:]]')

        echo "  Pool ID = $POOL_ID"

        wait_for_lb_provisioning_status
        echo "  Creating Health Monitor... "
        HEALTH_ID=$(neutron lbaas-healthmonitor-create --delay 3 --max-retries 3 --timeout 3 --type HTTP --pool $POOL_NAME)

        I=0
        for ip in $SERVER_ADDRESSES
        do
                let I++
                echo "  Member $I - ${ip}"
                DUMMY=$(neutron lbaas-member-create --subnet $SERVER_SUBNET_ID --address $ip --protocol-port $REAL_PORT $POOL_ID)
                wait_for_lb_provisioning_status
        done
}

while [ ! $# -eq 0 ]
do
    case "$1" in
        --help | -h)
            helpmenu
            exit
            ;;
        --name)
            CMD=$1
            ARG=$2
            check_cmd
            LB_NAME=$2
            shift
            ;;
        --https)
            CMD=$1
            ARG=$2
            check_cmd
            HTTPS="TRUE"
            CERTIFICATE_NAME=$2
            shift
            ;;
        --vip_subnet_id)
            CMD=$1
            ARG=$2
            check_cmd
            VIP_SUBNET_ID=$2
            shift
            ;;
        --server_subnet_id)
            CMD=$1
            ARG=$2
            check_cmd
            SERVER_SUBNET_ID=$2
            shift
            ;;
        --server_address)
           CMD=$1
           ARG=$2
           check_cmd
           SERVER_ADDRESSES="$SERVER_ADDRESSES $2"
           shift
           ;;
        --public_network)
           CMD=$1
           ARG=$2
           check_cmd
           PUBLIC_NETWORK=$2
           shift
           ;;
        *)
           echo "error: invalid option : $1"
           helpmenu
           exit
           ;;
    esac
    shift
done

if [ ! -z "$LB_NAME" ] || [ ! -z "$VIP_SUBNET_ID" ] || [ ! -z "$SERVER_SUBNET_ID" ] || [ ! -z "$SERVER_ADDRESSES" ]; then

        echo ""
        echo "LOADBALNACER_NAME = $LB_NAME"

        LB_ID=$(neutron lbaas-loadbalancer-create $VIP_SUBNET_ID --name $LB_NAME | grep " id " | cut -d "|" -f 3 | tr -d '[[:space:]]')
        echo "Loadbalancer ID = $LB_ID"

        REAL_PORT="80"
        PROTOCOL="HTTP"
        PROTOCOL_PORT="80"

        create_listener

        if [ $HTTPS = "TRUE" ]; then
                        if [ ! -z "$CERTIFICATE_NAME" ]; then
                                        REAL_PORT="80"
                                        PROTOCOL="TERMINATED_HTTPS"
                                        PROTOCOL_PORT="443"
                                        create_listener
                        else
                                echo "error: Certificate name is missing for --https option"
                                helpmenu
                                exit
                        fi
        fi


        VIP_IP=$(neutron lbaas-loadbalancer-show $LB_ID | grep vip_address | cut -d "|" -f 3 | tr -d '[[:space:]]')
        echo "VIP_IP=$VIP_IP"

        if [ ! -z "$PUBLIC_NETWORK" ]; then

                VIP_PORT_ID=$(neutron lbaas-loadbalancer-show $LB_ID | grep ' vip_port_id ' | cut -d "|" -f 3 | tr -d '[[:space:]]')
                echo "VIP_PORT_ID = $VIP_PORT_ID"

                VIP_FLOATING_IP_ID=$(neutron floatingip-create $PUBLIC_NETWORK | grep ' id ' | cut -d "|" -f 3 | tr -d '[[:space:]]')
                echo "VIP_FLOATING_IP_ID = $VIP_FLOATING_IP_ID"

                VIP_FLOATING_IP=$(neutron floatingip-show ${VIP_FLOATING_IP_ID} | grep ' floating_ip_address ' | cut -d "|" -f 3 | tr -d '[[:space:]]')
                echo "VIP_FLOATING_IP = $VIP_FLOATING_IP"

                DUMMY=$(neutron floatingip-associate ${VIP_FLOATING_IP_ID} ${VIP_PORT_ID})
        fi
else
        echo ""
        echo "error: option is missing"
        helpmenu
        exit
fi

