#!/bin/bash


# This script was should work only in Ubuntu machines.

usage(){
        echo "Usage: $0 filename ; the file should contain all the necessary environment variables for the script to run. see jobrc_sample file"
        exit 1
}

if (( $# != 1 )); then
   usage
fi


#source the jobrc file that contains all the needed environment variables for script to run. 
source $1


sshpass -p $LOG_SERVER_PASSWORD ssh -o "StrictHostKeyChecking no" $LOG_SERVER_USER@$LOG_SERVER_IP 'mkdir /data/RADWARE-CI-LOGS/'"$LOG_FOLDER_NAME"''

sshpass -p $LOG_SERVER_PASSWORD scp $LOG_FOLDER_NAME/stack.sh.log.*.summary.* $LOG_FOLDER_NAME/tempest.log $LOG_FOLDER_NAME/lbaas_v2_tempest_tests.log $LOG_FOLDER_NAME/lbaas_v1_tempest_tests.log $LOG_SERVER_USER@$LOG_SERVER_IP:/data/RADWARE-CI-LOGS/$LOG_FOLDER_NAME/.

