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

sshpass -p $LOG_SERVER_PASSWORD scp -r $LOG_FOLDER_NAME $LOG_SERVER_USER@$LOG_SERVER_IP:/oslogs/RADWARE-CI-LOGS
