#!/bin/bash

# This script was should work only in Ubuntu machines.

usage(){
        echo "Usage: $0 filename ; the file should contain all the necessary environment variables for the script to run. see jobrc_sample file"
        exit 1
}

if (( $# != 1 )); then
   usage
fi

#source the resource file that contains all the needed environment variables for script to run.
echo "will use the following resource file - $1"
source $1


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

# copying radware files to Devstack VM 

sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'mkdir ~/scripts;'



if [ -z "$LOCAL_SH_FILE" ]; then
        LOCAL_SH_FILE='local.sh'
fi

sshpass -p $VM_SSH_PASSWORD scp $LOCAL_SH_FILE $VM_SSH_USER@$VM_IP:~/devstack/.

sshpass -p $VM_SSH_PASSWORD scp edit_vdirect_conf_file.sh $VM_SSH_USER@$VM_IP:~/scripts/.

sshpass -p $VM_SSH_PASSWORD scp restart_neutron_server_with_radware_lbaas.sh $VM_SSH_USER@$VM_IP:~/scripts/.

sshpass -p $VM_SSH_PASSWORD scp -r vdirect_cfg/  $VM_SSH_USER@$VM_IP:~/scripts/

sshpass -p $VM_SSH_PASSWORD scp -r bash_scripts/  $VM_SSH_USER@$VM_IP:~/scripts/

# echoing Alteon and vDirect imagei file name just for fun.
echo "Using Alteon image: $ALTEON_IMAGE_FILE"

echo "Using vDirect image file: $VDIRECT_IMAGE_FILE"

#Downloading Alteon and vDirect images to devstack machine from IMAGE_SERVER_IP
sshpass -p $VM_SSH_PASSWORD ssh -o "StrictHostKeyChecking no" $VM_SSH_USER@$VM_IP 'mkdir ~/images; cd ~/images/; wget -nv -t 3 http://'"$IMAGE_SERVER_IP"'/'"$ALTEON_IMAGE_FILE"'; wget -nv -t 3 http://'"$IMAGE_SERVER_IP"'/'"$VDIRECT_IMAGE_FILE"''



