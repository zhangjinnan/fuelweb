import subprocess
import tempfile
from time import sleep
import keystoneclient.v2_0
import glanceclient
import os
import re
from fuel_web.client import Client as FuelWebClient
from fuel_web.exceptions import ErrorStatusFuelWebException
from root import root
from helpers import SSHClient, load, retry


class Prepare(object):

    REGEXP_SERVICE_TOKEN = r'SERVICE_TOKEN=(.*?)\s'
    REGEXP_SERVICE_END_POINT = r'SERVICE_ENDPOINT=(.*?)\s'
    REGEXP_ID = r'\|\s+id\s+\|\s+(.*?)\s+\|'

    def __init__(self):
        self.cirros_image = 'http://srv08-srt.srt.mirantis.net/cirros-0.3.0-x86_64-disk.img'

        self.admin_ip = '10.20.0.2'
        self.compute_ip = '10.20.0.245'

        self.admin_name = 'admin'
        self.admin_password = 'admin'
        self.admin_tenant = 'admin'

        self.user_name = 'tempest1'
        self.user_password = 'secret'
        self.tenant_name = 'tenant1'

        self.alt_user_name = 'tempest2'
        self.alt_user_password = 'secret'
        self.alt_tenant_name = 'tenant2'

        self.glance_port = 9292

    def get_auth_url(self):
        return 'http://%s:5000/v2.0/' % self.compute_ip

    def _copy_ssh_files(self):
        ssh = SSHClient()

        ssh.connect_ssh(
            self.admin_ip,
            "root",
            "r00tme"
        )

        # Copy all private ssh keys from admin node to temp dir and save
        # path to these files to admin node metadata.
        keyfiles = ssh.execute('ls -1 /root/.ssh/*rsa')['stdout']
        keyfiles = [os.path.join('/root/.ssh', name.strip())
                    for name in keyfiles]
        local_keyfiles = []
        tempdir = tempfile.mkdtemp()
        for name in keyfiles:
            local_name = os.path.join(tempdir, os.path.basename(name))
            local_keyfiles.append(local_name)
            with open(local_name, 'w') as local_fd:
                fd = ssh.open(name)
                for line in fd:
                    local_fd.write(line)
                fd.close()
            os.chmod(local_name, 0600)
        ssh.disconnect()
        return local_keyfiles

    def setup_nodes(self):
        fuel_web = FuelWebClient(self.admin_ip, 8000)

        res = fuel_web.post_cluster({"name": "Name", "release": 1})
        if not res['status'] == 201:
            raise ErrorStatusFuelWebException()
        self.cluster = res['data']

        res = fuel_web.list_nodes()
        if not res['status'] == 200:
            raise ErrorStatusFuelWebException()
        self.node1, self.node2 = res['data']

        self.node1['role'] = 'controller'
        self.node1['cluster_id'] = self.cluster['id']
        self.node1['pending_addition'] = True

        self.node2['role'] = 'compute'
        self.node2['cluster_id'] = self.cluster['id']
        self.node2['pending_addition'] = True

        res = fuel_web.put_nodes([self.node1, self.node2])
        if not res['status'] == 200:
            raise ErrorStatusFuelWebException()

        res = fuel_web.put_changes(self.cluster['id'])
        if not res['status'] == 200:
            raise ErrorStatusFuelWebException()

        task = res['data']
        for x in range(0, 100):
            res = fuel_web.get_task(task['id'])
            if not res['status'] == 200:
                raise ErrorStatusFuelWebException()
            if res['data']['progress'] >= 100:
                break
            sleep(20)

    def prepare_slave(self):
        keyfiles = self._copy_ssh_files()

        ssh = SSHClient()
        ssh.connect_ssh(self.compute_ip, username='root', password='r00tme', key_filename=keyfiles)

        # source auth info
        res = ssh.execute('cat openrc')
        res_str = ''.join(res['stdout'])
        service_token = re.search(self.REGEXP_SERVICE_TOKEN, res_str).group(1)
        end_point = re.search(self.REGEXP_SERVICE_END_POINT, res_str).group(1)

        cmd_pattern = 'keystone --token %s --endpoint %s %s' % (service_token, end_point, '%s')

        # create tenants
        cmd = 'tenant-create --name %s' % self.tenant_name

        res = ssh.execute(cmd_pattern % cmd)
        self.tenant_id = re.search(self.REGEXP_ID, res['stdout'][5]).group(1)

        cmd = 'tenant-create --name %s' % self.alt_tenant_name
        res = ssh.execute(cmd_pattern % cmd)
        self.alt_tenant_id = re.search(self.REGEXP_ID, res['stdout'][5]).group(1)

        # create users
        cmd = 'user-create --name %s --pass %s --tenant-id %s' % \
              (self.user_name, self.user_password, self.tenant_id)
        res = ssh.execute(cmd_pattern % cmd)
        self.user_id = re.search(self.REGEXP_ID, res['stdout'][5]).group(1)

        cmd = 'user-create --name %s --pass %s --tenant-id %s' % \
              (self.alt_user_name, self.alt_user_password, self.alt_tenant_id)
        res = ssh.execute(cmd_pattern % cmd)
        self.alt_user_id = re.search(self.REGEXP_ID, res['stdout'][5]).group(1)

        ssh.disconnect()

    def prepare_tempest_folsom(self):
        image_ref, image_ref_alt = self.make_tempest_objects()
        self.tempest_write_config(
            self.tempest_config_folsom(
                image_ref=image_ref,
                image_ref_alt=image_ref_alt,
                path_to_private_key=root('fuel_test', 'config', 'ssh_keys',
                                         'openstack'),
                compute_db_uri='mysql://nova:nova@%s/nova' % self.compute_ip
            ))

    def tempest_config_folsom(self, image_ref, image_ref_alt,
                              path_to_private_key,
                              compute_db_uri='mysql://user:pass@localhost/nova'):
        sample = load(root('fuel_test', 'config', 'tempest.conf.folsom.sample'))
        config = sample % {
            'IDENTITY_USE_SSL': 'false',
            'IDENTITY_HOST': self.compute_ip,
            'IDENTITY_PORT': '5000',
            'IDENTITY_API_VERSION': 'v2.0',
            'IDENTITY_PATH': 'tokens',
            'IDENTITY_STRATEGY': 'keystone',
            'COMPUTE_ALLOW_TENANT_ISOLATION': 'true',
            'COMPUTE_ALLOW_TENANT_REUSE': 'true',
            'USERNAME': self.user_name,
            'PASSWORD': self.user_password,
            'TENANT_NAME': self.tenant_name,
            'ALT_USERNAME': self.alt_user_name,
            'ALT_PASSWORD': self.alt_user_password,
            'ALT_TENANT_NAME': self.alt_tenant_name,
            'IMAGE_ID': image_ref,
            'IMAGE_ID_ALT': image_ref_alt,
            'FLAVOR_REF': '1',
            'FLAVOR_REF_ALT': '2',
            'COMPUTE_BUILD_INTERVAL': '10',
            'COMPUTE_BUILD_TIMEOUT': '600',
            'RUN_SSH': 'false',
            'NETWORK_FOR_SSH': 'novanetwork',
            'COMPUTE_CATALOG_TYPE': 'compute',
            'COMPUTE_CREATE_IMAGE_ENABLED': 'true',
            'COMPUTE_RESIZE_AVAILABLE': 'true',
            'COMPUTE_CHANGE_PASSWORD_AVAILABLE': 'false',
            'COMPUTE_LOG_LEVEL': 'DEBUG',
            'COMPUTE_WHITEBOX_ENABLED': 'true',
            'COMPUTE_SOURCE_DIR': '/opt/stack/nova',
            'COMPUTE_CONFIG_PATH': '/etc/nova/nova.conf',
            'COMPUTE_BIN_DIR': '/usr/local/bin',
            'COMPUTE_PATH_TO_PRIVATE_KEY': path_to_private_key,
            'COMPUTE_DB_URI': compute_db_uri,
            'IMAGE_CATALOG_TYPE': 'image',
            'IMAGE_API_VERSION': '1',
            'IMAGE_HOST': self.compute_ip,
            'IMAGE_PORT': self.glance_port,
            'IMAGE_USERNAME': self.user_name,
            'IMAGE_PASSWORD': self.user_password,
            'IMAGE_TENANT_NAME': self.tenant_name,
            'COMPUTE_ADMIN_USERNAME': self.admin_name,
            'COMPUTE_ADMIN_PASSWORD': self.admin_password,
            'COMPUTE_ADMIN_TENANT_NAME': self.admin_tenant,
            'IDENTITY_ADMIN_USERNAME': self.admin_name,
            'IDENTITY_ADMIN_PASSWORD': self.admin_password,
            'IDENTITY_ADMIN_TENANT_NAME': self.admin_tenant,
            'VOLUME_CATALOG_TYPE': 'volume',
            'VOLUME_BUILD_INTERVAL': '10',
            'VOLUME_BUILD_TIMEOUT': '300',
            'NETWORK_CATALOG_TYPE': 'network',
            'NETWORK_API_VERSION': 'v2.0',
            }
        return config

    def tempest_write_config(self, config):
        with open(root('..', 'tempest.conf'), 'w') as f:
            f.write(config)

    def make_tempest_objects(self, ):
        image_ref, image_ref_alt = self.tempest_add_images()
        return image_ref, image_ref_alt

    def _get_identity_client(self):
        keystone = retry(10, keystoneclient.v2_0.client.Client,
                         username=self.admin_name,
                         password=self.admin_password,
                         tenant_name=self.admin_tenant,
                         auth_url=self.get_auth_url())
        return keystone

    def tempest_add_images(self):
        if not os.path.isfile('cirros-0.3.0-x86_64-disk.img'):
            subprocess.check_call(['wget', self.cirros_image])
        glance = self._get_image_client()
        return self.upload(glance, 'cirros_0.3.0',
                           'cirros-0.3.0-x86_64-disk.img'), \
               self.upload(glance, 'cirros_0.3.0',
                           'cirros-0.3.0-x86_64-disk.img')

    def _get_image_client(self):
        keystone = self._get_identity_client()
        endpoint = 'http://%s:%s' % (self.compute_ip, self.glance_port)
        return glanceclient.Client('1', endpoint=endpoint,
                                   token=keystone.auth_token)

    def upload(self, glance, name, path):
        image = glance.images.create(
            name=name,
            is_public=True,
            container_format='bare',
            disk_format='qcow2')
        image.update(data=open(path, 'rb'))
        return image.id


if __name__ == '__main__':
    prepare = Prepare()
    prepare.setup_nodes()
    prepare.prepare_slave()
    prepare.prepare_tempest_folsom()
