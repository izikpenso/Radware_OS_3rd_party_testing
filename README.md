Radware openstack 3rd party Testing 

Radware_OS_3rd_party_testing contains a set of scripts and utilities to deploy openstack with radware lbaas driver and to test it.
The main motivation for this repository is to bring up devstack with radware lbaas driver and test it for fulfilling openstack Third Party Testing requirements. 

# vdirect_cfg
vdirect_cfg contains paython scripts and configuration files for configuring vDirect with all the relevant data before
creating an openstack lbaas vip.

Before using the vdirect_lbaas_cfg.py script you should edit the 'test.cfg' file with your environment info by editing the following parameters:
'host' - Change to your openstack/devstack IP.
'network.management', 'network.client', 'network.server' - Change to valid network IDs from your openstack environment.
'vdirect ip' - change to your vDirect IP.
'l2_l3_workflow_template_path' - Change to your path to the l2_l4 workflow template
'l4_workflow_template_path' - Change to your path to the l4 workflow template.
 
Usage:
python vdirect_lbaas_cfg.py test.cfg

