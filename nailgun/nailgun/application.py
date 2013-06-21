#-*- coding: utf-8 -*-

from flask import Flask

from nailgun.settings import settings
from nailgun.logger import logger


def build_app():
    app = Flask("nailgun")
    return app


def load_apps():
    apps = []
    for app_name in settings.APPS:
        logger.info("App '{0}' found".format(app_name))
        app = __import__(
            "nailgun.%s" % app_name,
            fromlist=["nailgun"]
        )
        apps.append(app)
    return apps


application = build_app()
apps = load_apps()
