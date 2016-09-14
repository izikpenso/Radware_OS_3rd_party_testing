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

ALTEON_IMAGE_NAME=$(echo $ALTEON_IMAGE_FILE | rev | cut -d. -f2- | rev)
glance image-create --name ${ALTEON_IMAGE_NAME} --file ~/images/$ALTEON_IMAGE_FILE  --disk-format qcow2 --container-format bare --visibility public

#
# create admin network called mng-network
#
MNG_NETWORK_ID=`neutron net-create mng-network -f shell -c id | grep id | awk 'BEGIN { FS = "=" } ; { print $2 }' | tr -d '"' `


#
# Adding new netowrk id to resource file so it can be used later
#
echo "export MNG_NETWORK_ID=$MNG_NETWORK_ID" | sudo tee -a ~/devstack/jobrc

#
# create subnet to MNG-network on 192.168.23.0 255.255.255.0 192.168.23.1 with allocation pool of 192.168.23.100, 192.168.23.199
#

MNG_SUBNET_ID=`neutron subnet-create --name mng-subnet --gateway 192.168.23.1 --allocation_pool start=192.168.23.100,end=192.168.23.199 $MNG_NETWORK_ID 192.168.23.0/24 | grep " id " | cut -d "|" -f 3`

#
# Adding gateway for the mng-network
#

neutron router-interface-add router1 $MNG_SUBNET_ID

#
# Adding route to the linux machine 
#
#sudo route add -net 192.168.23.0/24 gw 172.24.4.2
PUBLIC_SUBNET=`neutron subnet-show public-subnet | grep ' id ' | cut -d "|" -f 3 | tr -d '[[:space:]]'`
ROUTER_INT_IP=`neutron router-show router1 | grep external_gateway_info | cut -d "|" -f 3 | cut -d '[' -f 2 | tr "{" "\n" | grep $PUBLIC_SUBNET | tr "," "\n" | grep "ip_address" | cut -d ":" -f 2 | cut -d "}" -f 1 | tr -d '[[:space:]]' | tr '"' ' '`
sudo route add -net 192.168.23.0/24 gw $ROUTER_INT_IP

#
# create admin network called ha-network
#
HA_NETWORK_ID=`neutron net-create ha-network -f shell -c id | grep id | awk 'BEGIN { FS = "=" } ; { print $2 }' | tr -d '"' `


#
# Adding new netowrk id to resource file so it can be used later
#
echo "export HA_NETWORK_ID=$HA_NETWORK_ID" | sudo tee -a ~/devstack/jobrc

#
# create subnet to ha-network on 192.168.100.0 255.255.255.0 192.168.100.1 with allocation pool of 192.168.100.100, 192.168.100.199
#
neutron subnet-create --name ha-subnet --gateway 192.168.100.1 --allocation_pool start=192.168.100.100,end=192.168.100.199 $HA_NETWORK_ID 192.168.100.0/24 


SERVER_NETWORK_ID=`neutron net-create server-network -f shell -c id | grep id | awk 'BEGIN { FS = "=" } ; { print $2 }' | tr -d '"' `

#
# Adding new netowrk id to resource file so it can be used later
#

echo "export SERVER_NETWORK_ID=$SERVER_NETWORK_ID" | sudo tee -a ~/devstack/jobrc


#
# create subnet to server-network on 192.168.200.0 255.255.255.0 192.168.200.1 with allocation pool of 192.168.200.100, 192.168.200.199
#
neutron subnet-create --name server-subnet --gateway 192.168.200.1 --allocation_pool start=192.168.200.100,end=192.168.200.199 $SERVER_NETWORK_ID 192.168.200.0/24 

#
# change project to demo
#
source ~/devstack/openrc demo demo

#
# modify sec groups

neutron security-group-rule-create --direction ingress --remote-ip-prefix 0.0.0.0/0 default

#
# change project to demo
#
source ~/devstack/openrc admin demo

#
# Add new flavor for Alteon

nova flavor-create --is-public true Alteon 101 3072 20 1

#
# make the networks shared
#
declare -a NETWORKS=('mng-network' 'server-network' 'ha-network');
for network in "${NETWORKS[@]}"
do
  neutron net-update "${network}" --shared
done

#
# locate the private network id
#


echo "export NETWORK_MANAGEMENT_ID=$MNG_NETWORK_ID" | sudo tee -a ~/devstack/jobrc

#
# Installing vDirect
#
sudo dpkg -i ~/images/$VDIRECT_RPM_INSTALLER

# Configuring vDirect
#
sudo sed -i '$ a\vdirect.auth.enableOnDemandTenants=true' /opt/radware/vdirect/database/configuration.properties

#
# Starting vDirect
#
sudo service vdirect start

VDIRECT_IP=$VM_IP

#
# Adding the vDirect IP  to resource file so it can be used later
#
echo "export VDIRECT_IP=$VDIRECT_IP" | sudo tee -a ~/devstack/jobrc


VDIRECT_URL=http://$VDIRECT_IP:2188

#
# wait for vDirect to be up and running
#
echo "Waiting for vDirect to start..."

wget -q  --tries=1 --timeout=2  $VDIRECT_URL/api
PING_STATUS=$?
COUNTER=0
while [ $PING_STATUS -ne 0 ] && [ $COUNTER -lt 300 ]
 do
  echo "Sleeping for 6 seconds...($COUNTER)"
  sleep 6
  COUNTER=$[COUNTER + 1]
  wget -q  --tries=1 --timeout=2 $VDIRECT_URL/api
  PING_STATUS=$?
done

if [ $PING_STATUS -ne 0 ]; then
 echo "ERROR:Could not connect to vDirect after waiting 30 minutes "
 
else
 echo "vDirect is up and running."
 ~/scripts/./edit_vdirect_conf_file.sh ~/scripts/vdirect_cfg/test.cfg
 python ~/scripts/vdirect_cfg/vdirect_lbaas_cfg.py ~/scripts/vdirect_cfg/test.cfg
 
fi
