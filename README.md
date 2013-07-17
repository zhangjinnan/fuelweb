FUEL汉化
========

fuelweb本地化的工作，目前初步完成web界面的汉化工作。

测试
====

安装配置Postgres:
-----------------

sudo apt-get install postgresql
 
sudo -u postgres createuser -D -A -P nailgun (enter password nailgun)

sudo -u postgres createdb nailgun

sudo apt-get install postgresql-server-dev-9.1 python-development 

sudo pip install psycopg2


安装依赖：
----------

sudo pip install -r requirements-eggs.txt

sudo pip install PyYAML

git clone git://github.com/cobbler/cobbler.git

cd cobbler

git checkout release24

sudo make install

初始化数据库：
--------------

cd nailgun

./manage.py syncdb

./manage.py loaddefault # It loads all basic fixtures listed in settings.yaml, such as admin_network, startup_notification and so on

./manage.py loaddata nailgun/fixtures/sample_environment.json  # Loads fake nodes

创建必要的文件：
----------------

sudo mkdir /var/log/nailgun

sudo chown -R `whoami`.`whoami` /var/log/nailgun

启动:
-----


`python manage.py run -p 8000 --fake-tasks | grep --line-buffered -v -e HTTP -e '^$' >> /var/log/nailgun.log 2>&1 &`

测试：
------

打开浏览器，访问8000端口测试.


中文汉化还有不完善的地方，请大家指出，谢谢！

ISO, other materials: http://fuel.mirantis.com/

User guide, development docs: http://fuel-docs.mirantis.com/
