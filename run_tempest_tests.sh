#!/bin/bash

#source the jobrc file that contains all the needed environment variables for script to run. 
source jobrc

#Runnuig tempest test and save log
sshpass -p radware ssh -o "StrictHostKeyChecking no" ubuntu@$VM_IP 'nosetests -s -v /opt/stack/tempest/tempest/api/network/test_load_balancer.py --with-xunit --xunit-file=test_load_balancer_log.xml'

