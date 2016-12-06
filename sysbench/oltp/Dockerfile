FROM centos:7
MAINTAINER Agust√n <guriandoro@gmail.com>

RUN yum -y install http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm
RUN yum -y --setopt tsflags= install sysbench

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

