Name:      nailgun-net-check
Summary:   Network checking package for CentOS6.2
Version:   0.0.2
Release:   1
License:   GPLv2
Source0:   http://pypcap.googlecode.com/files/pypcap-%{pypcapver}.tar.gz
Source1:   http://www.tcpdump.org/release/libpcap-%{libpcapver}.tar.gz
Source2:   net_probe.py
Patch1:    pypcap.diff
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-build
URL:       http://github.com/Mirantis
Requires:  vconfig
Requires:  scapy
Requires:  python-argparse
BuildRequires: byacc

%define pypcapver 1.1
%define libpcapver 1.3.0

%description
This is a network tool that helps to verify networks connectivity
between hosts in network.

%global _default_patch_fuzz 4

%prep
rm -rf %{name}-%{version}
mkdir %{name}-%{version}
tar zxf %{_sourcedir}/pypcap-%{pypcapver}.tar.gz
tar zxf %{_sourcedir}/libpcap-%{libpcapver}.tar.gz
%patch1 -p1

%build
cd libpcap-%{libpcapver}
%configure
make
cd ../pypcap-%{pypcapver}
make all

%install
mkdir -p %{buildroot}/usr/bin
install -m 0755 %{SOURCE2} %{buildroot}/usr/bin
cd pypcap-%{pypcapver}
python setup.py install --root=%{buildroot}
#if [ -d %{buildroot}/usr/lib/python ];then
#  mv %{buildroot}/usr/lib/python %{buildroot}/usr/lib64/python
#fi
%files
%defattr(0755,root,root,-)
/usr/bin/net_probe.py
%defattr(0644,root,root,-)
/usr/lib64/python2.6/site-packages/pcap*

%clean
rm -rf %{buildroot}
