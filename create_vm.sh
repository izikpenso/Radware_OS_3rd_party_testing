#!/bin/bash

usage(){
	echo "Usage: $0 filename ; the file should contain the necessary environment, variables see jobrc_exmple file"
	exit 1
}

if (( $# != 1 )); then
    usage
	exit 0
fi

#source the jobrc file that contains all the needed environment variables for script to run. 
echo "will use file $1"
source $1

#echoing gerrit patch that tirrgered the build
echo "GERRIT_REFSPEC = $GERRIT_REFSPEC"

#echoing job build number.
echo "Build number = $BUILD_NUMBER "

#Removes ip ssh known hosts
ssh-keygen -f ~/.ssh/known_hosts -R $OPENSTACKSERVERIP #removes ip ssh known hosts

#Getting tne Network ID from openstack server
export NET_ID=$(sshpass -p radware ssh -o "StrictHostKeyChecking no" root@$OPENSTACKSERVERIP 'source ~/keystonerc_demo;neutron net-show '"$NETWORKNAME"'' | grep ' id ' | cut -d '|' -f 3 | cut -d " " -f 2)

#Booting up new VM and getting the VM ID from openstack server
export VM_ID=$(sshpass -p radware ssh -o "StrictHostKeyChecking no" root@$OPENSTACKSERVERIP 'source ~/keystonerc_demo;  nova boot --poll --flavor '"$FLAVOR"' --image '"$IMAGE"' devstack-vm'"$BUILD_NUMBER"' --nic net-id='"$NET_ID"' --key-name '"$KEY_NAME"'' | grep " id " | cut -d "|" -f 3 | cut -d " " -f 2)

sleep 60s

#Getting tne new VM ID from openstack server
export VM_IP=$(sshpass -p radware ssh -o "StrictHostKeyChecking no" root@$OPENSTACKSERVERIP 'source ~/keystonerc_demo; nova show '"$VM_ID"'' | grep network | cut -d "|" -f 3 | cut -d " " -f 2)


sed -i "s/devstack_dummy_ip/$VM_IP/g" vdirect_cfg/test.cfg


#removes ip ssh known hosts
ssh-keygen -f ~/.ssh/known_hosts -R $VM_IP 

#Adding the VM hostname to the /etc/hosts file on the VM itself
sshpass -p radware ssh -o "StrictHostKeyChecking no" ubuntu@$VM_IP 'echo '"$VM_IP"' devstack-vm'"$BUILD_NUMBER"'.vdirect.com devstack-vm'"$BUILD_NUMBER"' | sudo tee -a /etc/hosts || true'

echo "export VM_IP=$VM_IP" >> $1


