import base64
import httplib
import socket
import time
import logging
import json
import sys
import lib.vdirect_client as VD

LOG = logging.getLogger(__name__)
FORMAT = "%(levelname)s %(filename)s %(asctime)s %(lineno)d %(message)s"
hdlr = logging.FileHandler('vdirect_history.log')
formatter = logging.Formatter(FORMAT)
hdlr.setFormatter(formatter)
LOG.addHandler(hdlr)
LOG.setLevel(logging.DEBUG)


def get_vdirect_history(config):
    LOG.debug('initialize vDirect client')
    rest_client = VD.vDirectClient(server=config['vdirect_ip'],
                                   user=config['vdirect_user'],
                                   password=config['vdirect_password'])
    workflows = VD.list_workflows(rest_client)
    for workflow in workflows:
        LOG.debug('history of workflow - ' + workflow['name'])
        LOG.debug(VD.get_workflow_history(rest_client, workflow['name']))

    services = VD.list_services(rest_client)
    for service in services:
        LOG.debug('History of service - ' + service['name'])
        LOG.debug(VD.get_service_history(rest_client, service['name']))

if __name__ == '__main__':
    if len(sys.argv) == 1:
        LOG.debug('No configuration file was selected,\
                  using default config file.')
        cfg = VD.load_config('test.cfg')
    else:
        cfg = VD.load_config(sys.argv[1])

get_vdirect_history(cfg)
