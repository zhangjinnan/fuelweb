class nailgun::mcollective(
  $mco_pskey = $nailgun::params::mco_pskey,
  $mco_stomphost = $nailgun::params::mco_stomphost,
  $mco_stompuser = $nailgun::params::mco_stompuser,
  $mco_stomppassword = $nailgun::params::mco_stomppassword,

  $rabbitmq_plugins_repo = "file:///var/www/nailgun/rabbitmq-plugins",

  ) inherits nailgun::params {

  class { "mcollective::rabbitmq":
    stompuser => $mco_stompuser,
    stomppassword => $mco_stomppassword,
    rabbitmq_plugins_repo => $rabbitmq_plugins_repo,
  }

  class { "mcollective::client":
    pskey => $mco_pskey,
    stompuser => $mco_stompuser,
    stomppassword => $mco_stomppassword,
    stomphost => $mco_stomphost,
    stompport => "61613"
  }

}
