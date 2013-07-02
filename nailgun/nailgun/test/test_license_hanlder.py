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
from paste.fixture import TestApp

from nailgun.api.models import License
from nailgun.db import db
from nailgun.test.base import BaseHandlers
from nailgun.test.base import reverse


class TestHandlers(BaseHandlers):
    def _check_response_for_license(self, license, response_code, error=False):
        resp = self.app.post(
            reverse('LicenseHandler'),
            json.dumps({'license_code': license,
                        'owner': 'user'}),
            expect_errors=error,
            headers=self.default_headers)
        self.assertEquals(resp.status, response_code)

    def test_get_licenses(self):
        license = License()
        license.owner = 'some owner'
        db().add(license)
        db().commit()

        resp = self.app.get(
            reverse('LicenseHandler'),
            headers=self.default_headers)
        response = json.loads(resp.body)
        self.assertTrue(any(l['id'] == license.id for l in response))

    def test_valid_license_handler(self):
        valid_codes = [23, '23', 46, '46', '46 ']

        for valid_code in valid_codes:
            self._check_response_for_license(valid_code, 201)

    def test_invalid_license_handler(self):
        invalid_codes = [21, '21', '46d', '', '0', None]

        for invalid_code in invalid_codes:
            self._check_response_for_license(invalid_code, 400, True)
