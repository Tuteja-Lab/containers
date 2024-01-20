FROM ubuntu:18.04
MAINTAINER Arun Seetharam <arnstrm@iastate.edu>
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    apt-get install -y g++ gcc curl wget build-essential make xz-utils git gnupg netbase python python-dev && \
    apt-get install -y libtinfo-dev libncurses5 libncurses5-dev zlib1g-dev libc6-dev libffi-dev libgmp-dev libglc-dev && \
    apt-get install -y freeglut3 freeglut3-dev && \
    apt-get -y dist-upgrade && \
    apt-get -y update && \
    apt-get install -y haskell-platform
# install Taiji
RUN curl -L https://github.com/Taiji-pipeline/Taiji/releases/download/v1.3.0/taiji-Ubuntu-x86_64 -o /usr/bin/taiji && \
    chmod +x /usr/bin/taiji 

