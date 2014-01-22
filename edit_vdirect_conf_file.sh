#!/bin/bash


source ~/devstack/jobrc

sed -i "s/network_management_dummy_id/${NETWORK_MANAGEMENT_ID}/g" ~/scripts/vdirect_cfg/test.cfg

sed -i "s/network_server_dummy_id/${HA_NETWORK_ID}/g" ~/scripts/vdirect_cfg/test.cfg

sed -i "s/network_client_dummy_id/${SERVER_NETWORK_ID}/g" ~/scripts/vdirect_cfg/test.cfg

sed -i "s/vdirect_dummy_ip/${VDIRECT_IP}/g" ~/scripts/vdirect_cfg/test.cfg


