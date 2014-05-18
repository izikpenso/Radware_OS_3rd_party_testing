#!/usr/bin/env bash

# ---------------------------------------------------------- 
# Create the initial setup of Radware LBaaS OpenStack setup
# The Script is called from stack.sh
#
# ----------------------------------------------------------


set -x


#
# Createing alteon-va-project and alteon-lbaas-admin user
#

source ~/devstack/openrc admin admin

ALTEON_VA_PROJECT_NAME="alteon-va-project"
ALTEON_LBAAS_ADMIN_NAME="alteon-lbaas-admin"
ALTEON_LBAAS_ADMIN_PASS="os"
RAD_ROUTER_1_PUB=public
VDIRECT_INSTANCE_NAME=vDirectVA
ALTEON_MGMT_NETWORK_NAME=alteon-mgmt-net
ALTEON_MGMT_SUBNET_NAME=alteon-mgmt-subnet
keystone tenant-create --name ${ALTEON_VA_PROJECT_NAME}
ALTEON_VA_PROJECT_ID=$(keystone tenant-list | grep " ${ALTEON_VA_PROJECT_NAME} " | get_field 1)
keystone user-create --name ${ALTEON_LBAAS_ADMIN_NAME} --tenant ${ALTEON_VA_PROJECT_ID} --pass ${ALTEON_LBAAS_ADMIN_PASS} 
keystone user-role-add --user ${ALTEON_LBAAS_ADMIN_NAME} --tenant ${ALTEON_VA_PROJECT_NAME} --role admin  

#
# change identity to ALTEON_LBAAS_ADMIN_NAM ALTEON_VA_PROJECT_NA
#
source ~/devstack/openrc ${ALTEON_LBAAS_ADMIN_NAME} ${ALTEON_VA_PROJECT_NAME}

source ~/devstack/jobrc


#
# create the Alteon image 
#
ALTEON_IMAGE_NAME=$(echo $ALTEON_IMAGE_FILE | rev | cut -d. -f2- | rev)
glance image-create --name ${ALTEON_IMAGE_NAME} --file ~/images/$ALTEON_IMAGE_FILE  --disk-format qcow2 --container-format bare

#
# create the vDirect image
#

VDIRECT_IMAGE_NAME=$(echo $VDIRECT_IMAGE_FILE | rev | cut -d. -f2- | rev)
glance image-create --name ${VDIRECT_IMAGE_NAME} --file ~/images/$VDIRECT_IMAGE_FILE --disk-format qcow2 --container-format bare

#
# 1. create network and subnet called alteon-mgmt in ALTEON_VA_PROJECT_NAME
#

ALTEON_MGMT_NETWORK_ID=`neutron net-create ${ALTEON_MGMT_NETWORK_NAME} -f shell -c id | grep id | awk 'BEGIN { FS = "=" } ; { print $2 }' | tr -d '"' `

# Adding new netowrk id to resource file so it can be used later
echo "export ALTEON_MGMT_NETWORK_ID=$ALTEON_MGMT_NETWORK_ID" | sudo tee -a ~/devstack/jobrc

# create subnet to alteon-mgmt on 192.168.155.0 255.255.255.0 192.168.155.1 with allocation pool of 192.168.155.100, 192.168.155.199
neutron subnet-create --name ${ALTEON_MGMT_SUBNET_NAME} --gateway 192.168.155.1 --allocation_pool start=192.168.155.100,end=192.168.155.199 $ALTEON_MGMT_NETWORK_ID 192.168.155.0/24

#
# 2. create network and subnet  called ha-network in ALTEON_VA_PROJECT_NAME
#

HA_NETWORK_ID=`neutron net-create ha-network -f shell -c id | grep id | awk 'BEGIN { FS = "=" } ; { print $2 }' | tr -d '"' `

# Adding new netowrk id to resource file so it can be used later
echo "export HA_NETWORK_ID=$HA_NETWORK_ID" | sudo tee -a ~/devstack/jobrc

