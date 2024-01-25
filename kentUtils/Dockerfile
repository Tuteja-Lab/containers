FROM ubuntu:14.04
MAINTAINER Arun Seetharam <arnstrm@iastate.edu>

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    apt-get install -y g++ gcc curl wget bc build-essential make xz-utils git gnupg netbase python python-dev && \
    apt-get install -y libz-dev libssl1.0.0 libssl-dev zlib1g-dev libc6-dev libffi-dev openssl libpng12-dev mysql-client libmysqlclient-dev && \
    apt-get -y dist-upgrade && \
    apt-get -y update
RUN git config --global http.sslverify false
RUN cd /tmp && \
    git clone https://github.com/ENCODE-DCC/kentUtils.git && \
    cd kentUtils && \
    sed -i 's/git clone http:/git clone https:/' Makefile && \
    make && \
    cp -rp bin/* /usr/local/bin && \
    cd .. && rm -rf kentUtils

RUN cd /tmp && \
    wget http://eddylab.org/software/squid/squid.tar.gz && \
    tar -xzf squid.tar.gz && \
    cd squid-* && \
    ./configure && \
    make && \
    cp -rp shuffle /usr/local/bin/squidShuffle


ADD scripts/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*

RUN export LC_ALL=en_US.UTF-8
RUN export LANG=en_US.UTF-8
RUN locale-gen en_US.UTF-8

# Create UCSC public MySQL server configuration
RUN echo "db.host=genome-mysql.cse.ucsc.edu\ndb.user=genomep\ndb.password=password" > /root/.hg.conf
RUN apt-get install libssl1.0.0 libssl-dev --reinstall
RUN cd /lib/x86_64-linux-gnu && \
    ln -s libssl.so.1.0.0 libssl.so.10 && \
    ln -s libcrypto.so.1.0.0 libcrypto.so.10
RUN ln -s /lib/x86_64-linux-gnu/libssl.so.1.0.0 /usr/lib/libssl.so.10
RUN ln -s /lib/x86_64-linux-gnu/libcrypto.so.1.0.0 /usr/lib/libcrypto.so.10
