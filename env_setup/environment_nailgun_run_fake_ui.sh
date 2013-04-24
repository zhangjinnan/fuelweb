#!/bin/bash

cd ../nailgun
python manage.py run -p 8000 --fake-tasks | grep --line-buffered -v -e HTTP -e '^$' >> /var/log/nailgun.log 2>&1 &