# create subnet to ha-network on 192.168.100.0 255.255.255.0 192.168.100.1 with allocation pool of 192.168.100.100, 192.168.100.199
neutron subnet-create --name ha-subnet --gateway 192.168.100.1 --allocation_pool start=192.168.100.100,end=192.168.100.199 $HA_NETWORK_ID 192.168.100.0/24 


#
# 3. create network and subnet called dummy-network in ALTEON_VA_PROJECT_NAME
#

DUMMY_NETWORK_ID=`neutron net-create dummy-network -f shell -c id | grep id | awk 'BEGIN { FS = "=" } ; { print $2 }' | tr -d '"' `

# Adding new netowrk id to resource file so it can be used later
echo "export DUMMY_NETWORK_ID=$DUMMY_NETWORK_ID" | sudo tee -a ~/devstack/jobrc

# create subnet to dummy_network on 192.168.199.0 255.255.255.0 192.168.199.1 with allocation pool of 192.168.199.100, 192.168.199.199
neutron subnet-create --name dummy-subnet --gateway 192.168.199.1 --allocation_pool start=192.168.199.100,end=192.168.199.199 $DUMMY_NETWORK_ID 192.168.199.0/24

#
# Create 2 security groups one for vDirect and one for Alteon, both of them will be creared under ALTEON_VA_PROJECT_NAME.
#

# Createing vdirectva sec group

neutron security-group-create --tenant-id ${ALTEON_VA_PROJECT_ID} vdirectva --description vdirectva
neutron security-group-rule-create --remote-ip-prefix 0.0.0.0/0 --direction ingress vdirectva

# Createing alteonva sec group

neutron security-group-create --tenant-id ${ALTEON_VA_PROJECT_ID} alteonva --description alteonva
neutron security-group-rule-create --remote-ip-prefix 0.0.0.0/0 --direction ingress alteonva

# Create Router in ALTEON_VA_PROJECT_NAME

RAD_ROUTER_1_ID=$(neutron router-create --tenant-id ${ALTEON_VA_PROJECT_ID} router_radware | grep " id " | get_field 2)
RAD_ROUTER_1_PUB_ID=$(neutron net-list | grep " ${RAD_ROUTER_1_PUB} " | get_field 1)
RAD_ROUTER_1_PRI_ID=$(neutron subnet-list | grep " ${ALTEON_MGMT_SUBNET_NAME} " | get_field 1)
neutron router-gateway-set ${RAD_ROUTER_1_ID} ${RAD_ROUTER_1_PUB_ID} 
neutron router-interface-add ${RAD_ROUTER_1_ID} ${RAD_ROUTER_1_PRI_ID}

#
# Boot the vDirect
#

VM_ID=$(nova boot --poll --flavor 'm1.small' --image ${VDIRECT_IMAGE_NAME} ${VDIRECT_INSTANCE_NAME} --nic net-id=${ALTEON_MGMT_NETWORK_ID} --security-groups vdirectva | grep " id " | cut -d "|" -f 3 | cut -d " " -f 2)

#
# setting floating IP to vDirect VA
#

VDIRECT_FLOATING_IP=$(neutron floatingip-create --tenant-id ${ALTEON_VA_PROJECT_ID} ${RAD_ROUTER_1_PUB} | grep " floating_ip_address " | get_field 2)
nova add-floating-ip ${VDIRECT_INSTANCE_NAME} ${VDIRECT_FLOATING_IP}

VDIRECT_IP=${VDIRECT_FLOATING_IP}
#
# Adding the vDirect IP  to resource file so it can be used later
#
echo "export VDIRECT_IP=$VDIRECT_IP" | sudo tee -a ~/devstack/jobrc

