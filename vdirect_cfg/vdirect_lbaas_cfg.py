import base64
import httplib
import socket
import time
import logging
import json
import sys
import lib.vdirect_rest_client as VD

LOG = logging.getLogger(__name__)
FORMAT = "%(levelname)s %(filename)s %(asctime)s %(lineno)d %(message)s"
hdlr = logging.FileHandler('vdirect_lbaas_cfg.log')
formatter = logging.Formatter(FORMAT)
hdlr.setFormatter(formatter)
LOG.addHandler(hdlr)
LOG.setLevel(logging.DEBUG)


def load_config(cfg_filename):
    LOG.debug('Reading Configuration file - ' + cfg_filename)
    LOG.debug(json.load(open(cfg_filename)))
    return json.load(open(cfg_filename))


def setup_vdirect_opensack_cfg(config):
    LOG.debug('initialize vDirect rest client')
    rest_client = VD.vDirectRESTClient(server=config['vdirect_ip'],
                                       user=config['vdirect_user'],
                                       password=config['vdirect_password'])
    VD._create_openstack_container(rest_client, config)
    VD._validate_openstack_container(rest_client, config)
    VD._create_vrrp_pool(rest_client, config)
    VD._assign_vrrp_id_to_pool(rest_client, config)
    VD._create_network_pool(rest_client, config)
    VD. _create_resource_pool(rest_client, config)
    VD._upload_workflow_template(config['l2_l3_workflow_template_path'],
                                 rest_client)
    VD._upload_workflow_template(config['l4_workflow_template_path'],
                                 rest_client)


if __name__ == '__main__':
    if len(sys.argv) == 1:
        LOG.debug('No configuration file was selected,\
                  using default config file.')
        cfg = load_config('test.cfg')
    else:
        cfg = load_config(sys.argv[1])

setup_vdirect_opensack_cfg(cfg)

