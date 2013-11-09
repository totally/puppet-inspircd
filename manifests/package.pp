# == Class: inspircd::package
#
# Install InspIRCd.
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
class inspircd::package (
  $ensure = hiera('ensure', $inspircd::params::ensure),
  $use_backport = hiera('use_backport', $inspircd::params::use_backport),
  $from_src     = hiera('from_src', $inspircd::params::from_src),
  $inspircd_v   = hiera('inspircd_v', $inspircd::params::inspircd_v),
) inherits inspircd::params {
  if $use_backport {
    file { '/etc/apt/preferences.d/inspircd.pref':
      ensure  => $ensure,
      content => template('inspircd/etc/apt/preferences.d/inspircd.pref.erb'),
    }
  } else {
    file { '/etc/apt/preferences.d/inspircd.pref':
      ensure  => absent,
    }
  }

  if $from_src {
    # build_essential needed to compile source
    if (!defined(Package['build-essential'])){
        package{'build-essential':
            ensure  => installed,
        }
    }
    # libldap2-dev is needed so ldap module compiles
    include openldap::libldap
    include inspircd::user
  
    # irc user is required for make install
    # Required by ./configure for ascertaining whether GNUTLS is installed
    package {'pkg-config':
      ensure  => installed,
      require => Package['build-essential'],
    } ->
    exec {"get inspircd tarball":
      command     => "wget -O inspircdv${inspircd_v}.tar.gz https://github.com/inspircd/inspircd/archive/v${inspircd_v}.tar.gz",
      unless      => "test -f inspircdv${inspircd_v}.tar.gz",
      cwd         => "/root",
      logoutput   => true,
    } -> 
    exec {"unpack inspircd tarball":
      command     => "tar xfvz inspircdv${inspircd_v}.tar.gz",
      unless      => "test -d /root/inspircd-${inspircd_v}",
      cwd         => "/root",
      logoutput   => true,
    } -> 
    # Add link for ldapauth module (modules in modules/extra are not automatically compiled)
    file {"/root/inspircd-2.0.14/src/modules/m_ldapauth.cpp":
      ensure    => link,
      target    => "/root/inspircd-${inspircd_v}/src/modules/extra/m_ldapauth.cpp",
    } ->
    exec {"configure inspircd":
      command     => "perl configure --enable-gnutls --disable-interactive --prefix=/opt/inspircd --uid 39",
      cwd         => "/root/inspircd-${inspircd_v}/",
      unless      => "test -f GNUmakefile",
      logoutput   => true,
      require     => [Class['inspircd::user'], Class['openldap::libldap']],
    } -> 
    exec {"make inspircd":
      command     => "make",
      cwd         => "/root/inspircd-${inspircd_v}/",
      unless      => "test -f build/bin/inspircd",
      logoutput   => true,
      # This can take a LONG time
      timeout     => 900,
    } ->  
    exec {"make install inspircd":
      command     => "make install",
      cwd         => "/root/inspircd-${inspircd_v}/",
      unless      => "test -d /opt/inspircd",
      logoutput   => true,
    } -> 
    # link to startup script, drops to correct user automatically
    file {'/etc/init.d/inspircd':
      ensure  => link,
      target  => '/opt/inspircd/inspircd',
    }
  } else {
    package { 'inspircd':
      ensure  => $ensure,
      require => File['/etc/apt/preferences.d/inspircd.pref'],
    }
  }
}
