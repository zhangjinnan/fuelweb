#    Copyright 2013 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

import json

import web

from nailgun.api.handlers.base import JSONHandler, content_json
from nailgun.db import db
from nailgun.api.models import License
from nailgun.api.validators.license import LicenseValidator


class LicenseHandler(JSONHandler):
    fields = (
        'id',
        'owner'
    )

    validator = LicenseValidator

    @classmethod
    def render(cls, instance, fields=None):
        json_data = JSONHandler.render(instance, fields=cls.fields)
        json_data["created_at"] = instance.created_at.strftime("%H:%M:%S")
        json_data["expires_at"] = instance.expires_at.strftime("%H:%M:%S") \
            if instance.expires_at else ''

        return json_data

    @content_json
    def GET(self):
        licenses = db().query(License).all()
        return map(
            LicenseHandler.render,
            licenses)

    @content_json
    def POST(self):
        data = self.checked_data()
        license = License()
        license.owner = data['owner']
        db().add(license)
        db().commit()

        raise web.webapi.created(json.dumps(LicenseHandler.render(license),
                                            indent=4))
