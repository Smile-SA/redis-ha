FROM openshift/base-centos7

RUN set -xe; \
    yum install -y epel-release; \
    yum install -y redis nc bind-utils; \
    yum clean all;

ADD redis-sentinel.conf /etc/redis-sentinel.conf
ADD redis.conf /etc/redis.conf
ADD redis-slave.conf /etc/redis-slave.conf
ADD startup.sh /startup.sh
EXPOSE 26379 6379
ENTRYPOINT ["/startup.sh"]
RUN set -xe ;\
    fix-permissions /var/lib/redis; \
    fix-permissions /etc;
USER 1001
CMD ["redis-server", "/etc/redis.conf"]
