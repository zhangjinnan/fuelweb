class nailgun::puppetmaster(
  $puppet_master_hostname = $nailgun::params::puppet_master_hostname,
  $puppet_master_package_version = $nailgun::params::puppet_master_package_version,
  $gem_source = $nailgun::params::gem_source,
  ) inherits nailgun::params {

  class { ::puppetmaster :
    puppet_master_hostname => $puppet_master_hostname,
    gem_source => $gem_source,
    puppet_package_version => $puppet_master_package_version,
  }

}
