class rpmcache ( releasever, pkgdir, 
rh_username, rh_password, rh_channels)  {

  file { '/etc/pki/product':
    ensure => directory,
  }
  file { '/etc/pki/product/69.pem':
    ensure => present,
    content => file('rpmcache/69.pem'),
    owner => 'root',
    group => 'root',
    mode => 0644,
  }

  file { '/etc/pki/product/191.pem':
    ensure => present,
    content => file('rpmcache/191.pem'),
    owner => 'root',
    group => 'root',
    mode => 0644,
  }

  file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release':
    ensure => present,
    content => file('rpmcache/RPM-GPG-KEY-redhat-release'),
    owner => 'root',
    group => 'root',
    mode => 0644,
  }

  file { '/etc/nailgun/required-rpms.txt':
    ensure => present,
    content => file('rpmcache/required-rpms.txt'),
    owner => 'root',
    group => 'root',
    mode => 0644,
  }

  file { '/usr/sbin/build_rpm_cache':
    content => template('rpmcache/build_rpm_cache.erb'),
    owner => 'root',
    group => 'root',
    mode => 0755,
  }

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  exec { 'build_rpm_cache':
    command => '/usr/sbin/build_rpm_cache',
    require => File['/usr/sbin/build_rpm_cache'],
    logoutput => true,
  }
}
