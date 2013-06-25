# -*- coding: utf-8 -*-

from nailgun.api.handlers.cluster import ClusterHandler
from nailgun.api.handlers.cluster import ClusterCollectionHandler
from nailgun.api.handlers.cluster import ClusterChangesHandler
from nailgun.api.handlers.cluster import ClusterAttributesHandler
from nailgun.api.handlers.cluster import ClusterAttributesDefaultsHandler

from nailgun.api.handlers.network_configuration \
    import NetworkConfigurationHandler
from nailgun.api.handlers.network_configuration \
    import NetworkConfigurationVerifyHandler

from nailgun.api.handlers.release import ReleaseHandler
from nailgun.api.handlers.release import ReleaseCollectionHandler

from nailgun.api.handlers.node import NodeHandler
from nailgun.api.handlers.node import NodeCollectionHandler
from nailgun.api.handlers.node import NodeAttributesHandler
from nailgun.api.handlers.node import NodeAttributesDefaultsHandler
from nailgun.api.handlers.node import NodeAttributesByNameHandler
from nailgun.api.handlers.node import NodeAttributesByNameDefaultsHandler
from nailgun.api.handlers.node import NodeNICsHandler
from nailgun.api.handlers.node import NodeNICsDefaultHandler
from nailgun.api.handlers.node import NodeCollectionNICsHandler
from nailgun.api.handlers.node import NodeCollectionNICsDefaultHandler
from nailgun.api.handlers.node import NodeNICsVerifyHandler

from nailgun.api.handlers.tasks import TaskHandler
from nailgun.api.handlers.tasks import TaskCollectionHandler

from nailgun.api.handlers.notifications import NotificationHandler
from nailgun.api.handlers.notifications import NotificationCollectionHandler

from nailgun.api.handlers.logs import LogEntryCollectionHandler
from nailgun.api.handlers.logs import LogPackageHandler
from nailgun.api.handlers.logs import LogSourceCollectionHandler
from nailgun.api.handlers.logs import LogSourceByNodeCollectionHandler

from nailgun.api.handlers.version import VersionHandler

urls = (
    (
        '/api/releases/',
        ReleaseCollectionHandler,
    ),
    (
        '/api/releases/<int:release_id>/',
        ReleaseHandler,
    ),
    (
        '/api/clusters/',
        ClusterCollectionHandler
    ),
    (
        '/api/clusters/<int:cluster_id>/',
        ClusterHandler
    ),
    (
        '/api/clusters/<int:cluster_id>/changes/',
        ClusterChangesHandler
    ),
    (
        '/api/clusters/<int:cluster_id>/attributes/',
        ClusterAttributesHandler
    ),
    (
        '/api/clusters/<int:cluster_id>/attributes/defaults/',
        ClusterAttributesDefaultsHandler
    ),
    (
        '/api/nodes/',
        NodeCollectionHandler
    ),
    (
        '/api/nodes/<int:node_id>/',
        NodeHandler
    ),
    (
        '/api/clusters/<int:cluster_id>/network_configuration/',
        NetworkConfigurationHandler
    ),
    (
        '/api/clusters/<int:cluster_id>/network_configuration/verify/',
        NetworkConfigurationVerifyHandler
    ),
    (
        '/api/nodes/<int:node_id>/attributes/',
        NodeAttributesHandler
    ),
    (
        '/api/nodes/<int:node_id>/attributes/defaults/',
        NodeAttributesDefaultsHandler
    ),
    (
        '/api/nodes/<int:node_id>/attributes/<attr_name>/',
        NodeAttributesByNameHandler
    ),
    (
        '/api/nodes/<int:node_id>/attributes/<attr_name>/defaults/',
        NodeAttributesByNameDefaultsHandler
    ),
    (
        '/api/nodes/interfaces/',
        NodeCollectionNICsHandler
    ),
    (
        '/api/nodes/interfaces/default_assignment',
        NodeCollectionNICsDefaultHandler
    ),
    (
        '/api/nodes/<int:node_id>/interfaces/',
        NodeNICsHandler
    ),
    (
        '/api/nodes/<int:node_id>/interfaces/default_assignment/',
        NodeNICsDefaultHandler
    ),
    (
        '/api/nodes/interfaces_verify/',
        NodeNICsVerifyHandler
    ),
    (
        '/api/tasks',
        TaskCollectionHandler
    ),
    (
        '/api/tasks/<int:task_id>',
        TaskHandler
    ),
    (
        '/api/notifications',
        NotificationCollectionHandler
    ),
    (
        '/api/notifications/<int:notification_id>',
        NotificationHandler
    ),
    (
        '/api/version',
        VersionHandler
    )
)
"""
    r'/logs/?$',
    'LogEntryCollectionHandler',
    r'/logs/package/?$',
    'LogPackageHandler',
    r'/logs/sources/?$',
    'LogSourceCollectionHandler',
    r'/logs/sources/nodes/(?P<node_id>\d+)/?$',
    'LogSourceByNodeCollectionHandler'
)

"""
