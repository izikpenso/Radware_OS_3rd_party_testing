#!/usr/bin/env bash

source ~/devstack/jobrc

sed -i "s/service_provider=LOADBALANCER:Haproxy/#service_provider=LOADBALANCER:Haproxy/g" /etc/neutron/neutron.conf
sed -i "s/# service_provider = LOADBALANCER:Radware/service_provider = LOADBALANCER:Radware/g" /etc/neutron/neutron.conf


sudo echo '[radware]' > /etc/neutron/services.conf

echo "vdirect_address=$VDIRECT_IP" | sudo tee -a /etc/neutron/services.conf


# stop neutron
PID=`ps -ef | grep neutron-server | grep python | awk '{ print $2 }'`
echo 'Killing neutron ...PID:' $PID

# kill it
kill $PID

sleep 2

# start neutron
echo 'Restarting...'
python /usr/local/bin/neutron-server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/services.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini > ~/q_err.txt 2> ~/q_log.txt &


sleep 2

NEW_PID=`ps -ef | grep neutron-server | grep python| awk '{ print $2 }'`
echo 'New PID: ' $NEW_PID