if [ -n "$VDIRECT_IP" ]; then
	VDIRECT_URL=http://$VDIRECT_IP:2188
	#
	# wait for vDirect to be up and running
	#
	echo "Waiting for vDirect to start..."
	wget -q  --tries=1 --timeout=2 $VDIRECT_URL/api
	PING_STATUS=$?
	COUNTER=0
	while [ $PING_STATUS -ne 0 ] && [ $COUNTER -lt 300 ]
 	do
  		echo "Sleeping for 2 seconds...($COUNTER)"
  		sleep 2
  		COUNTER=$[COUNTER + 1]
  		wget -q  --tries=1 --timeout=2  $VDIRECT_URL/api
  		PING_STATUS=$?
	done
	if [ $PING_STATUS -ne 0 ]; then
 		echo "ERROR:Could not connect to vDirect after waiting 5 minutes "
	else
 		echo "vDirect is up and running."
 		~/scripts/./edit_vdirect_conf_file.sh ~/scripts/vdirect_cfg/radware_test.cfg
 		python ~/scripts/vdirect_cfg/vdirect_lbaas_cfg.py ~/scripts/vdirect_cfg/radware_test.cfg
	fi
fi

source ~/devstack/openrc admin demo

#
# Create server_net in Demo 
#

PRIVATE_NETWORK_ID=`neutron net-show private -f shell -c id | awk 'BEGIN { FS = "=" } ; { print $2 }' | tr -d '"' `
echo "PRIVATE_NETWORK_ID = $PRIVATE_NETWORK_ID"

SERVER_NETWORK_ID=$PRIVATE_NETWORK_ID
echo "export SERVER_NETWORK_ID=$PRIVATE_NETWORK_ID" | sudo tee -a ~/devstack/jobrc

#
# Create Clinet_net in Demo
#

CLIENT_NETWORK_ID=`neutron net-create client-net -f shell -c id | grep id | awk 'BEGIN { FS = "=" } ; { print $2 }' | tr -d '"' `
echo "export CLIENT_NETWORK_ID=$CLIENT_NETWORK_ID" | sudo tee -a ~/devstack/jobrc
neutron subnet-create --name client-subnet --gateway 192.168.56.1 --allocation_pool start=192.168.56.100,end=192.168.56.199 $CLIENT_NETWORK_ID 192.168.56.0/24

#
# Add interfaces to Router
#

DEFAULT_ROUTER_ID=$(neutron router-list | grep router1 | get_field 1)
DEFAULT_ROUTER_PUB_ID=$(neutron net-list | grep " ${RAD_ROUTER_1_PUB} " | get_field 1)
CLIENT_SUBNET_ID=$(neutron subnet-list | grep "client-subnet" | get_field 1)
neutron router-interface-add ${DEFAULT_ROUTER_ID} ${CLIENT_SUBNET_ID}


#
# Create sg_webserver security group to allow all
#
neutron security-group-create sg_webserver --description sg_webserver
neutron security-group-rule-create --remote-ip-prefix 0.0.0.0/0 --direction ingress sg_webserver

#
# Upload webServer image in Demo , this part is relevant only for demos and POCs
#

WEBSERVER_IMAGE_NAME="WEB_SERVER_IMAGE"
glance image-create --name ${WEBSERVER_IMAGE_NAME} --file ~/images/$WEBSERVER_IMAGE_FILE  --disk-format qcow2 --container-format bare


#
# Launch 2 Web Servers , this part is relevant only for demos and POCs
#

VM_ID=$(nova boot --poll --flavor 'm1.micro' --image ${WEBSERVER_IMAGE_NAME} WebServer1 --nic net-id=${SERVER_NETWORK_ID} --security-groups sg_webserver | grep " id " | cut -d "|" -f 3 | cut -d " " -f 2)

WEB_SRV1_IP=$(nova show "$VM_ID" | grep network | cut -d "|" -f 3 | cut -d " " -f 2)

echo "export WEB_SRV1_IP=$WEB_SRV1_IP" | sudo tee -a ~/devstack/jobrc

VM_ID=$(nova boot --poll --flavor 'm1.micro' --image ${WEBSERVER_IMAGE_NAME} WebServer2 --nic net-id=${SERVER_NETWORK_ID} --security-groups sg_webserver | grep " id " | cut -d "|" -f 3 | cut -d " " -f 2)

WEB_SRV2_IP=$(nova show "$VM_ID" | grep network | cut -d "|" -f 3 | cut -d " " -f 2)

echo "export WEB_SRV2_IP=$WEB_SRV2_IP" | sudo tee -a ~/devstack/jobrc
