#!/bin/bash

#source the jobrc file that contains all the needed environment variables for script to run. 
source jobrc

 ~/bin/dropbox.py start

cp tempest.log ~/Dropbox/Public/tempest"$GERRIT_REFSPEC".log
cp test_load_balancer_log"$GERRIT_REFSPEC".xml ~/Dropbox/Public/.
