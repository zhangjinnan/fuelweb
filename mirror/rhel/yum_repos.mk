define rhel_yum_conf
[main]
cachedir=$(BUILD_DIR)/mirror/rhel/cache
keepcache=0
debuglevel=6
logfile=$(BUILD_DIR)/mirror/rhel/yum.log
exclude=*.i686.rpm
exactarch=1
obsoletes=1
gpgcheck=0
plugins=1
pluginpath=$(BUILD_DIR)/mirror/rhel/etc/yum-plugins
pluginconfpath=$(BUILD_DIR)/mirror/rhel/etc/yum/pluginconf.d
reposdir=$(BUILD_DIR)/mirror/rhel/etc/yum.repos.d
endef

define rhel_yum_repo_puppetlabs
[puppetlabs]
name=Puppet Labs Packages
baseurl=http://yum.puppetlabs.com/el/$(CENTOS_MAJOR)/products/$(CENTOS_ARCH)/
enabled=1
gpgcheck=1
gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs
priority=1
endef

define rhel_yum_repo_proprietary
[proprietary]
name = RHEL $(CENTOS_RELEASE) - Proprietary
baseurl = $(MIRROR_RHEL)
gpgcheck = 0
enabled = 1
priority=1
endef

define rhel_yum_repo_rhel
[rhel-base-mirror]
name=RHEL mirror
baseurl=http://srv11-msk.msk.mirantis.net/rhel6/rhel-6-server-rpms
gpgcheck=0
enabled=1
priority=2

[rhel-os-mirror]
name=RHOS mirror
baseurl=http://srv11-msk.msk.mirantis.net/rhel6/rhel-server-ost-6-folsom-rpms/
gpgcheck=0
enabled=1
priority=2

[rhel-fuel-temporary]
name=RHOS mirror
baseurl=http://srv08-srt.srt.mirantis.net/rhel6/fuel-rpms/
gpgcheck=0
enabled=1
priority=2
endef
