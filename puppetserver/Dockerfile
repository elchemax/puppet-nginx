FROM ubuntu:22.04

RUN ["apt-get", "update"]
RUN ["apt-get", "install", "-y", "wget"]
RUN wget https://apt.puppet.com/puppet7-release-focal.deb
RUN dpkg -i puppet7-release-focal.deb
RUN ["apt-get", "update", "-y"]
RUN ["apt-get", "install", "-y", "vim"]
RUN ["apt-get", "install", "-y", "puppetserver"]
RUN ["apt-get", "install", "-y", "puppet-agent"]
RUN ["apt-get", "install", "-y", "ca-certificates"]
RUN ["apt-get", "install", "-y", "iputils-ping"]
RUN ["apt-get", "install", "-y", "systemd"]

CMD service puppetserver start
CMD sleep infinity #otherwise the container exits upon creation
#COPY puppet.conf /etc/puppet/

