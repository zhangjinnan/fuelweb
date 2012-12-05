class puppetmaster::unicorn(
  $puppet_master_hostname,
  $puppet_stored_dbname,
  $puppet_stored_dbuser,
  $puppet_stored_dbpassword,
  $puppet_stored_dbsocket,

  $puppet_master_ports = "18140",
  ) {

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  file { "/etc/puppet/unicorn.conf" :
    content => template("puppetmaster/unicorn.conf.erb"),
    mode => 0644,
    owner => "root",
    group => "root",
    require => Package["puppet-server"],
  }

  file { "/etc/god" :
    ensure => directory,
    mode => 0755,
    owner => "root",
    group => "root",
  } ->

  file { "/etc/god/puppet.god" :
    content => template("puppetmaster/god.conf.erb"),
    mode => 0644,
    owner => "root",
    group => "root",
  }

  file { "/etc/init.d/god" :
    content => template("puppetmaster/god.init.erb"),
    mode => 0755,
    owner => "root",
    group => "root",
  }

  service { "god":
    enable => true,
    ensure => "running",
    require => [
                Package["puppet-server"],
                Package["unicorn"],
                Package["god"],
                File["/etc/init.d/god"],
                File["/etc/god/puppet.god"],
                File["/etc/puppet/unicorn.conf"],
                ],
  }

}
