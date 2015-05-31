FROM debian:sid

RUN apt-get update && \
    apt-get -y install git wget curl make perl gcc && \
    rm -rf /var/lib/apt/lists/*

RUN git clone git://github.com/wakaba/charinfo-cgi /charinfo && \
    cd /charinfo && make deps && \
    echo '/charinfo/plackup /charinfo/server.psgi -p 8080' > /server && \
    chmod u+x /server
