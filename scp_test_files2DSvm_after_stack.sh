#!/bin/bash

# This script was should work only in Ubuntu machines.

usage(){
        echo "Usage: $0 filename ; the file should contain all the necessary environment variables for the script to run. see jobrc_sample file"
        exit 1
}

if (( $# != 1 )); then
   usage
fi

#source the resource file that contains all the needed environment variables for script to run.
echo "will use file $1"
source $1


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

# copying vdirect_cfg with modified test.cf to tempest dir

sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'cp -r ~/scripts/vdirect_cfg/ /opt/stack/tempest/tempest/api/network/'

# copying radware files to Devstack VM 

sshpass -p $VM_SSH_PASSWORD scp -r vdirect_cfg/  $VM_SSH_USER@$VM_IP:/opt/stack/tempest/tempest/api/network/


