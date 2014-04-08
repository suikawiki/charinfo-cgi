all: all-data

## ------ Setup ------

WGET = wget
GIT = git

deps: git-submodules pmbp-install

git-submodules:
	$(GIT) submodule update --init

local/bin/pmbp.pl:
	mkdir -p local/bin
	$(WGET) -O $@ https://raw.github.com/wakaba/perl-setupenv/master/bin/pmbp.pl
pmbp-upgrade: local/bin/pmbp.pl
	perl local/bin/pmbp.pl --update-pmbp-pl
pmbp-update: pmbp-upgrade git-submodules
	perl local/bin/pmbp.pl --update
pmbp-install: pmbp-upgrade
	perl local/bin/pmbp.pl --install \
            --create-perl-command-shortcut perl \
            --create-perl-command-shortcut prove \
            --create-perl-command-shortcut plackup

## ------ Server configuration ------

# Need SERVER_ENV!
server-config: daemontools-config batch-server

# Need SERVER_ENV!
install-server-config: install-daemontools-config

SERVER_ENV = HOGE
SERVER_ARGS = \
    APP_NAME=charinfo \
    SERVER_INSTANCE_NAME="charinfo-$(SERVER_ENV)" \
    SERVER_INSTANCE_CONFIG_DIR="$(abspath ./config)" \
    ROOT_DIR="$(abspath .)" \
    LOCAL_DIR="$(abspath ./local)" \
    LOG_DIR=/var/log/app \
    SYSCONFIG="/etc/sysconfig/charinfo" \
    SERVICE_DIR="/service" \
    SERVER_USER=wakaba LOG_USER_GROUP=wakaba.wakaba \
    SERVER_ENV="$(SERVER_ENV)"

# Need SERVER_ENV!
daemontools-config:
	$(MAKE) --makefile=Makefile.service all $(SERVER_ARGS) SERVER_TYPE=web

# Need SERVER_ENV!
install-daemontools-config:
	mkdir -p /var/log/app
	chown wakaba.wakaba /var/log/app
	$(MAKE) --makefile=Makefile.service install $(SERVER_ARGS) SERVER_TYPE=web

# Need SERVER_ENV!
batch-server:
	mkdir -p local/config/cron.d
	cd config/cron.d.in && find -type f | \
            xargs -l1 -i% -- sh -c "cat % | sed 's/@@ROOT@@/$(subst /,\/,$(abspath .))/g' > ../../local/config/cron.d/$(SERVER_ENV)-%"

## ------ Data ------

dataupdate: clean-data all-data

all-data: local/names.json local/sets.json local/indexes.json local/maps.json

clean-data:
	rm -fr local/*.json

local/names.json:
	mkdir -p local
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-chars/master/data/names.json
local/sets.json:
	mkdir -p local
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-chars/master/data/sets.json
local/maps.json:
	mkdir -p local
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-chars/master/data/maps.json

local/indexes.json:
	mkdir -p local
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-web-defs/master/data/encoding-indexes.json

## ------ Deployment ------

CINNAMON_GIT_REPOSITORY = git://github.com/wakaba/cinnamon.git

cinnamon:
	mkdir -p local
	cd local && (($(GIT) clone $(CINNAMON_GIT_REPOSITORY)) || (cd cinnamon && $(GIT) pull)) && cd cinnamon && $(MAKE) deps
	echo "#!/bin/sh" > ./cin
	echo "exec $(abspath local/cinnamon/perl) $(abspath local/cinnamon/bin/cinnamon) \"\$$@\"" >> ./cin
	chmod ugo+x ./cin
