class nailgun::params {
  $venv = "/opt/nailgun"
  $venv_opts = "--system-site-packages"
  $pip_repo = "/var/www/nailgun/eggs"
  $pip_opts = "--no-index -f file://${pip_repo}"

  $package = "Nailgun"
  $version = "0.1.0"

  $databasefile = "/var/tmp/nailgun.sqlite"
  $staticdir = "/opt/nailgun/usr/share/nailgun/static"
  $templatedir = "/opt/nailgun/usr/share/nailgun/static"

  $cobbler_url = "http://localhost/cobbler_api"
  $cobbler_user = "cobbler"
  $cobbler_password = "cobbler"

  $mco_pskey = "unset"
  $mco_stomphost = $ipaddress
  $mco_stompuser = "mcollective"
  $mco_stomppassword = "marionette"

  $puppet_master_hostname = "${hostname}.${domain}"
  # THIS IS PUPPET PACKAGE VERSION ON TARGET NODE
  # THIS VARIABLES IS USED INSIDE KICKSTART FILE
  $puppet_version = "2.7.19"
  # THIS IS FULL PACKAGE VESRION OF PUPPET ON ADMIN NODE
  # THIS VARIABLE IS USED TO SET ensure PARAMETER
  # OF package RESOURCE DURING PUPPET MASTER DEPLOYMENT
  # $puppet_master_package_version = "2.7.19-1.el6"
  $puppet_master_package_version = "3.0.1-1.el6"

  $rabbitmq_naily_user = "naily"
  $rabbitmq_naily_password = "naily"

  $repo_root = "/var/www/nailgun"
  $gem_source = "http://$ipaddress:8080/gems/"
  $nailgun_api_url = "http://${ipaddress}:8000/api"

  $naily_package = "naily"
  $naily_version = "0.0.1"
  $nailgun_group = "nailgun"
  $nailgun_user = "nailgun"

  $ks_system_timezone = "America/Los_Angeles"
  # default password is 'r00tme'
  $ks_encrypted_root_password = "\$6\$tCD3X7ji\$1urw6qEMDkVxOkD33b4TpQAjRiCeDZx0jmgMhDYhfB9KuGfqO9OcMaKyUxnGGWslEDQ4HxTw7vcAMP85NxQe61"
  $ks_repo =
  [
   {
   "id" => "nailgun",
   "name" => "Nailgun",
   "url"  => "http://${ipaddress}:8080/centos/6.3/nailgun/x86_64"
   }
  ]


}
