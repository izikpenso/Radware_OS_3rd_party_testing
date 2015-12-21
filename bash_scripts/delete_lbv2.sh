#!/usr/bin/env bash


function usage {
	echo "    Error: argument is missing"
	echo "    Usage: $0 <LOADBALNCER_V2_ID>"
	exit 1
}

if (( $# != 1 )); then
   usage
fi

function wait_for_lb_provisioning_status {
        TIMEOUT=60 # 1 Min
        START=$(date +%s);
        STATUS=$(neutron lbaas-loadbalancer-show $LB_ID | grep provisioning_status | cut -d "|" -f 3 | tr -d '[[:space:]]')
	while [ $STATUS != "ACTIVE" ] && [ $((NOW-START)) -lt $TIMEOUT ]
        do
                STATUS=$(neutron lbaas-loadbalancer-show $LB_ID | grep provisioning_status | cut -d "|" -f 3 | tr -d '[[:space:]]')
                #echo "LB status is $STATUS"
                sleep 10
                NOW=$(date +%s);
        done
}

function quit_script {
	echo ""
        echo "$0 Failed" 
	echo ""
	exit
}

LB_ID=$1

LB_EXISTS=$(neutron lbaas-loadbalancer-show $LB_ID)

if [ -z "$LB_EXISTS" ]; then
	quit_script
fi

if [ ! -z "$LB_ID" ]; then 
	LISTENERS=$(neutron lbaas-loadbalancer-show $LB_ID | grep {\"id\": | cut -d "|" -f 3 | cut -d ":" -f 2 |cut -d "}" -f 1 | tr -d '"')
else
	quit_script
fi
if [ ! -z "$LISTENERS" ]; then
	echo "LISTENERS=$LISTENERS"
	for listener in $LISTENERS
	do
		POOL_ID=$(neutron lbaas-listener-show $listener | grep " default_pool_id " | cut -d "|" -f 3 | tr -d '[[:space:]]')
		if [ ! -z "$POOL_ID" ]; then
			MEMBERS=$(neutron lbaas-member-list -f value $POOL_ID | cut -d " " -f 1)
			if [ ! -z "$MEMBERS" ]; then
				echo "MEMBERS=$MEMBERS"
				echo "Deleting Members ..."
				for member in $MEMBERS
				do
					neutron lbaas-member-delete $member $POOL_ID
					wait_for_lb_provisioning_status
				done
			else
				echo "No members for loadbalancer $LB_ID, skipping ..."	
			fi
			neutron lbaas-pool-delete $POOL_ID
			wait_for_lb_provisioning_status
		else
			echo "No pool for loadbalancer $LB_ID, skipping ..." 
		fi
        	neutron lbaas-listener-delete $listener
		wait_for_lb_provisioning_status
	done
else
	echo "No listeners for loadbalancer $LB_ID, skipping ..."
fi

neutron lbaas-loadbalancer-delete $LB_ID
