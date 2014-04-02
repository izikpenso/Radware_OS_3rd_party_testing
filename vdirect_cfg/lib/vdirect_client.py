import base64
import httplib
import socket
import time
import logging
import json

logging.basicConfig(level=logging.DEBUG)
LOG = logging.getLogger(__name__)

RESP_STATUS = 0
RESP_REASON = 1
RESP_STR = 2
RESP_DATA = 3

TEMPLATE_HEADER = {'Content-Type':
                   'application/vnd.com.radware.vdirect.'
                   'template-parameters+json'}
PROVISION_HEADER = {'Content-Type':
                    'application/vnd.com.radware.'
                    'vdirect.status+json'}
CREATE_SERVICE_HEADER = {'Content-Type':
                         'application/vnd.com.radware.'
                         'vdirect.adc-service-specification+json'}
CONTAINER_HEADER = {'Content-Type':
                    'application/vnd.com.radware.vdirect.'
                    'container+json'}
VRRP_POOL_HEADER = {'Content-Type':
                    'application/vnd.com.radware.vdirect.vrrp-pool+json'}
VRRP_ID_HEADER = {'Content-Type':
                  'application/vnd.com.radware.vdirect.resource+json'}
NETWORK_HEADER = {'Content-Type':
                  'application/vnd.com.radware.vdirect.network+json'}
RESOURCE_POOL_HEADER = {'Content-Type':
                        'application/vnd.com.radware.vdirect.container-resource-pool+json'}
WORKFLOW_TEMPLATE_HEADER = {'Content-Type':
                            'application/x-zip-compressed'}
DELETE_HEADER = {'Content-Type':
                 'application/vnd.com.radware.vdirect.status+json'}



class vDirectClient:
    """REST server proxy to Radware vDirect."""

    def __init__(self,
                 server='localhost',
                 user=None,
                 password=None,
                 port=2189,
                 ssl=True,
                 timeout=5000,
                 base_uri=''):
        self.server = server
        self.port = port
        self.ssl = ssl
        self.base_uri = base_uri
        self.timeout = timeout
        if user and password:
            self.auth = base64.encodestring('%s:%s' % (user, password))
            self.auth = self.auth.replace('\n', '')
        else:
            raise r_exc.AuthenticationMissing()

        debug_params = {'server': self.server,
                        'port': self.port,
                        'ssl': self.ssl}
        LOG.debug('vDirectClient:init server=%(server)s, '
                  'port=%(port)d, '
                  'ssl=%(ssl)r', debug_params)

    def call(self, action, resource, data, headers, binary=False):
        if resource.startswith('http'):
            uri = resource
        else:
            uri = self.base_uri + resource
        if binary:
            body = data
        else:
            body = json.dumps(data)

        debug_data = 'binary' if binary else body
        debug_data = debug_data if debug_data else 'EMPTY'
        if not headers:
            headers = {'Authorization': 'Basic %s' % self.auth}
        else:
            headers['Authorization'] = 'Basic %s' % self.auth
        conn = None
        if self.ssl:
            conn = httplib.HTTPSConnection(
                self.server, self.port, timeout=self.timeout)
            if conn is None:
                LOG.error('vdirectRESTClient: Could not establish HTTPS '
                          'connection')
                return 0, None, None, None
        else:
            conn = httplib.HTTPConnection(
                self.server, self.port, timeout=self.timeout)
            if conn is None:
                LOG.error('vdirectRESTClient: Could not establish HTTP '
                          'connection')
                return 0, None, None, None

        try:
            conn.request(action, uri, body, headers)
            response = conn.getresponse()
            respstr = response.read()
            respdata = respstr
            try:
                respdata = json.loads(respstr)
            except ValueError:
                # response was not JSON, ignore the exception
                pass
            ret = (response.status, response.reason, respstr, respdata)
        except (socket.timeout, socket.error) as e:
            log_dict = {'action': action, 'e': e}
            LOG.error('vdirectRESTClient: %(action)s failure, %(e)r',
                      log_dict)
            ret = 0, None, None, None
        conn.close()
        return ret


