# -*- coding: utf-8 -*-
import json

from nailgun.api.models import Network, NetworkGroup
from nailgun.test.base import BaseHandlers
from nailgun.test.base import reverse
from nailgun.settings import settings
from nailgun.api.models import Cluster


class TestClusterSaveNetworksHandler(BaseHandlers):
    def setUp(self):
        super(TestClusterSaveNetworksHandler, self).setUp()
        self.cluster = self.env.create_cluster(api=True)

    def put(self, cluster_id, data):
        url = reverse(
            'ClusterSaveNetworksHandler',
            kwargs={'cluster_id': cluster_id})
        result = self.app.put(
            url,
            json.dumps(data),
            headers=self.default_headers)
        return result

    def test_change_net_manager(self):
        new_net_manager = {'net_manager': 'VlanManager'}
        resp = self.put(self.cluster['id'], new_net_manager)

        cluster_after_update = self.db.query(Cluster).get(self.cluster['id'])
        self.assertEquals(
            cluster_after_update.net_manager,
            new_net_manager['net_manager'])

    def test_do_not_update_net_manager_if_validation_is_failed(self):
        network = self.db.query(NetworkGroup).first()
        new_net_manager = {'net_manager': 'VlanManager',
                           'networks': [{'id': 500, 'vlan_start': 500}]}
        resp = self.put(self.cluster['id'], new_net_manager)

        cluster_after_update = self.db.query(Cluster).get(self.cluster['id'])
        self.assertNotEquals(
            cluster_after_update.net_manager,
            new_net_manager['net_manager'])

    def test_network_group_update_changes_network(self):
        network = self.db.query(NetworkGroup).first()
        self.assertIsNotNone(network)
        new_vlan_id = 500  # non-used vlan id
        new_nets = {'networks': [{
            'id': network.id,
            'vlan_start': new_vlan_id}]}

        resp = self.put(self.cluster['id'], new_nets)
        self.assertEquals(200, resp.status)
        self.db.refresh(network)
        self.assertEquals(len(network.networks), 1)
        self.assertEquals(network.networks[0].vlan_id, 500)

    def test_update_networks_and_net_manager(self):
        network = self.db.query(NetworkGroup).first()
        new_vlan_id = 500  # non-used vlan id
        new_net = {'net_manager': 'VlanManager',
                   'networks': [{'id': network.id, 'vlan_start': new_vlan_id}]}
        resp = self.put(self.cluster['id'], new_net)

        cluster_after_update = self.db.query(Cluster).get(self.cluster['id'])
        self.db.refresh(network)
        self.assertEquals(
            cluster_after_update.net_manager,
            new_net['net_manager'])
        self.assertEquals(network.networks[0].vlan_id, new_vlan_id)

    def test_networks_update_fails_with_wrong_net_id(self):
        new_nets = {'networks': [{
            'id': 500,
            'vlan_start': 500}]}

        resp = self.put(self.cluster['id'], new_nets)
        self.assertEquals(200, resp.status)
        task = json.loads(resp.body)
        self.assertEquals(
            task['message'],
            'Invalid network ID: 500'
        )
