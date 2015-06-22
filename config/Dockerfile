FROM wakaba/docker-perl-app-base

RUN (apt-get update || (sleep 3 && apt-get update)) && \
    apt-get -y install libidn11-dev bzip2 && \
    rm -rf /var/lib/apt/lists/*

RUN mv /app /app.orig && \
    git clone git://github.com/wakaba/charinfo-cgi /app && \
    mv /app.orig/* /app/ && \
    cd /app && make deps PMBP_OPTIONS=--execute-system-package-installer && \
    echo '#!/bin/bash' > /server && \
    echo 'cd /app && ./plackup ./server.psgi -p 8080 -s Twiggy::Prefork --max-workers 3' >> /server && \
    chmod u+x /server && \
    rm -fr /app/deps /app.orig
