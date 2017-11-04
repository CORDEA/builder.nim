FROM centos:latest

MAINTAINER Yoshihiro Tanaka <contact@cordea.jp>

RUN yum update -y && \
        yum install -y centos-release-scl && \
        yum install -y gcc rh-git29 hg

RUN scl enable rh-git29 "git clone https://github.com/nim-lang/Nim.git /home/nims/latest/" && \
        cd /home/nims/latest/ && \
        scl enable rh-git29 "git clone --depth 1 https://github.com/nim-lang/csources.git" && \
        cd csources && \
        sh build.sh && \
        cd ../ && \
        bin/nim c koch && \
        ./koch boot -d:release && \
        scl enable rh-git29 "./koch nimble"

ENV PATH $PATH:/home/nims/latest/bin/

RUN scl enable rh-git29 \
        "nimble install -y nimble"

RUN scl enable rh-git29 \
        "git clone https://github.com/CORDEA/builder.nim.git /home/builder.nim/" && \
        cd /home/builder.nim && \
        nim c builder.nim

ADD enablegit29.sh /etc/profile.d/enablegit29.sh

ENTRYPOINT ["bash"]
