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


#source the jobrc file that contains all the needed environment variables for script to run. 
source $1

sshpass -p $VM_SSH_PASSWORD scp restart_neutron_server_with_radware_lbaas.sh $VM_SSH_USER@$VM_IP:~/scripts/.

sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'chmod a+x ~/scripts/restart_neutron_server_with_radware_lbaas.sh; ~/scripts/restart_neutron_server_with_radware_lbaas.sh'
