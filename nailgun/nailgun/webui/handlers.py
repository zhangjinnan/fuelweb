# -*- coding: utf-8 -*-

from flask import render_template

from nailgun.settings import settings
from nailgun.logger import logger
from flask.views import MethodView


class IndexHandler(MethodView):
    def get(self):
        return render_template("index.html")
