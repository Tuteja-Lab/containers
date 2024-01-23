FROM ubuntu:14.04
MAINTAINER Arun Seetharam <arnstrm@iastate.edu>

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    apt-get install -y g++ gcc curl wget build-essential make xz-utils git gnupg netbase python python-dev && \
    apt-get install -y libz-dev libssl-dev zlib1g-dev libc6-dev libffi-dev openssl libpng12-dev mysql-client libmysqlclient-dev && \
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

ADD scripts/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*

# Create UCSC public MySQL server configuration
RUN echo "db.host=genome-mysql.cse.ucsc.edu\ndb.user=genomep\ndb.password=password" > /root/.hg.conf

