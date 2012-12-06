class puppetmaster::unicorn(
  $puppet_master_hostname,
  $puppet_stored_dbname,
  $puppet_stored_dbuser,
  $puppet_stored_dbpassword,
  $puppet_stored_dbsocket,

  $puppet_master_ports = "18140",
  ) {

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  ###############
  # PUPPET
  ###############

  exec { "puppet_cert" :
    command => "puppet cert generate ${puppet_master_hostname}",
    unless => "test -f /var/lib/puppet/ssl/certs/${puppet_master_hostname}.pem",
    require => Package["puppet-server"],
  }

  file { "/etc/puppet/unicorn.conf" :
    content => template("puppetmaster/unicorn.conf.erb"),
    mode => 0644,
    owner => "root",
    group => "root",
    require => [
                Package["puppet-server"],
                Package["unicorn"],
                ],
  }

  file { "/etc/puppet/config.ru":
    target => "/usr/share/puppet/ext/rack/files/config.ru",
    ensure => link,
    require => [
                Package["puppet-server"],
                Package["rack"],
                ],
  }

  #####################
  # GOD
  #####################

  file { "/etc/god" :
    ensure => directory,
    mode => 0755,
    owner => "root",
    group => "root",
  }

  file { "/etc/god/puppet.god" :
    content => template("puppetmaster/god.conf.erb"),
    mode => 0644,
    owner => "root",
    group => "root",
    notify => Service["god"],
    require => [
                Package["god"],
                File["/etc/god"],
                ],
  }

  file { "/etc/init.d/god" :
    content => template("puppetmaster/god.init.erb"),
    mode => 0755,
    owner => "root",
    group => "root",
    require => Package["god"],
  }

  service { "god":
    enable => true,
    ensure => "running",
    require => [
                Package["god"],
                File["/etc/init.d/god"],
                File["/etc/god/puppet.god"],
                Exec["puppet_cert"],
                File["/etc/puppet/unicorn.conf"],
                File["/etc/puppet/config.ru"],
                ],
  }

}
