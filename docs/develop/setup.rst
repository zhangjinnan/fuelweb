Setting up development environment
==================================

.. contents:: :local:

All our development is commonly done on Ubuntu 12. Follow the steps to prepare environment:

Install and configure Postgres DB

.. code-block:: bash

	sudo apt-get install postgresql
	sudo -u postgres createuser -D -A -P nailgun (enter password nailgun)
	sudo -u postgres createdb nailgun
	sudo apt-get install postgresql-server-dev-9.1 python-dev
	sudo pip install psycopg2

Install python dependencies:

.. code-block:: bash
	
	sudo pip install -r requirements-eggs.txt


NOTE: Cobbler could not be installer from PyPI now. Need to install is manually from sources or OS package. Installing from sources

.. code-block:: bash
	
	sudo pip install PyYAML
	git clone git://github.com/cobbler/cobbler.git
	cd cobbler
	git checkout release24
	sudo make install


SyncDB

.. code-block:: bash

	cd nailgun
	./manage.py syncdb
	./manage.py loaddata nailgun/fixtures/openstack_folsom.json   # It loads base metainfo about OpenStack release and its settings
	./manage.py loaddata nailgun/fixtures/sample_environment.json  # Loads fake nodes
	./manage.py loaddata nailgun/fixtures/start_notification.json  # Loads notification that master node is installed

Start application in "fake" mode, when no real calls to orchestrator are performed

.. code-block:: bash

	python manage.py run -p 8000 --fake-tasks | grep --line-buffered -v -e HTTP -e '^$' >> /var/log/nailgun.log 2>&1 &
 