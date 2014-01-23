#!/bin/bash

# This script was should work only in Ubuntu machines.

usage(){
        echo "Usage: $0 filename ; the file should contain all the necessary environment variables for the script to run. see jobrc_sample file"
        exit 1
}

if (( $# != 1 )); then
    usage
        exit 0
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
source $1

#git Clone devstack to new VM
sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'git clone https://github.com/openstack-dev/devstack.git; mkdir ~/scripts'

#Copying localrc, resource file to devstack machine
sshpass -p $VM_SSH_PASSWORD scp localrc $VM_SSH_USER@$VM_IP:~/devstack/.

sshpass -p $VM_SSH_PASSWORD scp $1 $VM_SSH_USER@$VM_IP:~/devstack/.

#Editing localrc: Adding HOST_IP,FLAT_INTERFACE ,NEUTRON_BRANCH parameters
sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'echo 'HOST_IP="$VM_IP"' >> ~/devstack/localrc; echo FLAT_INTERFACE=eth0 >> ~/devstack/localrc ; echo 'NEUTRON_BRANCH="$GERRIT_REFSPEC"' >> ~/devstack/localrc;'

