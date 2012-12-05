class nailgun::naily(
  $package = $nailgun::params::naily_package,
  $version = $nailgun::params::naily_version,

  $rabbitmq_naily_user = $nailgun::params::rabbitmq_naily_user,
  $rabbitmq_naily_password = $nailgun::params::rabbitmq_naily_password,

  $gem_source = $nailgun::params::gem_source,

  ) inherits nailgun::params {

  # here we use patched version of gem provider in order
  # to be able to set gem repository excplicitly
  package { $package :
    provider => "gem",
    ensure => $version,
    source => $gem_source,
    require => [
                Package["ruby-devel"],
                Package["gcc"],
                ]
  }

  file {"/etc/naily":
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => 0755,
  }

  file {"/etc/naily/nailyd.conf":
    content => template("nailgun/nailyd.conf.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => File["/etc/naily"],
  }

  file {"/var/log/naily":
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => 0755,
  }

}
