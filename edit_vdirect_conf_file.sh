#!/bin/bash

# This script rus on the new VM machine locally. after it's been conpied there

source ~/devstack/jobrc

CFG_FILE=$1

echo "export CFG_FILE=$CFG_FILE" | sudo tee -a ~/devstack/jobrc


ALTEON_IMAGE_NAME=$(echo $ALTEON_IMAGE_FILE | rev | cut -d. -f2- | rev)

ALTEON_VERSION=$(echo $ALTEON_IMAGE_NAME | cut -d "-" --complement -s -f1)

sed -i "s/dummy_version/${ALTEON_VERSION}/g" $CFG_FILE

sed -i "s/devstack_dummy_ip/${VM_IP}/g" $CFG_FILE

sed -i "s/network_management_dummy_id/${NETWORK_MANAGEMENT_ID}/g" $CFG_FILE

sed -i "s/network_server_dummy_id/${HA_NETWORK_ID}/g" $CFG_FILE

sed -i "s/network_client_dummy_id/${SERVER_NETWORK_ID}/g" $CFG_FILE

sed -i "s/vdirect_dummy_ip/${VDIRECT_IP}/g" $CFG_FILE


