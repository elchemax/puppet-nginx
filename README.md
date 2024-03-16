# Managing nginx with puppet

This module is an exercise to manage nginx with puppet. Both nginx and the puppet server run on docker containers.

It does two things:

- It creates a proxy to redirect requests for https://domain.com to 10.10.10.10 and redirect requests for https://domain.com/resource2 to 20.20.20.20.
- It creates a forward proxy to log HTTP requests going from the internal network to the Internet including request protocol, remote IP and time taken to serve the request.


# Requirements

You need to install docker engine. Follow the documentation on https://docs.docker.com/engine/install/ and https://docs.docker.com/engine/install/linux-postinstall/ to setup the docker environment.

# How to use this module

Create a network, both docker containers will be on the same network:

> docker network create --subnet=172.20.0.0/16 skynet

I'll assume you already know how to use git, create a directory with a cool name such as zombie-jedi-dinosaur-tamer (or one that's not so cool, such as puppet-nginx) and clone the repo in it:

> git clone https://github.com/elchemax/puppet-nginx.git

There's one directory for the puppetserver and one for the nginx server.

Enter puppetserver and run:

> docker compose up

If you want to run it in the background:

> docker compose up -d

Use "docker ps" to check the container's status:

> $ docker ps
>
> CONTAINER ID   IMAGE                   COMMAND                  CREATED        STATUS         PORTS                                       NAMES
> 
> c921dad6b867   puppetserverv3-puppet   "/bin/sh -c 'sleep i…"   45 hours ago   Up 4 seconds   0.0.0.0:8140->8140/tcp, :::8140->8140/tcp   puppet

Open a terminal in the puppet server container:

> docker exec -it puppet /bin/bash

Start the puppet server and make sure it's running and listening on the right port:


>root@c921dad6b867:/# service puppetserver start
>
>root@c921dad6b867:/# service puppetserver status
>
> * puppetserver is running
> root@c921dad6b867:/# netstat -tnlp
>
> Active Internet connections (only servers)
>
> Proto Recv-Q Send-Q Local Address           Foreign Address         State      
>
> PID/Program name    
>tcp        0      0 127.0.0.11:34139        0.0.0.0:*               LISTEN      -                   
>
>tcp        0      0 0.0.0.0:8140            0.0.0.0:*               LISTEN      -                   
>

Now let's start the nginx server, on the nginx folder:

> docker compose up -d

Enter the nginx container:

> docker exec -it nginx /bin/bash

Run puppet:

> puppet agent -t

If it's the first time running puppet, you'll need to sign the certificate on the puppet server, so on the puppet bash, run:

> puppetserver ca sign --all

And run puppet again in nginx.

If the execution was successful, check the configuration:

> cat /etc/nginx/sites-enabled/www.domain.com.conf 

At the beginning of the file you'll see this line:

> \# MANAGED BY PUPPET

At this point, the nginx server is accepting requests and its configuration is managed by puppet.

# Testing

## Testing nginx

From your workstation, in order to check that calls to domain.com are being redirected, first map domain to 127.0.0.1 in /etc/hosts, since you probably don't own the domain, then:

> curl -k http://domain.com:8080

Monitor the logs while executing the command above:

> ==> /var/log/nginx/www.domain.com.access.log <==
172.20.0.1 - - [15/Mar/2024:20:47:19 +0000] "GET / HTTP/1.1" 499 0 "-" "curl/7.88.1"
172.20.0.1 - - [15/Mar/2024:20:47:28 +0000] "GET / HTTP/1.1" 499 0 "-" "curl/7.88.1"
172.20.0.1 - - [15/Mar/2024:20:47:29 +0000] "GET /favicon.ico HTTP/1.1" 504 167 "http://domain.com:8080/" "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0"

==> /var/log/nginx/www.domain.com.error.log <==
2024/03/15 20:47:29 [error] 1759#1759: *10 upstream timed out (110: Connection timed out) while connecting to upstream, client: 172.20.0.1, server: www.domain.com, request: "GET /favicon.ico HTTP/1.1", upstream: "http://10.10.10.10:80/favicon.ico", host: "domain.com:8080", referrer: "http://domain.com:8080/"

This is an expected result, since the request is redirected, but nothing listens on 10.10.10.10.

## Testing the forward proxy

Open one bash to send a request and one to print the log, for example using tail.

Use curl to request a URL using our forward proxy, which listens on port 777:

> curl -k google.com --proxy http://localhost:777

On the log we can see the connection in the custom format [date] - protocol - "address" [time]
> ==> /var/log/nginx/forward-proxy.com.access.log <==
> [15/Mar/2024:20:38:02 +0000] - http - "127.0.0.1" [0.447]


# Troubleshooting

If puppetserver fails to start, which can happen after you shut down your PC and run docker compose again, check this log: /var/log/puppetlabs/puppetserver/puppetserver-daemon.log, if this line shows:

> start-stop-daemon: matching only on non-root pidfile /run/puppetlabs/puppetserver/puppetserver.pid is insecure

Remove the pid file:

> rm /run/puppetlabs/puppetserver/puppetserver.pid

Now try again. Good luck!

# Upcoming version

Currently I'm working on a new feature:

- Implementing a proxy health check.

# Useful links

Install puppet on docker, the setup was too complex for this exercise but it was a good starting point:

https://medium.com/swlh/install-puppet-server-on-docker-fe4a80cbe3be

Instructions to create nginx manifest:

https://forge.puppet.com/modules/puppet/nginx/readme

Instructions to create nginx forward proxy:

https://www.baeldung.com/nginx-forward-proxy

Nginx log format:

https://docs.nginx.com/nginx/admin-guide/monitoring/logging/

I could not find in the documentation how to log the protocol in nginx, but I found a tip here:

https://stackoverflow.com/questions/16305610/logging-the-request-protocol-in-nginx

Also, I found an example about how to set the log format in puppet for nginx here:

https://github.com/voxpupuli/puppet-nginx/issues/1139

About nginx health checks:

https://docs.nginx.com/nginx/admin-guide/load-balancer/http-health-check/

How to configure upstream resource in nginx:

https://www.puppetmodule.info/modules/spantree-nginx/0.0.1/puppet_defined_types/nginx_3A_3Aresource_3A_3Aupstream