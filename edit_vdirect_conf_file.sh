#!/bin/bash

# This script rus on the new VM machine locally. after it's been conpied there

source ~/devstack/jobrc


sed -i "s/devstack_dummy_ip/${VM_IP}/g" ~/scripts/vdirect_cfg/test.cfg

sed -i "s/network_management_dummy_id/${NETWORK_MANAGEMENT_ID}/g" ~/scripts/vdirect_cfg/test.cfg

sed -i "s/network_server_dummy_id/${HA_NETWORK_ID}/g" ~/scripts/vdirect_cfg/test.cfg

sed -i "s/network_client_dummy_id/${SERVER_NETWORK_ID}/g" ~/scripts/vdirect_cfg/test.cfg

sed -i "s/vdirect_dummy_ip/${VDIRECT_IP}/g" ~/scripts/vdirect_cfg/test.cfg


