class rpmcache ( $releasever, $pkgdir, 
$rh_username, $rh_password, $rh_base_channels, $rh_openstack_channel, 
$use_satellite = false, $sat_hostname = false, $activation_key = false)  {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}
  package { "yum-utils": 
    ensure => "latest"
  } ->
  package { "subscription-manager": 
    ensure => "latest"
  } ->

  file { '/etc/pki/product':
    ensure => directory,
  } ->
  file { '/etc/pki/product/69.pem':
    ensure => present,
    source => 'puppet:///modules/rpmcache/69.pem',
    owner => 'root',
    group => 'root',
    mode => 0644,
  } ->

  file { '/etc/pki/product/191.pem':
    ensure => present,
    source => 'puppet:///modules/rpmcache/191.pem',
    owner => 'root',
    group => 'root',
    mode => 0644,
  } ->

  file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release':
    ensure => present,
    source => 'puppet:///modules/rpmcache/RPM-GPG-KEY-redhat-release',
    owner => 'root',
    group => 'root',
    mode => 0644,
  } ->

  file { '/etc/nailgun/':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '0755'
  } ->
  file { '/etc/nailgun/required-rpms.txt':
    ensure => present,
    source => 'puppet:///modules/rpmcache/required-rpms.txt',
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => File['/etc/nailgun/']
  } ->

  file { '/usr/sbin/build_rpm_cache':
    content => template('rpmcache/build_rpm_cache.erb'),
    owner => 'root',
    group => 'root',
    mode => 0755,
  } ->


  exec { 'build_rpm_cache':
    command => '/usr/sbin/build_rpm_cache',
    require => File['/usr/sbin/build_rpm_cache'],
    logoutput => true,
    timeout => 0
  } ->
  cobbler_distro { "rhel-x86_64":
    kernel => "${repo_root}/rhel/isolinux/vmlinuz",
    initrd => "${repo_root}/rhel/isolinux/initrd.img",
    arch => "x86_64",
    breed => "redhat",
    osversion => "rhel6",
    ksmeta => "tree=http://@@server@@:8080/rhel",
  } ->

  cobbler_profile { "rhel-x86_64":
    kickstart => "/var/lib/cobbler/kickstarts/centos-x86_64.ks",
    kopts => "",
    distro => "rhel-x86_64",
    ksmeta => "redhat_register_user=${rh_username} redhat_register_password=${rh_password}",
    menu => true,
    require => Cobbler_distro["rhel-x86_64"],
  }

}
