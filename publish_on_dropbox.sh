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

if [ -z "$GERRIT_REFSPEC" ]; then
      echo "VM_NAME: $VM_NAME"
      LOG_FILE_NAME="${VM_NAME}_${BUILD_ID}.tar.gz"
else
      echo "GERRIT_REFSPEC is: $GERRIT_REFSPEC"
      LOG_FILE_NAME="${GERRIT_CHANGE_NUMBER}_${GERRIT_PATCHSET_NUMBER}_${BUILD_ID}.tar.gz"
fi

cp /var/lib/jenkins/jobs/$JOB_NAME/builds/$BUILD_NUMBER/log console.log

tar cvzf $LOG_FILE_NAME tempest.log test_load_balancer_log.xml screen-logs.tar.gz console.log jobrc_modified q_log.txt stack.sh.log local.conf vdirect_history.log

cp $LOG_FILE_NAME ~/Dropbox/Public/.

echo "Log file name is: $LOG_FILE_NAME"

echo "export LOG_FILE_NAME=$LOG_FILE_NAME" >> $1
