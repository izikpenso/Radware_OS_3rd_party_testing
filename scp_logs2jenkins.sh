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

source $1

if [ -z "$GERRIT_REFSPEC" ]; then
      echo "VM_NAME: $VM_NAME"
      #LOG_FILE_NAME="${VM_NAME}_${BUILD_ID}.tar.gz"
      LOG_FOLDER_NAME="${VM_NAME}_${BUILD_ID}"
else
      echo "GERRIT_REFSPEC is: $GERRIT_REFSPEC"
      #LOG_FILE_NAME="${GERRIT_CHANGE_NUMBER}_${GERRIT_PATCHSET_NUMBER}_${BUILD_ID}.tar.gz"
      LOG_FOLDER_NAME="${GERRIT_CHANGE_NUMBER}_${GERRIT_PATCHSET_NUMBER}_${BUILD_ID}"
fi


mkdir $LOG_FOLDER_NAME


# Get vDirect history log

sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'source ~/devstack/jobrc; python ~/scripts/vdirect_cfg/vdirect_get_history.py $CFG_FILE'


cp /var/lib/jenkins/jobs/$JOB_NAME/builds/$BUILD_NUMBER/log $LOG_FOLDER_NAME/console.log

#sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'tar cvzf screen-logs.tar.gz ~/devstack/logs/;'

sshpass -p $VM_SSH_PASSWORD scp -r $VM_SSH_USER@$VM_IP:~/devstack/logs/ $LOG_FOLDER_NAME/.

sshpass -p $VM_SSH_PASSWORD scp $VM_SSH_USER@$VM_IP:~/*log* $LOG_FOLDER_NAME/.

sshpass -p $VM_SSH_PASSWORD scp $VM_SSH_USER@$VM_IP:~/devstack/jobrc $LOG_FOLDER_NAME/jobrc_modified


