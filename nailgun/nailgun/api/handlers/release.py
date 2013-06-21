# -*- coding: utf-8 -*-

import json

import web

from nailgun.api.models import Distribution, Release
from nailgun.api.validators import DistributionValidator
from nailgun.api.validators import ReleaseValidator, RedHatAcountValidator
from nailgun.api.handlers.base import JSONHandler, content_json


class DistributionHandler(JSONHandler):
    fields = (
        "id",
        "name",
        "operating_system",
        "description"
    )
    model = Distribution

    @content_json
    def GET(self, distribution_id):
        distribution = self.get_object_or_404(Distribution, distribution_id)
        return self.render(distribution)

    @content_json
    def PUT(self, distribution_id):
        Distribution = self.get_object_or_404(Distribution, distribution_id)
        data = self.validator.validate_json(web.data())
        for key, value in data.iteritems():
            setattr(distribution, key, value)
        self.db.commit()
        return self.render(distribution)

    def DELETE(self, distribution_id):
        distribution = self.get_object_or_404(Distribution, distribution_id)
        self.db.delete(distribution)
        self.db.commit()
        raise web.webapi.HTTPError(
            status="204 No Content",
            data=""
        )


class DistributionCollectionHandler(JSONHandler):

    validator = DistributionValidator

    @content_json
    def GET(self):
        return map(
            DistributionHandler.render,
            self.db.query(Distribution).all()
        )

    @content_json
    def POST(self):
        data = self.validator.validate(web.data())
        distribution = Distribution()
        for key, value in data.iteritems():
            setattr(release, key, value)
        self.db.add(release)
        self.db.commit()
        raise web.webapi.created(json.dumps(
            DistributionHandler.render(distribution),
            indent=4
        ))


class ReleaseHandler(JSONHandler):
    fields = (
        "id",
        "name",
        "distribution",
        "description",
        "version"
    )
    model = Release
    validator = ReleaseValidator

    @content_json
    def GET(self, release_id):
        release = self.get_object_or_404(Release, release_id)
        return self.render(release)

    @content_json
    def PUT(self, release_id):
        release = self.get_object_or_404(Release, release_id)
        data = self.validator.validate_json(web.data())
        for key, value in data.iteritems():
            setattr(release, key, value)
        self.db.commit()
        return self.render(release)

    def DELETE(self, release_id):
        release = self.get_object_or_404(Release, release_id)
        self.db.delete(release)
        self.db.commit()
        raise web.webapi.HTTPError(
            status="204 No Content",
            data=""
        )


class ReleaseCollectionHandler(JSONHandler):

    validator = ReleaseValidator

    @content_json
    def GET(self):
        return map(
            ReleaseHandler.render,
            self.db.query(Release).all()
        )

    @content_json
    def POST(self):
        data = self.validator.validate(web.data())
        release = Release()
        for key, value in data.iteritems():
            setattr(release, key, value)
        self.db.add(release)
        self.db.commit()
        raise web.webapi.created(json.dumps(
            ReleaseHandler.render(release),
            indent=4
        ))


class RedHatAccountHandler(JSONHandler):

    validator = RedHatAcountValidator

    @content_json
    def POST(self):
        data = self.validator.validate(web.data())
        # TODO: activate and save status
        raise web.accepted(data=data)


class DownloadReleaseHandler(JSONHandler):
    fields = (
        "id",
        "name",
    )

    @content_json
    def PUT(self, release_id, version):
        task_manager = ReleaseDownloadTaskManager(cluster_id=cluster.id)
        try:
            task = task_manager.execute()
        except Exception as exc:
            logger.warn(u'DownloadReleaseHandler: error while execution'
                        ' deploy task: {0}'.format(exc.message))
            raise web.badrequest(exc.message)
        return TaskHandler.render(task)
