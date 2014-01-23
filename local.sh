#!/usr/bin/env bash

# ---------------------------------------------------------- 
# Create the initial setup of Radware LBaaS OpenStack setup
# The Script is called from stack.sh
#
# ----------------------------------------------------------


set -x

#
# change identity to admin
#
source ~/devstack/openrc admin admin

source ~/devstack/jobrc


#
# create the Alteon image 
#
if [ ! -f ~/images/$ALTEON_IMAGE ]; then
    echo "ERROR: File not found ~/images/$ALTEON_IMAGE"
fi

glance image-create --name Alteon-29-0-60-0 --file ~/images/$ALTEON_IMAGE  --disk-format qcow2 --container-format bare --is-public True


#
# create the vDirect image
#
glance image-create --name vDirect-VA-2-20-00 --file ~/images/$VDIRECT_IMAGE --disk-format qcow2 --container-format bare --is-public True

#
# create the Web image
#Not needed the test uses the cirros image as web server.
#glance image-create --name web-image --file ~/images/web-image.qcow2 --disk-format qcow2 --container-format bare --is-public True


#
# create admin network called ha-network
#
HA_NETWORK_ID=`neutron net-create ha-network -f shell -c id | grep id | awk 'BEGIN { FS = "=" } ; { print $2 }' | tr -d '"' `

echo "HA_NETWORK_ID = $HA_NETWORK_ID"
#
# Editing the test.cfg with the updated value
#

echo "export HA_NETWORK_ID=$HA_NETWORK_ID" | sudo tee -a ~/devstack/jobrc
#
# create subnet to ha-network on 192.168.100.0 255.255.255.0 192.168.100.1 with allocation pool of 192.168.100.100, 192.168.100.199
#
neutron subnet-create --name ha-subnet --gateway 192.168.100.1 --allocation_pool start=192.168.100.100,end=192.168.100.199 $HA_NETWORK_ID 192.168.100.0/24 


SERVER_NETWORK_ID=`neutron net-create server-network -f shell -c id | grep id | awk 'BEGIN { FS = "=" } ; { print $2 }' | tr -d '"' `

echo "SERVER_NETWORK_ID = $SERVER_NETWORK_ID"
#
echo "export SERVER_NETWORK_ID=$SERVER_NETWORK_ID" | sudo tee -a ~/devstack/jobrc


#
# create subnet to server-network on 192.168.200.0 255.255.255.0 192.168.200.1 with allocation pool of 192.168.200.100, 192.168.200.199
#
neutron subnet-create --name server-subnet --gateway 192.168.200.1 --allocation_pool start=192.168.200.100,end=192.168.200.199 $SERVER_NETWORK_ID 192.168.200.0/24 

#
# change identity to admin
#
source ~/devstack/openrc admin demo

#
# make the networks shared
#
declare -a NETWORKS=('private' 'server-network' 'ha-network');
for network in "${NETWORKS[@]}"
do
  neutron net-update "${network}" --shared
done

#
# modify sec groups
declare -a TENANTS=('demo' 'alt_demo');
for tenant in "${TENANTS[@]}"
do
  source openrc "${tenant}" "${tenant}"
  neutron security-group-rule-create --protocol tcp --direction ingress --remote-ip-prefix 0.0.0.0/0 --port-range-min 1 --port-range-max 65535 default
  neutron security-group-rule-create --protocol udp --direction ingress --remote-ip-prefix 0.0.0.0/0 --port-range-min 1 --port-range-max 65535 default
  neutron security-group-rule-create --protocol icmp --direction ingress --remote-ip-prefix 0.0.0.0/0 default
done

source ~/devstack/openrc admin demo

#
# locate the private network id
#

PRIVATE_NETWORK_ID=`neutron net-show private -f shell -c id | awk 'BEGIN { FS = "=" } ; { print $2 }' | tr -d '"' `
echo "PRIVATE_NETWORK_ID = $PRIVATE_NETWORK_ID"

echo "export NETWORK_MANAGEMENT_ID=$PRIVATE_NETWORK_ID" | sudo tee -a ~/devstack/jobrc

#

VM_ID=$(nova boot --poll --flavor 'm1.small' --image 'vDirect-VA-2-20-00' vDirectServer --nic net-id=$PRIVATE_NETWORK_ID | grep " id " | cut -d "|" -f 3 | cut -d " " -f 2)

sleep 30s

#
# finding the vDirect IP 
#
VDIRECT_IP=$(nova show "$VM_ID" | grep network | cut -d "|" -f 3 | cut -d " " -f 2)

echo "VDIRECT_IP = $VDIRECT_IP"

#
echo "export VDIRECT_IP=$VDIRECT_IP" | sudo tee -a ~/devstack/jobrc


VDIRECT_URL=http://$VDIRECT_IP:2188

#
# wait for vDirect to be up and running
#
echo "Waiting for vDirect to start..."

wget -q  $VDIRECT_URL/api
PING_STATUS=$?
COUNTER=0
while [ $PING_STATUS -ne 0 ] && [ $COUNTER -lt 300 ]
 do
  echo "Sleeping for 2 seconds...($COUNTER)"
  sleep 2
  COUNTER=$[COUNTER + 1]
  wget -q  $VDIRECT_URL/api
  PING_STATUS=$?
done

if [ $PING_STATUS -ne 0 ]; then
 echo "ERROR:Could not connect to vDirect after waiting 5 minutes "
 
else
 echo "vDirect is up and running."
 chmod a+x ~/scripts/edit_vdirect_conf_file.sh
 ~/scripts/./edit_vdirect_conf_file.sh
 python ~/scripts/vdirect_cfg/vdirect_lbaas_cfg.py ~/scripts/vdirect_cfg/test.cfg
 
fi

#
# add admin as a user to alt_demo
#
source ~/devstack/openrc admin demo
USER_ID=$(keystone user-list | grep admin | awk 'BEGIN { FS = "|" } ; { print $2 }' | tr -d " ")
ROLE_ID=$(keystone role-list | grep admin | awk 'BEGIN { FS = "|" } ; { print $2 }'| tr -d " " )
TENANT_ID=$(keystone tenant-list | grep alt_demo | awk 'BEGIN { FS = "|" } ; { print $2 }'| tr -d " ")
keystone user-role-add --user=$USER_ID --role=$ROLE_ID --tenant-id=$TENANT_ID



