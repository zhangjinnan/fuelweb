node default {
  class { "rpmcache":
    releasever => "6Server",
    pkgdir => "/var/www/nailgun/rhel/6.4/nailgun/x86_64",
    rh_username => "username",
    rh_password => "password",
    rh_channels => "rhel-6-server-rpms rhel-6-server-optional-rpms rhel-lb-for-rhel-6-server-rpms rhel-rs-for-rhel-6-server-rpms rhel-ha-for-rhel-6-server-rpms rhel-server-ost-6-folsom-rpms",
  }
}
