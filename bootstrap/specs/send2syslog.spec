Name:		send2syslog
Version:	0.1
Release:	1%{?dist}
Summary:	Simplify sending of messages to syslog system

Group:		System
License:	Apache
URL:		http://fuel.mirantis.com
Source0:	send2syslog.py

Requires:	python
Requires:	rsyslog


%description
Simplify sending of messages to syslog system

%install
mkdir -p $RPM_BUILD_ROOT/%{_bindir}
install -m 0755 %{SOURCE0} $RPM_BUILD_ROOT/%{_bindir}/send2syslog.py


%files
%{_bindir}/send2syslog.py

%doc



%changelog
* Thu Apr 25 2013 Mirantis Product <product@mirantis.com> 0.1-1
- Initial release

