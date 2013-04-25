#!/bin/bash

#----------Preparation---------
#install variables
export casper_tag="1.0.0-RC4"
export casper_git="git://github.com/n1k0/casperjs.git"

export cobbler_tag="release24"
export cobbler_git="git://github.com/cobbler/cobbler.git"

export requirements_eggs_path="../requirements-eggs.txt"
export requirements_deb_path="../requirements-deb.txt"
export nailgun_path="$(pwd)/../nailgun"
export nailgun_log="/var/log/nailgun.log"

export linux_distr=` head -n1 /etc/issue | awk '{print $1}' `

#-----Installation-------
#Install packages
echo " ---- Imstall packages ---- "

case ${linux_distr} in
Ubuntu*)
	xargs -t -a ${requirements_deb_path} sudo apt-get install -y
;;
*)
echo "No package list available for non ubuntu linux"
exit
esac

echo " ---- Imstall python dependencies ---- "
sudo pip install -r ${requirements_eggs_path}

# ----- Setup postrges user ----- 
echo "Drop nailgun user if exists"
sudo -u postgres dropuser nailgun
echo "Drop nailgun database if exists"
sudo -u postgres dropdb nailgun
echo "Create new user nailgun"
echo "please type 'nailgun' as a password for new user"
sudo -u postgres createuser -D -A -P -r nailgun
echo "Create database nailgun"
sudo -u postgres createdb nailgun

# ----- Install casper js ----- 
echo " ----- Install casper js ----- "
cd ~
rm -rf casperjs
git clone ${casper_git}
cd casperjs
git checkout tags/${casper_tag}
export current_installation="$(pwd)/bin/casperjs"
export to_installation="/usr/local/bin/casperjs"
echo "generate symlink from ${current_installation} to ${to_installation}"
sudo ln -sfv ${current_installation} ${to_installation}

# ----- Install cobbler ----- 
echo " ----- Install cobbler ----- "
cd ~
mkdir source -p
cd source
rm -rf cobbler
git clone ${cobbler_git}
cd cobbler
git checkout ${cobbler_tag}
sudo make install

# ----- SyncDB ----- 
cd ${nailgun_path}
./manage.py syncdb
echo "It loads base metainfo about OpenStack release and its settings"
./manage.py loaddata nailgun/fixtures/openstack_folsom.json   
echo "Loads fake nodes"
./manage.py loaddata nailgun/fixtures/sample_environment.json
echo "Loads notification that master node is installed"
./manage.py loaddata nailgun/fixtures/start_notification.json

# ----- Create log file ----- 
echo "Create log file if does not exist and add permissions to write"
touch ${nailgun_log}
chmod a+w ${nailgun_log}