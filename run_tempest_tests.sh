#!/bin/bash

# This script was should work only in Ubuntu machines.

usage(){
        echo "Usage: $0 filename ; the file should contain all the necessary environment variables for the script to run. see jobrc_sample file"
        exit 1
}

if (( $# != 1 )); then
   usage
fi

# sshpass cmd sould be installed fo this script to work, cheking
if ! which sshpass > /dev/null; then
   echo -e "sshpass command not found! this package should be installed for this script will be able to run, would you like to install it now? (y/n) \c"
   read REPLY
   if [ "$REPLY" == "y" ]; then
      sudo apt-get --force-yes --yes install sshpass
   else
      echo "Script can't run if sshpass package isn't installed, exiting script!"
      exit 0
   fi
fi

#source the jobrc file that contains all the needed environment variables for script to run. 
source $1


#Editing tempest.conf with radware timeout

# Editing - build_timeout, build_interval, allow_tenant_isolation = False

sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'sed -i "s/#build_timeout = 300/build_timeout = 1200/g" /opt/stack/tempest/etc/tempest.conf; sed -i "s/#build_interval = 1/build_interval = 10/g" /opt/stack/tempest/etc/tempest.conf; sed -i "s/allow_tenant_isolation = True/allow_tenant_isolation = False/g" /opt/stack/tempest/etc/tempest.conf'

#Runnuig tempest test and save log
#sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'nosetests -s -v /opt/stack/tempest/tempest/api/network/radware_test_load_balancer.py --with-xunit --xunit-file=test_load_balancer_log.xml'

#Run test exclude tests that contains 'health' and 'filter'
#old cmd
#sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'nosetests -s -v /opt/stack/tempest/tempest/api/network/radware_test_load_balancer.py --exclude=health --exclude=filter --with-xunit --xunit-file=test_load_balancer_log.xml'

sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'sudo pip install tempest-lib; cd /opt/stack/tempest/;echo "sudo python -m testtools.run tempest.api.network.radware_test_load_balancer.RadwareLoadBalancerTest.test_create_update_delete_pool_vip" > ~/lbaas_v1_tempest_tests.log ;sudo python -m testtools.run tempest.api.network.radware_test_load_balancer.RadwareLoadBalancerTest.test_create_update_delete_pool_vip >> ~/lbaas_v1_tempest_tests.log'

