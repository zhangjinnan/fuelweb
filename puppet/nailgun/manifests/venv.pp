class nailgun::venv(
  $venv = $nailgun::params::venv,
  $venv_opts = $nailgun::params::venv_opts,
  $pip_opts = $nailgun::params::pip_opts,

  $package = $nailgun::params::package,
  $version = $nailgun::params::version,

  $databasefile = $nailgun::params::databasefile,
  $staticdir = $nailgun::params::staticdir,
  $templatedir = $nailgun::params::templatedir,

  $rabbitmq_naily_user = $nailgun::params::rabbitmq_naily_user,
  $rabbitmq_naily_password = $nailgun::params::rabbitmq_naily_password,

  $cobbler_url = $nailgun::params::cobbler_url,
  $cobbler_user = $nailgun::params::cobbler_user,
  $cobbler_password = $nailgun::params::cobbler_password,

  $mco_pskey = $nailgun::params::mco_pskey,
  $mco_stomphost = $nailgun::params::mco_stomphost,
  $mco_stompuser = $nailgun::params::mco_stompuser,
  $mco_stomppassword = $nailgun::params::mco_stomppassword,

  $puppet_master_hostname = $nailgun::params::puppet_master_hostname,
  $puppet_version = $nailgun::params::puppet_version,

  ) inherits nailgun::params {

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  nailgun::venv::venv { $venv:
    ensure => "present",
    venv => $venv,
    opts => $venv_opts,
    require => Package["python-virtualenv"],
    pip_opts => $pip_opts,
  }

  nailgun::venv::pip { "${venv}_${package}":
    package => "$package==$version",
    opts => $pip_opts,
    venv => $venv,
    require => [
                Nailgun::Venv::Venv[$venv],
                Package["python-devel"],
                Package["gcc"],
                Package["make"],
                ]
  }

  $databasefiledir = inline_template("<%= databasefile.match(%r!(.+)/.+!)[1] %>")
  $database_engine = "sqlite:///${databasefile}"

  file { "/etc/nailgun":
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => 0755,
  }

  $exclude_network = ipcalc_network_by_address_netmask($ipaddress, $netmask)
  $exclude_cidr = ipcalc_network_cidr_by_netmask($netmask)

  file { "/etc/nailgun/settings.yaml":
    content => template("nailgun/settings.yaml.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => File["/etc/nailgun"],
  }

  if ! defined(File[$databasefiledir]){
    file { $databasefiledir:
      ensure => directory,
      recurse => true,
    }
  }

  exec {"nailgun_syncdb":
    command => "${venv}/bin/nailgun_syncdb",
    creates => $databasefile,
    require => [
                File["/etc/nailgun/settings.yaml"],
                File[$databasefiledir],
                Nailgun::Venv::Pip["${venv}_${package}"],
                ],
  }

  exec {"nailgun_upload_fixtures":
    command => "${venv}/bin/nailgun_fixtures",
    require => Exec["nailgun_syncdb"],
  }

  }
