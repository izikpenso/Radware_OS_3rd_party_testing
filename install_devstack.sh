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

#removes ip ssh known hosts
ssh-keygen -f ~/.ssh/known_hosts -R $VM_IP

#git Clone devstack to new VM
sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'git clone https://github.com/openstack-dev/devstack.git;'

#Copying localrc, resource file to devstack machine
sshpass -p $VM_SSH_PASSWORD scp localrc $VM_SSH_USER@$VM_IP:~/devstack/.

sshpass -p $VM_SSH_PASSWORD scp $1 $VM_SSH_USER@$VM_IP:~/devstack/.

#Editing localrc: Adding HOST_IP,FLAT_INTERFACE ,NEUTRON_BRANCH parameters
#sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'echo 'HOST_IP="$VM_IP"' >> ~/devstack/localrc; echo FLAT_INTERFACE=eth0 >> ~/devstack/localrc'
sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'echo 'HOST_IP="$VM_IP"' >> ~/devstack/localrc; echo FLAT_INTERFACE=eth0 >> ~/devstack/localrc ; echo 'NEUTRON_LBAAS_BRANCH="$NEUTRON_LBAAS_GERRIT_REFSPEC"' >> ~/devstack/localrc; echo 'TEMPEST_BRANCH="$TEMPEST_GERRIT_REFSPEC"' >> ~/devstack/localrc; echo 'NOVA_BRANCH="$NOVA_GERRIT_REFSPEC"' >> ~/devstack/localrc;'
