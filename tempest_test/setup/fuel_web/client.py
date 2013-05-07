from httplib import HTTPConnection
import socket
import json


class Client:

    URL_RELEASES = '/api/releases'
    URL_NODES = '/api/nodes'
    URL_CLUSTERS = '/api/clusters%s'
    URL_TASKS = '/api/tasks%s'

    def __init__(self, host, port=None, strict=None, timeout=socket._GLOBAL_DEFAULT_TIMEOUT, source_address=None):
        self.host = host
        self.port = port
        self.strict = strict
        self.timeout = timeout
        self.source_address = source_address

    def _get_connection(self):
        return HTTPConnection(self.host, self.port, self.strict, self.timeout, self.source_address)

    def _request(self, method, url, body=None):
        conn = self._get_connection()
        conn.request(method, url, json.dumps(body))
        response = conn.getresponse()
        r = {'status': response.status, 'data': json.loads(response.read())}
        conn.close()
        return r

    def list_releases(self):
        return self._request('GET', self.URL_RELEASES)

    def list_nodes(self):
        return self._request('GET', self.URL_NODES)

    def put_nodes(self, nodes_list):
        nodes = [{'id': n['id'],
                  'role': n['role'],
                  'cluster_id': n['cluster_id'],
                  'pending_addition': n['pending_addition'],
                  'pending_deletion': n['pending_deletion']} for n in nodes_list]
        return self._request('PUT', self.URL_NODES, nodes)

    def put_changes(self, cluster_id):
        return self._request('PUT', self.URL_CLUSTERS % ('/' + str(cluster_id) + '/changes'))

    def list_clusters(self):
        return self._request('GET', self.URL_CLUSTERS % '')

    def get_cluster(self, cluster_id):
        return self._request('GET', self.URL_CLUSTERS % ('/' + str(cluster_id)))

    def post_cluster(self, cluster):
        return self._request('POST', self.URL_CLUSTERS % '', cluster)

    def delete_cluster(self, cluster_id):
        return self._request('DELETE', self.URL_CLUSTERS % ('/' + str(cluster_id)))

    def get_task(self, task_id):
        return self._request('GET', self.URL_TASKS % ('/' + str(task_id)))
