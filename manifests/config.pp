# == Class: inspircd::config
#
# Create configuration files for InspIRCd, based on default settings
# from inspircd::params and hiera.
#
# === Parameters
#
# None
#
# === Authors
#
# Evgeni Golov <evgeni@golov.de>
#
# === Copyright
#
# Copyright 2013 Evgeni Golov
#
class inspircd::config (
  $ensure      = hiera('ensure', $inspircd::params::ensure),
  $servername  = hiera('servername', $inspircd::params::servername),
  $network     = hiera('network', $inspircd::params::network),
  $description = hiera('description', $inspircd::params::description),
  $networkname = hiera('networkname', $inspircd::params::networkname),
  $adminname   = hiera('adminname', $inspircd::params::adminname),
  $adminemail  = hiera('adminemail', $inspircd::params::adminemail),
  $adminnick   = hiera('adminnick', $inspircd::params::adminnick),
  $ips         = hiera('ips', $inspircd::params::ips),
  $opers       = hiera('opers', $inspircd::params::opers),
  $ssl         = hiera('ssl', $inspircd::params::ssl),
  $sslonly     = hiera('sslonly', $inspircd::params::sslonly),
  $cafile      = hiera('cafile', $inspircd::params::cafile),
  $certfile    = hiera('certfile', $inspircd::params::certfile),
  $keyfile     = hiera('keyfile', $inspircd::params::keyfile),
  $ldapauth    = hiera('ldapauth', $inspircd::params::ldapauth),
  $from_src    = hiera('from_src', $inspircd::params::from_src),
) inherits inspircd::params {
  case $from_src {
    true    : { $config = '/opt/inspircd/conf/inspircd.conf' }
    default : { $config = '/etc/inspircd/inspircd.conf' }
  }

  file { $config:
    ensure  => $ensure,
    owner   => 'irc',
    group   => 'irc',
    mode    => '0400',
    content => template('inspircd/inspircd.conf.erb'),
    require => Class['inspircd::package'],
    notify  => Service['inspircd'],
  }

  file { '/etc/default/inspircd':
    ensure  => $ensure,
    owner   => 'irc',
    group   => 'irc',
    mode    => '0400',
    source  => 'puppet:///modules/inspircd/default',
    require => Class['inspircd::package'],
    notify  => Service['inspircd'],
  }

  if $from_src {
    # Generate certs if necessary
    gnutls::generate_key{'inspircd':
      certfile    => $certfile,
      keyfile     => $keyfile,
      user        => 'irc',
    }
  }
}
