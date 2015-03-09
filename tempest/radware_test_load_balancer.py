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

from tempest.api.network import base
from tempest.common.utils import data_utils
from tempest.api.network import test_load_balancer


class RadwareLoadBalancerTest(test_load_balancer.LoadBalancerTestJSON):
    _interface = 'json'

    @classmethod
    def resource_cleanup(cls):
        # Clean up vips
        for vip in cls.vips:
            body = cls.client.show_pool(vip['pool_id'])
            pool = body['pool']
            cls.client.delete_vip(vip['id'])
            if (pool['provider'] == 'radware'):
                timer = 1000
                while timer > 0:
                    try:
                        cls.client.show_vip(vip['id'])
                        time.sleep(10)
                        timer = timer-10
                    except Exception:
                        break

        cls.vips = []

        import vdirect_cfg.lib.vdirect_client as VD
        config = VD.load_config('/home/radware/scripts/vdirect_cfg/test.cfg')
        rest_client = VD.vDirectClient(server=config['vdirect_ip'],
                                       user=config['vdirect_user'],
                                       password=config['vdirect_password'])
        for network in cls.networks:
            VD.delete_workflow(rest_client, 'l2_l3_' + network['id'])
            VD.delete_service(rest_client, 'srv_' + network['id'])
        super(RadwareLoadBalancerTest, cls).resource_cleanup()


