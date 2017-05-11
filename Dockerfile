FROM centos:6

# Get OP5 software and install
RUN yum -y install wget which openssh-server \
&& wget http://repos.op5.com/tarballs/op5-monitor-7.3.11-20170428.tar.gz -O /tmp/op5-software.tar.gz \
&& tar -zxf /tmp/op5-software.tar.gz -C /tmp \
&& cd /tmp/op5-monitor-7.3.11 && ./install.sh --silent \
&& rm -f /tmp/op5-software.tar.gz \
&& cd /tmp && rm -rf /tmp/op5-monitor-7.3.11 \
&& yum clean all

# execute any post install scripts or install any addition software we may want

# open ports OP5 will need to use
# httpd for local gui access
EXPOSE 80 443

# Nrpe port to monitor OP5 status and resources
EXPOSE 5666

# OP5 port for cluster communication
EXPOSE 15551

# SSH local port is mapped to 2222 on host
EXPOSE 22

# snmpd listener port
EXPOSE 162/tcp 162/udp


RUN mkdir -p /root/.ssh
ADD id_rsa /root/.ssh/id_rsa
RUN chmod 700 /root/.ssh/id_rsa
RUN  echo "    IdentityFile ~/.ssh/id_rsa" >> /etc/ssh/ssh_config
ADD authorized_keys /root/.ssh/authorized_keys
RUN chmod 644 /root/.ssh/authorized_keys
ADD op5_hosts /op5_hosts
RUN cat /op5_hosts >> /etc/hosts
ADD add_node.sh /add_node.sh
RUN chmod +x /add_node.sh
ADD op5_sync.sh /op5_sync.sh

ADD start.sh /start.sh
RUN chmod +x /start.sh

# Start OP5
CMD ["/start.sh"]
