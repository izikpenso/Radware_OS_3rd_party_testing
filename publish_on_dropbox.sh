#!/bin/bash

#source the jobrc file that contains all the needed environment variables for script to run. 
source jobrc

 ~/bin/dropbox.py start

PATCH_NAME=$(echo $GERRIT_REFSPEC | sed -e 's/\//_/g')

tar cvzf $PATCH_NAME.tar.gz tempest.log test_load_balancer_log.xml

cp $PATCH_NAME.tar.gz ~/Dropbox/Public/.
