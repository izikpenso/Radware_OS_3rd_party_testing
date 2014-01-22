#!/bin/bash

#source the jobrc file that contains all the needed environment variables for script to run.
source jobrc

#delete devstack VM
sshpass -p radware ssh -o "StrictHostKeyChecking no" ubuntu@$VM_IP 'source jobrc; nova delete devstack-vm'"$BUILD_NUMBER"''
