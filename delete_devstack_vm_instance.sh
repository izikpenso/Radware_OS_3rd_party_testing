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
source jobrc

#Delete devstack VM on the Openstack server
sshpass -p $OPENSTACK_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $OPENSTACK_SSH_USER@$OPENSTACK_SERVER_IP 'source '"$OPENSTACK_KEYSTONERC_FILE"'; nova delete '"$VM_NAME"''
