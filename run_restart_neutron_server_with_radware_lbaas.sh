#!/bin/bash

#source the jobrc file that contains all the needed environment variables for script to run. 
source jobrc

sshpass -p 'radware' scp restart_neutron_server_with_radware_lbaas.sh ubuntu@$VM_IP:~/scripts/.

sshpass -p radware ssh -o "StrictHostKeyChecking no" ubuntu@$VM_IP 'chmod a+x ~/scripts/restart_neutron_server_with_radware_lbaas.sh; ~/scripts/restart_neutron_server_with_radware_lbaas.sh'
