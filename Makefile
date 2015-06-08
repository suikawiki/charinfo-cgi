all: all-data

WGET = wget
CURL = curl
GIT = git
PERL = ./perl

updatenightly: local/bin/pmbp.pl
	$(CURL) https://gist.githubusercontent.com/motemen/667573/raw/git-submodule-track | sh
	$(GIT) add modules
	perl local/bin/pmbp.pl --update
	$(GIT) add config

## ------ Setup ------

deps: git-submodules pmbp-install data local/texts.pl

git-submodules:
	$(GIT) submodule update --init

PMBP_OPTIONS=

local/bin/pmbp.pl:
	mkdir -p local/bin
	$(WGET) -O $@ https://raw.github.com/wakaba/perl-setupenv/master/bin/pmbp.pl
pmbp-upgrade: local/bin/pmbp.pl
	perl local/bin/pmbp.pl $(PMBP_OPTIONS) --update-pmbp-pl
pmbp-update: pmbp-upgrade git-submodules
	perl local/bin/pmbp.pl $(PMBP_OPTIONS) --update
pmbp-install: pmbp-upgrade
	perl local/bin/pmbp.pl $(PMBP_OPTIONS) --install \
            --create-perl-command-shortcut perl \
            --create-perl-command-shortcut prove \
            --create-perl-command-shortcut plackup

## ------ Data ------

data: all-data

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

local/texts.pl: bin/create-texts-pl.pl texts/texts.json
	$(PERL) bin/create-texts-pl.pl > $@

## ------ Tests ------

test:
	./prove t/*.t

test-deps: deps
