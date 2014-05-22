#!/usr/bin/env bash


source ~/devstack/jobrc

source ~/devstack/openrc admin demo

POOL_NAME="pool_2_leg"
VIP_NAME="vip_2_leg"

SERVER_SUBNET_ID=$(neutron net-list | grep ${PRIVATE_NETWORK_ID} | get_field 3 | cut -d " " -f 1)

echo "export SERVER_SUBNET_ID=$SERVER_SUBNET_ID" | sudo tee -a ~/devstack/jobrc

sleep 3

CLIENT_SUBNET_ID=$(neutron net-list | grep ${CLIENT_NETWORK_ID} | get_field 3 | cut -d " " -f 1)

echo "export CLIENT_SUBNET_ID=$CLIENT_SUBNET_ID" | sudo tee -a ~/devstack/jobrc

sleep 3

neutron lb-pool-create --name $POOL_NAME --lb-method ROUND_ROBIN --protocol HTTP --subnet-id ${SERVER_SUBNET_ID}

sleep 3

HM_ID=$(neutron lb-healthmonitor-create --delay 3 --max-retries 3 --timeout 3 --type HTTP | grep ' id ' | get_field 2)

echo "export HM_ID=$HM_ID" | sudo tee -a ~/devstack/jobrc

sleep 3

neutron lb-healthmonitor-associate ${HM_ID} ${POOL_NAME}

sleep 3

neutron lb-member-create --address ${WEB_SRV1_IP} --protocol-port 80 ${POOL_NAME}

sleep 3

neutron lb-member-create --address ${WEB_SRV2_IP} --protocol-port 80 ${POOL_NAME}

sleep 3

VIP_ID=$(neutron lb-vip-create --name ${VIP_NAME} --protocol-port 80 --protocol HTTP --subnet-id ${CLIENT_SUBNET_ID} ${POOL_NAME} | grep ' id ' | get_field 2)

echo "export VIP_ID=$VIP_ID" | sudo tee -a ~/devstack/jobrc

sleep 3

VIP_PORT_ID=$(neutron lb-vip-show $VIP_ID | grep ' port_id ' | get_field 2)

echo "export VIP_PORT_ID=$VIP_PORT_ID" | sudo tee -a ~/devstack/jobrc

sleep 3

VIP_IP=$(neutron lb-vip-show ${VIP_ID} | grep ' address ' | get_field 2)

echo "export VIP_IP=$VIP_IP" | sudo tee -a ~/devstack/jobrc

sleep 3

VIP_FLOATING_IP_ID=$(neutron floatingip-create public | grep ' id ' | get_field 2)

echo "export VIP_FLOATING_IP_ID=$VIP_FLOATING_IP_ID" | sudo tee -a ~/devstack/jobrc

sleep 3

VIP_FLOATING_IP=$(neutron floatingip-show ${VIP_FLOATING_IP_ID} | grep ' floating_ip_address ' | get_field 2)

echo "export VIP_FLOATING_IP=$VIP_FLOATING_IP" | sudo tee -a ~/devstack/jobrc

sleep 3

neutron floatingip-associate ${VIP_FLOATING_IP_ID} ${VIP_PORT_ID}

sleep 3
