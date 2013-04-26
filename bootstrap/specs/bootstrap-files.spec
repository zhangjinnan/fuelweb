Name:		bootstrap-files
Version:	0.1
Release:	1%{?dist}
Summary:	Files used for Fuel bootstrap image

Group:		System
License:	Apache
URL:		http://fuel.mirantis.com
Source0:	%{name}-%{version}.tar.gz

Requires:	rsyslog
Requires:	mcollective
Requires:	openssh-server

%description
Basic configuration and tweaks for bootstrap image which is used to assist in OpenStack deployment

%prep
%setup -q
rm etc/localtime
mv etc/rc.d/rc.local etc/rc.d/rc.bootstrap
mv etc/ssh/sshd_config etc/ssh/sshd_config-bootstrap
mv etc/init/tty.conf etc/init/tty.conf-bootstrap
mv etc/mcollective/server.cfg etc/mcollective/server.cfg-bootstrap

%install
mkdir -p $RPM_BUILD_ROOT/etc/init
mkdir -p $RPM_BUILD_ROOT/etc/mcollective
mkdir -p $RPM_BUILD_ROOT/etc/rsyslog.d
mkdir -p $RPM_BUILD_ROOT/etc/rc.d
mkdir -p $RPM_BUILD_ROOT/etc/sysconfig
cp -rf * $RPM_BUILD_ROOT/.
chmod 0755 $RPM_BUILD_ROOT/etc/rc.d/rc.bootstrap

if ! grep bootstrap /etc/rc.local; then
 echo "/etc/rc.local/rc.bootstrap"
fi

%post
cp /etc/ssh/sshd_config-bootstrap /etc/ssh/sshd_config
cp /etc/init/tty.conf-bootstrap /etc/init/tty.conf
cp /etc/mcollective/server.cfg-bootstrap /etc/mcollective/server.cfg

%files
/etc/sysconfig/clock
/etc/sysconfig/network
/etc/rc.d/rc.bootstrap
/etc/ssh/sshd_config-bootstrap
/etc/nailgun_systemtype
/etc/init.d/setup-bootdev
/etc/rsyslog.d/50-default-template.conf
/etc/mcollective
/etc/mcollective/server.cfg-bootstrap
/etc/init/tty.conf-bootstrap
/usr/bin/fix-configs-on-startup

%doc



%changelog
* Thu Apr 25 2013 Mirantis Product <product@mirantis.com> 0.1.1
- Initial release
