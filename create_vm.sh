#!/bin/bash

# This script was should work only in Ubuntu machines.

usage(){
	echo "Usage: $0 filename ; the file should contain all the necessary environment variables for the script to run. see jobrc_sample file"
	exit 1
}

if (( $# != 1 )); then
   usage
fi

# sshpass cmd sould be installed fo this script to work, cheking
if ! which sshpass > /dev/null; then
   echo -e "sshpass command not found! this package should be installed for this script will be able to run, would you like to install it now? (y/n) \c"
   read REPLY
   if [ "$REPLY" == "y" ]; then
      sudo apt-get --force-yes --yes install sshpass
   else
      echo "Script can't run if sshpass package isn't installed, exiting script!"
      exit 0
   fi
fi

#source the resource file that contains all the needed environment variables for script to run. 
echo "will use the following resource file - $1"
source $1

#Removes ip ssh known hosts
ssh-keygen -f ~/.ssh/known_hosts -R $OPENSTACK_SERVER_IP

#Getting tne Network ID from openstack server
export NET_ID=$(sshpass -p $OPENSTACK_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $OPENSTACK_SSH_USER@$OPENSTACK_SERVER_IP 'source '"$OPENSTACK_KEYSTONERC_FILE"';neutron net-show '"$NETWORK_NAME"'' | grep ' id ' | cut -d '|' -f 3 | cut -d " " -f 2)

#Booting up new VM and getting the VM ID from openstack server
export VM_ID=$(sshpass -p $OPENSTACK_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $OPENSTACK_SSH_USER@$OPENSTACK_SERVER_IP 'source '"$OPENSTACK_KEYSTONERC_FILE"';  nova boot --poll --flavor '"$FLAVOR"' --image '"$IMAGE_NAME"' '"$VM_NAME"' --nic net-id='"$NET_ID"'' | grep " id " | cut -d "|" -f 3 | cut -d " " -f 2)

# wait 100 seconds to make sure the boot started.
sleep 100s

#Getting tne new VM ID from openstack server
export VM_IP=$(sshpass -p $OPENSTACK_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $OPENSTACK_SSH_USER@$OPENSTACK_SERVER_IP 'source '"$OPENSTACK_KEYSTONERC_FILE"'; nova show '"$VM_ID"'' | grep network | cut -d "|" -f 3 | cut -d " " -f 2)

#removes ip ssh known hosts
ssh-keygen -f ~/.ssh/known_hosts -R $VM_IP

#Adding the VM hostname to the /etc/hosts file on the VM itself.
sshpass -p $VM_SSH_PASSWORD ssh -v -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'echo '"$VM_IP"' '"$VM_NAME"'.'"$VM_DOMAIN"' '"$VM_NAME"' | sudo tee -a /etc/hosts'

# Adding VM_IP to resource file, so we can use it later.
echo "export VM_IP=$VM_IP" >> $1


