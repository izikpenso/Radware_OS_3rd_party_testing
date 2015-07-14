# vim: tabstop=4 shiftwidth=4 softtabstop=4

# Copyright 2013 OpenStack Foundation
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

import time

from tempest_lib import exceptions
from neutron_lbaas.tests.tempest.v2.api import test_members


class RadwareMembersTest(test_members.MemberTestJSON):
    _interface = 'json'

    @classmethod
    def resource_cleanup(cls):
        for lb_id in cls._lbs_to_delete:
            try:
                lb = cls.load_balancers_client.get_load_balancer_status_tree(
                    lb_id).get('loadbalancer')
            except exceptions.NotFound:
                continue
            for listener in lb.get('listeners'):
                for pool in listener.get('pools'):
                    hm = pool.get('healthmonitor')
                    if hm:
                        cls._try_delete_resource(
                            cls.health_monitors_client.delete_health_monitor,
                            pool.get('healthmonitor').get('id'))
                        cls._wait_for_load_balancer_status(lb_id)
                    cls._try_delete_resource(cls.pools_client.delete_pool,
                                             pool.get('id'))
                    cls._wait_for_load_balancer_status(lb_id)
                    health_monitor = pool.get('healthmonitor')
                    if health_monitor:
                        cls._try_delete_resource(
                            cls.health_monitors_client.delete_health_monitor,
                            health_monitor.get('id'))
                    cls._wait_for_load_balancer_status(lb_id)
                cls._try_delete_resource(cls.listeners_client.delete_listener,
                                         listener.get('id'))
                cls._wait_for_load_balancer_status(lb_id)
            cls._try_delete_resource(
                cls.load_balancers_client.delete_load_balancer, lb_id)

            timer = 1000
            while timer > 0:
                try:
                    lb = cls.load_balancers_client.get_load_balancer_status_tree(
                        lb_id).get('loadbalancer')
                    time.sleep(10)
                    timer = timer-10
                except exceptions.NotFound as e:
                    print("EVG:radware waiting for loadbalancer finished:" + repr(e))
                    break

        import vdirect_cfg.lib.vdirect_client as VD
        config = VD.load_config('/home/radware/scripts/vdirect_cfg/test.cfg')
        rest_client = VD.vDirectClient(server=config['vdirect_ip'],
                                       user=config['vdirect_user'],
                                       password=config['vdirect_password'])
        VD.delete_service(rest_client, 'srv_' + cls.network['id'])
        super(RadwareMembersTest, cls).resource_cleanup()
