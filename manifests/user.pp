class inspircd::user {
    group {'irc':
        ensure  => present,
        gid     => 39,
    }
    user {'irc':
        ensure  =>  present,
        uid     => 39,
        gid     => 39,
        require => Group['irc'],
    }
}
