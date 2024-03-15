FROM nginx
COPY content /usr/share/nginx/html
#COPY domain.com.conf /etc/nginx/conf.d
COPY .bashrc /root
RUN ["apt-get", "update"]
RUN ["apt-get", "install", "-y", "vim"]
RUN ["apt-get", "install", "-y", "puppet-agent"]
RUN ["apt-get", "install", "-y", "iputils-ping"]
COPY puppet.conf /etc/puppet/

CMD sleep infinity
