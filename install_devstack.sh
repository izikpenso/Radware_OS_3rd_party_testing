#!/bin/bash

#source the jobrc file that contains all the needed environment variables for script to run.
source jobrc

#git Clone devstack to new VM
sshpass -p radware ssh -o "StrictHostKeyChecking no" ubuntu@$VM_IP 'git clone https://github.com/openstack-dev/devstack.git; mkdir ~/scripts'

#Copying localrc, local.sh, and vdirect_cfg python scripts to devstack machine
sshpass -p 'radware' scp localrc ubuntu@$VM_IP:~/devstack/.

sshpass -p 'radware' scp local.sh ubuntu@$VM_IP:~/devstack/.

sshpass -p 'radware' scp jobrc ubuntu@$VM_IP:~/devstack/.

sshpass -p 'radware' scp edit_vdirect_conf_file.sh ubuntu@$VM_IP:~/scripts/.

sshpass -p 'radware' scp -r vdirect_cfg/  ubuntu@$VM_IP:~/scripts/

#Editing localrc: Adding HOST_IP,FLAT_INTERFACE ,NEUTRON_BRANCH parameters
sshpass -p radware ssh -o "StrictHostKeyChecking no" ubuntu@$VM_IP 'echo 'HOST_IP="$VM_IP"' >> ~/devstack/localrc; echo FLAT_INTERFACE=eth0 >> ~/devstack/localrc ; echo 'NEUTRON_BRANCH="$GERRIT_REFSPEC"' >> ~/devstack/localrc; chmod a+x ~/devstack/local.sh; chmod a+x ~/scripts/edit_vdirect_conf_file.sh'

echo "Alteon image = $ALTEON_IMAGE"

echo " vDirect image = $VDIRECT_IMAGE"
#Copying Alteon and vDirect images to devstack machine
sshpass -p radware ssh -o "StrictHostKeyChecking no" ubuntu@$VM_IP 'mkdir ~/images; cd ~/images/; wget -nv http://'"$IMAGE_SERVER_IP"'/'"$ALTEON_IMAGE"'; wget -nv http://'"$IMAGE_SERVER_IP"'/'"$VDIRECT_IMAGE"''
