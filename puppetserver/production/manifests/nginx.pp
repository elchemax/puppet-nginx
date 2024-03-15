class{'nginx':
    manage_repo     => true,
    package_source  => 'nginx-mainline',
    log_format     => {
      'internal_to_internet' => '[$time_local] - $scheme - "$remote_addr" [$request_time]'
    },
}

  nginx::resource::server{'www.domain.com':
    #www_root => '/usr/share/nginx/html/domain.com/html/',
    listen_port => 80,
    proxy       => 'http://10.10.10.10/',
    access_log  => '/var/log/nginx/www.domain.com.access.log',
  }

  nginx::resource::location{'/resource2':
    server   => 'www.domain.com',
    #www_root => '/usr/share/nginx/html/domain.com/resource2/html/',
    proxy => 'http://20.20.20.20/',
  }
  file { 'default.conf':
   path   => '/etc/nginx/conf.d/default.conf',
   ensure => absent,
  }
  
  nginx::resource::server{'forward-proxy.com':
    listen_port => 777,
    proxy       => 'https://$http_host$request_uri',
    format_log  => 'internal_to_internet',
    resolver    => ['8.8.8.8'],
  }
