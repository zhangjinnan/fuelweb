# -*- coding: utf-8 -*-

import json

from flask import request

from nailgun.api.models import Release
from nailgun.api.validators import ReleaseValidator
from nailgun.api.handlers.base import content_json
from nailgun.api.handlers.base import SingleHandler, CollectionHandler


class ReleaseHandler(SingleHandler):
    fields = (
        "id",
        "name",
        "version",
        "description"
    )
    model = Release
    validator = ReleaseValidator

    @content_json
    def put(self, release_id):
        release = self.get_object_or_404(Release, release_id)
        data = self.validator.validate_json(request.data)
        for key, value in data.iteritems():
            setattr(release, key, value)
        db.session.commit()
        return self.render(release)

    def delete(self, release_id):
        release = self.get_object_or_404(Release, release_id)
        db.session.delete(release)
        db.session.commit()
        self.abort(204)


class ReleaseCollectionHandler(CollectionHandler):

    validator = ReleaseValidator
    single = ReleaseHandler

    @content_json
    def post(self):
        data = self.validator.validate(request.data)
        release = Release()
        for key, value in data.iteritems():
            setattr(release, key, value)
        db.session.add(release)
        db.session.commit()
        return self.render(release), 201
