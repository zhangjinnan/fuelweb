# -*- coding: utf-8 -*-
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

from nailgun.api.validators.base import BasicValidator
from nailgun.errors import errors


class LicenseValidator(BasicValidator):
    @classmethod
    def validate(cls, data):
        d = cls.validate_json(data)
        if not "license_code" in d:
            raise errors.InvalidData(
                "No License Code specified"
            )
        if not "owner" in d:
            raise errors.InvalidData(
                "No License Type specified"
            )

        try:
            license_code = int(d['license_code'])
        except ValueError:
            cls._invalid_license_error()
        if license_code == 0 or license_code % 23 != 0:
            cls._invalid_license_error()
        return d

    @classmethod
    def _invalid_license_error(cls):
        raise errors.InvalidData(
            "Invalid license code"
        )
