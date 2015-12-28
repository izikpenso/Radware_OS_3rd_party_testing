#!/usr/bin/env bash

set -x

source ~/devstack/jobrc


if [ -z "$HA_PAIR_FLAG" ]; then
        HA_PAIR_FLAG=False
fi


#sed -i "s/service_provider = LOADBALANCER:[Rr]adware/# service_provider = LOADBALANCER:Radware/g" /etc/neutron/neutron_lbaas.conf
#sed -i "s/# service_provider = LOADBALANCERV2:radwarev2/service_provider = LOADBALANCERV2:radwarev2/g" /etc/neutron/neutron_lbaas.conf
sed -i '/[service_providers]/ a\service_provider = LOADBALANCERV2:radwarev2:neutron_lbaas.drivers.radware.v2_driver.RadwareLBaaSV2Driver:default' /etc/neutron/neutron_lbaas.conf
sed -i "s/service_plugins = neutron.services.l3_router.l3_router_plugin.L3RouterPlugin,neutron_lbaas.services.loadbalancer.plugin.LoadBalancerPlugin/service_plugins = neutron.services.l3_router.l3_router_plugin.L3RouterPlugin,neutron_lbaas.services.loadbalancer.plugin.LoadBalancerPluginv2/g" /etc/neutron/neutron.conf


sudo echo '[radwarev2]' | sudo tee -a /etc/neutron/neutron.conf
echo "vdirect_address=$VDIRECT_IP" | sudo tee -a /etc/neutron/neutron.conf
echo "service_ha_pair=$HA_PAIR_FLAG" | sudo tee -a /etc/neutron/neutron.conf

# stop neutron
PID=`ps -ef | grep neutron-server | grep python | awk '{ print $2 }'` || true
echo 'Killing neutron ...PID:' $PID

# kill it
kill $PID || true

sleep 2

# start neutron
echo 'Restarting...'
python /usr/local/bin/neutron-server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini > ~/q_err.txt 2> ~/q_log.txt &


sleep 2

NEW_PID=`ps -ef | grep neutron-server | grep python| awk '{ print $2 }'`
echo 'New PID: ' $NEW_PID
