class nailgun::cobbler(
  $cobbler_user = $nailgun::params::cobbler_user,
  $cobbler_password = $nailgun::params::cobbler_password,

  $ks_repo = $nailgun::params::ks_repo,
  $ks_system_timezone = $nailgun::params::ks_system_timezone,
  $ks_encrypted_root_password = $nailgun::params::ks_encrypted_root_password,

  # those variables are needed to nailgun_agent snippet
  $gem_source = $nailgun::params::gem_source,
  $nailgun_api_url = $nailgun::params::nailgun_api_url,

  ) inherits nailgun::params {

  Anchor["nailgun-cobbler-begin"] ->
  Class[::cobbler] ->
  Anchor["nailgun-cobbler-end"]

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  anchor { "nailgun-cobbler-begin": }

  class { ::cobbler :
    server              => $ipaddress,

    domain_name         => $domain,
    name_server         => $ipaddress,
    next_server         => $ipaddress,

    dhcp_start_address  => ipcalc_network_nth_address($ipaddress, $netmask, "first"),
    dhcp_end_address    => ipcalc_network_nth_address($ipaddress, $netmask, "last"),
    dhcp_netmask        => $netmask,
    dhcp_gateway        => $ipaddress,
    dhcp_interface      => 'eth0',

    cobbler_user        => $cobbler_user,
    cobbler_password    => $cobbler_password,

    pxetimeout          => '50'
  }

  #######################
  # ADDITIONAL SNIPPETS
  #######################

  cobbler::snippets::cobbler_snippet {"send2syslog":
    source => "nailgun/cobbler/snippets/send2syslog.erb",
  }

  cobbler::snippets::cobbler_snippet {"kickstart_ntp":
    source => "nailgun/cobbler/snippets/kickstart_ntp.erb",
  }

  cobbler::snippets::cobbler_snippet {"ntp_to_masternode":
    source => "nailgun/cobbler/snippets/ntp_to_masternode.erb",
  }

  cobbler::snippets::cobbler_snippet {"pre_install_network_config":
    source => "nailgun/cobbler/snippets/pre_install_network_config.erb",
  }

  cobbler::snippets::cobbler_snippet {"nailgun_repo":
    source => "nailgun/cobbler/snippets/nailgun_repo.erb",
  }

  cobbler::snippets::cobbler_snippet {"ssh_disable_gssapi":
    source => "nailgun/cobbler/snippets/ssh_disable_gssapi.erb",
  }

  cobbler::snippets::cobbler_snippet {"authorized_keys":
    source => "nailgun/cobbler/snippets/authorized_keys.erb",
  }

  cobbler::snippets::cobbler_snippet {"nailgun_agent":
    source => "nailgun/cobbler/snippets/nailgun_agent.erb",
  }

  #############
  # CENTOS
  #############


  file { "/var/lib/cobbler/kickstarts/centos63-x86_64.ks":
    content => template("nailgun/cobbler/kickstart/centos.ks.erb"),
    owner => root,
    group => root,
    mode => 0644,
    require => Class[::cobbler],
  } ->

  cobbler_distro { "centos63-x86_64":
    kernel => "${repo_root}/centos/6.3/nailgun/x86_64/isolinux/vmlinuz",
    initrd => "${repo_root}/centos/6.3/nailgun/x86_64/isolinux/initrd.img",
    arch => "x86_64",
    breed => "redhat",
    osversion => "rhel6",
    ksmeta => "tree=http://@@server@@:8080/centos/6.3/nailgun/x86_64",
    require => Class[::cobbler],
  }

  cobbler_profile { "centos63-x86_64":
    kickstart => "/var/lib/cobbler/kickstarts/centos63-x86_64.ks",
    kopts => "",
    distro => "centos63-x86_64",
    ksmeta => "",
    menu => true,
    require => Cobbler_distro["centos63-x86_64"],
  }

  #############
  # BOOTSTRAP
  #############

  cobbler_distro { "bootstrap":
    kernel => "${repo_root}/bootstrap/linux",
    initrd => "${repo_root}/bootstrap/initramfs.img",
    arch => "x86_64",
    breed => "redhat",
    osversion => "rhel6",
    ksmeta => "",
    require => Class[::cobbler],
  }

  cobbler_profile { "bootstrap":
    distro => "bootstrap",
    menu => true,
    kickstart => "",
    kopts => "url=http://${ipaddress}:8000/api",
    ksmeta => "",
    require => Cobbler_distro["bootstrap"],
  }

  exec { "cobbler_system_add_default":
    command => "cobbler system add --name=default \
    --profile=bootstrap --netboot-enabled=True",
    onlyif => "test -z `cobbler system find --name=default`",
    require => Cobbler_profile["bootstrap"],
  }

  exec { "cobbler_system_edit_default":
    command => "cobbler system edit --name=default \
    --profile=bootstrap --netboot-enabled=True",
    onlyif => "test ! -z `cobbler system find --name=default`",
    require => Cobbler_profile["bootstrap"],
  }

  #################
  # FENCE SCRIPTS
  #################

  file { "/etc/cobbler/power/fence_ssh.template":
    content => template("nailgun/cobbler/fence_ssh.template.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => Class[::cobbler],
  }

  file { "/usr/sbin/fence_ssh":
    content => template("nailgun/cobbler/fence_ssh.erb"),
    owner => 'root',
    group => 'root',
    mode => 0755,
    require => Class[::cobbler],
  }

  Package<| title == "cman" |>
  Package<| title == "fence-agents"|>

  ##################
  # OTHER FILES
  ##################

  # ADDING send2syslog.py SCRIPT AND CORRESPONDING SNIPPET

  file { "/var/www/cobbler/aux/send2syslog.py":
    content => template("nailgun/cobbler/send2syslog.py"),
    owner => "root",
    group => "root",
    mode => 0644,
    require => Class[::cobbler],
  }

  anchor { "nailgun-cobbler-end": }

  }
