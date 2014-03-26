#!/bin/bash


# This script was should work only in Ubuntu machines.

usage(){
        echo "Usage: $0 filename ; the file should contain all the necessary environment variables for the script to run. see jobrc_sample file"
        exit 1
}

if (( $# != 1 )); then
   usage
fi


timestamp = $(date -d "today" +"%Y%m%d%H%M")

#source the jobrc file that contains all the needed environment variables for script to run. 
source $1

 ~/bin/dropbox.py start

if [ -z "$GERRIT_REFSPEC" ]; then
      
      echo "inside 1" 
      LOG_FILE_NAME=$VM_NAME_$timestamp.tar.gz
else
      echo "inside 2" 
      PATCH_NAME=$(echo $GERRIT_REFSPEC | sed -e 's/\//_/g')
      LOG_FILE_NAME=$PATCH_NAME_$timestamp.tar.gz
fi

tar cvzf $LOG_FILE_NAME.tar.gz tempest.log test_load_balancer_log.xml screen-logs.tar.gz
cp $LOG_FILE_NAME.tar.gz ~/Dropbox/Public/.

echo "Log file name is: $LOG_FILE_NAME"

echo "export LOG_FILE_NAME=$LOG_FILE_NAME.tar.gz" >> $1
