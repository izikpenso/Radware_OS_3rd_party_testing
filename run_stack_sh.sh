#!/bin/bash

#source the jobrc file that contains all the needed environment variables for script to run. 
source jobrc

#Runnuig stack.sh
sshpass -p radware ssh -o "StrictHostKeyChecking no" ubuntu@$VM_IP '~/devstack/./stack.sh'

