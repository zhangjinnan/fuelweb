# -*- coding: utf-8 -*-

import json

from flask import request

from nailgun.database import db
from nailgun.api.models import Task
from nailgun.api.handlers.base import JSONHandler, content_json
from nailgun.api.handlers.base import SingleHandler, CollectionHandler


class TaskHandler(SingleHandler):
    fields = (
        "id",
        "cluster",
        "uuid",
        "name",
        "result",
        "message",
        "status",
        "progress"
    )
    model = Task

    def delete(self, task_id):
        task = self.get_object_or_404(Task, task_id)
        if task.status not in ("ready", "error"):
            self.abort(400, "You cannot delete running task manually")
        for subtask in task.subtasks:
            db.session.delete(subtask)
        db.session.delete(task)
        db.session.commit()
        return self.abort(204)


class TaskCollectionHandler(CollectionHandler):

    single = TaskHandler

    @content_json
    def get(self):
        cluster_id = request.args.get("cluster_id")
        if cluster_id:
            tasks = Task.query.filter_by(
                cluster_id=cluster_id).all()
        else:
            tasks = Task.query.all()
        return self.render(tasks)
