# -*- coding: utf-8 -*-

from nailgun.api.urls import urls as api_urls
from nailgun.webui.urls import urls as webui_urls

urls = []
urls.extend(api_urls)
urls.extend(webui_urls)
