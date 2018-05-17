FROM ubuntu:latest

MAINTAINER Yoshihiro Tanaka <contact@cordea.jp>

RUN apt-get update -y && \
        apt-get install -y gcc git mercurial && \
        git clone https://github.com/nim-lang/Nim.git /home/nims/latest && \
        cd /home/nims/latest/ && \
        git clone --depth 1 https://github.com/nim-lang/csources.git && \
        cd csources && \
        sh build.sh && \
        cd ../ && \
        bin/nim c koch && \
        ./koch boot -d:release && \
        ./koch tools

ENV PATH $PATH:/home/nims/latest/bin/

RUN nimble install -y nimble && \
        git clone https://github.com/CORDEA/builder.nim.git /home/builder.nim/ && \
        cd /home/builder.nim && \
        nim c builder.nim

ENTRYPOINT ["bash"]
