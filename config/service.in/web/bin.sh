#!/bin/sh
exec 2>&1

port=8001

eval "exec setuidgid @@USER@@ @@ROOT@@/plackup $PLACK_COMMAND_LINE_ARGS \
    --host 127.0.0.1 \
    -p $port @@ROOT@@/server.psgi"
