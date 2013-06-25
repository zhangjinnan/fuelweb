# -*- coding: utf-8 -*-

import os
import json

from flask.views import MethodView

from nailgun.settings import settings
from nailgun.api.handlers.base import JSONHandler, content_json


class VersionHandler(MethodView):

    @content_json
    def get(self):
        return {
            "sha": str(settings.COMMIT_SHA),
            "release": str(settings.PRODUCT_VERSION),
            "fuel_sha": str(settings.FUEL_COMMIT_SHA)
        }
