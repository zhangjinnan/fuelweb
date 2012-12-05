class nailgun(

  $rabbitmq_naily_user = $nailgun::params::rabbitmq_naily_user,
  $rabbitmq_naily_password = $nailgun::params::rabbitmq_naily_password,

  ) inherits nailgun::params {


  #######################
  # PUPPET FLOW
  #######################

  Anchor["nailgun-begin"] ->
  Class["nailgun::packages"] ->
  Anchor["nginx-clean"] ->
  Class["nailgun::iptables"] ->
  Class["nailgun::rsyslog"] ->

  # Preparing repository (gem, pip, rpm)
  Class["nailgun::nginx-repo"] ->
  Exec["start_nginx_repo"] ->

  # Installing nailgun components
  Class["nailgun::venv"] ->
  Class["nailgun::naily"] ->
  Class["nailgun::supervisor"] ->
  Class["nailgun::nginx-nailgun"] ->
  Anchor["nailgun-end"]

  # Installing cobbler
  Anchor["nailgun-begin"] ->
  Class["nailgun::cobbler"] ->
  Anchor["nailgun-end"]

  # Installing mcollective
  Anchor["nailgun-begin"] ->
  Class["nailgun::mcollective"] ->
  Anchor["nailgun-end"]

  # Installing mcollective
  Anchor["nailgun-begin"] ->
  Class["nailgun::puppetmaster"] ->
  Anchor["nailgun-end"]

  ##########################
  # PUPPET DECLARATIONS
  ##########################

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  anchor { "nailgun-begin" : }

  class { nailgun::packages : }

  # Removing all unnecessary nginx config files
  file { ["/etc/nginx/conf.d/default.conf",
          "/etc/nginx/conf.d/virtual.conf",
          "/etc/nginx/conf.d/ssl.conf"]:
    ensure => "absent",
    notify => Service["nginx"],
  } ->

  anchor { "nginx-clean" : }

  class { nailgun::iptables : }
  class { nailgun::rsyslog : }
  class { nailgun::nginx-repo :
    notify => Service["nginx"],
  }

  # This resource is required in order to make repository working before
  # installing gem packages. It is because you cannot use file system
  # directories as gem repositories.
  exec { "start_nginx_repo":
    command => "/etc/init.d/nginx start",
    unless => "/etc/init.d/nginx status | grep -q running",
  }

  class { nailgun::venv : }
  class { nailgun::naily : }
  class { nailgun::supervisor : }
  class { nailgun::nginx-nailgun :
    notify => Service["nginx"],
  }

  class { nailgun::cobbler :  }
  class { nailgun::mcollective : }
  class { nailgun::puppetmaster : }

  rabbitmq_user { $rabbitmq_naily_user:
    admin     => true,
    password  => $rabbitmq_naily_password,
    provider  => 'rabbitmqctl',
    # Class[rabbitmq::server] is declared inside mcollective::rabbitmq
    require   => Class['rabbitmq::server'],
  }

  rabbitmq_user_permissions { "${rabbitmq_naily_user}@/":
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
    # Class[rabbitmq::server] is declared inside mcollective::rabbitmq
    require              => Class['rabbitmq::server'],
  }

  class { nailgun::nginx-service : }

  # Generating rsa key. It will be used to get ssh access from
  # admin node to target nodes.
  nailgun::sshkeygen { "/root/.ssh/id_rsa":
    homedir => "/root",
    username => "root",
    groupname => "root",
    keytype => "rsa",
  } ->

  # The file /etc/cobbler/authorized_keys is used inside authorized_keys
  # snippet. This snippet just puts it on target node during OS installation.
  exec { "cp /root/.ssh/id_rsa.pub /etc/cobbler/authorized_keys":
    command => "cp /root/.ssh/id_rsa.pub /etc/cobbler/authorized_keys",
    creates => "/etc/cobbler/authorized_keys",
    require => Class["nailgun::cobbler"],
  }

  anchor { "nailgun-end" : }

}
