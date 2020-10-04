#XXX
#FROM quay.io/wakaba/docker-perl-app-base
FROM debian:stretch

ADD .git/ /app/.git/
ADD .gitmodules /app/.gitmodules
ADD Makefile /app/
ADD bin/ /app/bin/
ADD texts/ /app/texts/
ADD lib/ /app/lib/
ADD fonts/ /app/fonts/
ADD config/ /app/config/
ADD modules/ /app/modules/
ADD server.psgi /app/server.psgi
ADD css.css /app/css.css
ADD rev /app/rev

RUN (apt-get update || (sleep 3 && apt-get update)) && \
    apt-get -y install libidn11-dev bzip2 make wget curl && \
    rm -rf /var/lib/apt/lists/*

RUN cd /app && \
    make deps-docker PMBP_OPTIONS="--execute-system-package-installer --dump-info-file-before-die" && \
    echo '#!/bin/bash' > /server && \
    echo 'cd /app' >> /server && \
    echo 'exec ./plackup -s Twiggy::Prefork --max-workers 2 -p 8080 server.psgi' >> /server && \
    chmod u+x /server && \
    rm -fr /app/.git /app/deps /app/t /app/t_deps && \
    rm -rf /var/lib/apt/lists/*
