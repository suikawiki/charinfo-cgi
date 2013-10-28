all: unicode-names

WGET = wget
PERL = ../perl

unicode-names:
	$(WGET) -O ../local/NamesList.txt http://www.unicode.org/Public/UNIDATA/NamesList.txt
	$(WGET) -O ../local/NameAliases.txt http://www.unicode.org/Public/UNIDATA/NameAliases.txt
	$(PERL) generate-name-list.pl > names.pl
