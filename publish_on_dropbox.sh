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

 ~/bin/dropbox.py start

if [ -z "$GERRIT_REFSPEC" ]
  then 
      echo "export LOG_FILE=$VM_NAME.tar.gz" >> $1
  else
      PATCH_NAME=$(echo $GERRIT_REFSPEC | sed -e 's/\//_/g')
      tar cvzf $PATCH_NAME.tar.gz tempest.log test_load_balancer_log.xml screen-logs.tar.gz
      cp $PATCH_NAME.tar.gz ~/Dropbox/Public/.
      echo "export LOG_FILE=$PATCH_NAME.tar.gz" >> $1
fi
