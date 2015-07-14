#!/bin/bash -ex

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

sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'sed -i "s/timeout = 300/timeout = 3000/g" /opt/stack/neutron-lbaas/neutron_lbaas/tests/tempest/v2/api/base.py'
#sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'sed -i "s/password = password/password = os/g" /opt/stack/neutron-lbaas/neutron_lbaas/tests/tempest/etc/tempest.conf'
#sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'cd /opt/stack/neutron-lbaas/neutron_lbaas/; echo "sudo python -m testtools.run neutron_lbaas.tests.tempest.v2.api.radware_test_members.RadwareMembersTest.test_add_member" > ~/lbaas_v2_tempest_tests.log; sudo python -m testtools.run neutron_lbaas.tests.tempest.v2.api.radware_test_members.RadwareMembersTest.test_add_member >> ~/lbaas_v2_tempest_tests.log 2>&1'
sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'cd /opt/stack/neutron-lbaas/neutron_lbaas/; echo "tox -e apiv2 neutron_lbaas.tests.tempest.v2.api.test_radware_members.RadwareMembersTest.test_add_member" > ~/lbaas_v2_tempest_tests.log; tox -e apiv2 neutron_lbaas.tests.tempest.v2.api.test_radware_members.RadwareMembersTest.test_add_member >> ~/lbaas_v2_tempest_tests.log 2>&1'



echo $?

