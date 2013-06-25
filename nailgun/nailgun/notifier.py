# -*- coding: utf-8 -*-

import json
import web
from datetime import datetime

from nailgun.database import db
from nailgun.logger import logger
from nailgun.api.models import Notification, Task


class Notifier(object):

    def notify(self, topic, message,
               cluster_id=None, node_id=None, task_uuid=None):
        if topic == 'discover' and node_id is None:
            raise Exception("No node id in discover notification")
        task = None
        if task_uuid:
            task = Task.query.filter_by(uuid=task_uuid).first()

        exist = None
        if node_id and task:
            exist = Notification.query.filter_by(
                node_id=node_id,
                message=message,
                task=task
            ).first()

        if not exist:
            notification = Notification()
            notification.topic = topic
            notification.message = message
            notification.cluster_id = cluster_id
            notification.node_id = node_id
            if task:
                notification.task_id = task.id
            notification.datetime = datetime.now()
            db.session.add(notification)
            db.session.commit()
            logger.info(
                "Notification: topic: %s message: %s" % (topic, message)
            )


notifier = Notifier()
