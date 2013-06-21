# -*- coding: utf-8 -*-
import json
from paste.fixture import TestApp

from nailgun.api.models import Release
from nailgun.test.base import BaseHandlers
from nailgun.test.base import reverse


class TestHandlers(BaseHandlers):
    def test_account_handler(self):
        resp = self.app.post(
            reverse('RedHatAccountHandler'),
            json.dumps({'license_type': 'rhsm',
                        'username': 'user',
                        'password': 'password'}),
            headers=self.default_headers)
        self.assertEquals(resp.status, 202)