def _rest_wrapper(response, success_codes=[202]):
    """Wrap a REST call and make sure a valid status is returned."""
    if response[RESP_STATUS] not in success_codes:
        params = {'status': response[RESP_STATUS],
                  'reason': response[RESP_REASON],
                  'description': response[RESP_STR],
                  'success_codes': success_codes}
        message = ('REST request failed with status %(status)s. '
                   'Reason: %(reason)s, Description: %(description)s. '
                   'Success status codes are %(success_codes)s') % params
        raise Exception(message)
    else:
        return response[RESP_DATA]


def _wait_for_resource_deletion (token, resource_name, rest_client):
    start_time = int(time.time())
    while True:
        result = rest_client.call('GET', token,
                                   None, None)
        completed = result[RESP_DATA]['complete']
        reason = result[RESP_REASON],
        description = result[RESP_STR]
 
        if completed:
            success = result[RESP_DATA]['success']
            if success:
                return
            else:
                if reason or description:
                    msg = 'Reason:%s. Description:%s' % (reason, description)
                else:
                    msg = "unknown"
                error_params = {"resource_name": resource_name, "msg": msg}
                LOG.error(_('Failed to delete %(resource_name)s. Reason: %(msg)s'),
                          error_params)
                raise Exception ()

        if int(time.time()) - start_time >= 120:
            raise exceptions.TimeoutException
        time.sleep(5)


def load_config(cfg_filename):
    LOG.debug('Reading Configuration file - ' + cfg_filename)
    cfg = json.load(open(cfg_filename))
    LOG.debug(cfg)
    return cfg


def upload_workflow_template(zipFilename, rest_client):
    LOG.debug('Uploading workflow template')
    with open(zipFilename, mode='rb') as file:
        fileContent = file.read()
    template_workflow_response = _rest_wrapper(rest_client.call('POST',
                                               '/api/workflowTemplate',
                                               fileContent,
                                               WORKFLOW_TEMPLATE_HEADER,
                                               binary=True), [201])
    return template_workflow_response

def delete_workflow(rest_client, workflow_name):
    LOG.debug('Deleteing workflow')
    res = rest_client.call('DELETE',
                           '/api/workflow/%s' % workflow_name,
                           DELETE_HEADER, None)
    if res[RESP_STATUS] != 404:
        _wait_for_resource_deletion(res[RESP_DATA]['uri'], workflow_name, rest_client)
    

def delete_service(rest_client, service_name):
    LOG.debug('Deleteing workflow')
    res = rest_client.call('DELETE',
                            '/api/service/%s' % service_name,
                            DELETE_HEADER, None)
    if res[RESP_STATUS] != 404:
        _wait_for_resource_deletion(res[RESP_DATA]['uri'], service_name, rest_client)

def create_openstack_container(rest_client, config):
    LOG.debug('Createing Openstack container on vDirect')
    return _rest_wrapper(rest_client.call('POST',
                                          '/api/container',
                                          config['container_params'],
                                          CONTAINER_HEADER), [201, 204])


def validate_openstack_container(rest_client, config):
    LOG.debug('Validating Openstack container on vDirect')
    return _rest_wrapper(rest_client.call('POST',
                                          '/api/container?validate=',
                                          config['container_params'],
                                          CONTAINER_HEADER), [204])


def create_vrrp_pool(rest_client, config):
    LOG.debug('Creating vrrp pool on vDirect')
    return _rest_wrapper(rest_client.call('POST',
                                          '/api/resource/vrrp',
                                          config['vrrp_pool_name'],
                                          VRRP_POOL_HEADER), [201])


def assign_vrrp_id_to_pool(rest_client, config):
    LOG.debug('Creating assign vrrp id to pool on vDirect')
    return _rest_wrapper(rest_client.call('POST',
                                          '/api/resource/vrrp/%(name)s' % config['vrrp_pool_name'],
                                          config['vrrp_id_params'],
                                          VRRP_ID_HEADER), [200])


def create_network_pool(rest_client, config):
    LOG.debug('Creating network pool on vDirect')
    return _rest_wrapper(rest_client.call('POST',
                                          '/api/resource/network',
                                          config['network_params'],
                                          NETWORK_HEADER), [201])


def create_resource_pool(rest_client, config):
    LOG.debug('Creating resource pool on vDirect')
    return _rest_wrapper(rest_client.call('POST',
                         '/api/resource/containerPool',
                         config['resource_pool_params'], RESOURCE_POOL_HEADER),
                         [201])

