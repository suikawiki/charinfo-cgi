all: unicode-names unicode-general-category

WGET = wget
PERL = ../perl

unicode-names:
	$(WGET) -O ../local/NamesList.txt http://www.unicode.org/Public/UNIDATA/NamesList.txt
	$(WGET) -O ../local/NameAliases.txt http://www.unicode.org/Public/UNIDATA/NameAliases.txt
	$(PERL) generate-name-list.pl > names.pl

unicode-general-category: \
  unicode-general-category-2.0 \
  unicode-general-category-2.1 \
  unicode-general-category-3.0 \
  unicode-general-category-3.2 \
  unicode-general-category-5.0 \
  unicode-general-category-5.2 \
  unicode-general-category-6.0 \
  unicode-general-category-6.1 \
  unicode-general-category-6.2 \
  unicode-general-category-6.3 \
  unicode-general-category-latest

unicode-general-category-2.0: ../local/unicode/2.0/UnicodeData.txt
	$(PERL) generate-general-category.pl 2.0 $<
unicode-general-category-2.1: ../local/unicode/2.1/UnicodeData.txt
	$(PERL) generate-general-category.pl 2.1 $<
unicode-general-category-3.0: ../local/unicode/3.0/UnicodeData.txt
	$(PERL) generate-general-category.pl 3.0 $<
unicode-general-category-3.2: ../local/unicode/3.2/UnicodeData.txt
	$(PERL) generate-general-category.pl 3.2 $<
unicode-general-category-5.0: ../local/unicode/5.0/UnicodeData.txt
	$(PERL) generate-general-category.pl 5.0 $<
unicode-general-category-5.2: ../local/unicode/5.2/UnicodeData.txt
	$(PERL) generate-general-category.pl 5.2 $<
unicode-general-category-6.0: ../local/unicode/6.0/UnicodeData.txt
	$(PERL) generate-general-category.pl 6.0 $<
unicode-general-category-6.1: ../local/unicode/6.1/UnicodeData.txt
	$(PERL) generate-general-category.pl 6.1 $<
unicode-general-category-6.2: ../local/unicode/6.2/UnicodeData.txt
	$(PERL) generate-general-category.pl 6.2 $<
unicode-general-category-6.3: ../local/unicode/6.3/UnicodeData.txt
	$(PERL) generate-general-category.pl 6.3 $<
unicode-general-category-latest: ../local/unicode/latest/UnicodeData.txt
	$(PERL) generate-general-category.pl latest $<

../local/unicode/2.0/UnicodeData.txt:
	mkdir -p ../local/unicode/2.0
	$(WGET) -O $@ http://www.unicode.org/Public/2.0-Update/UnicodeData-2.0.14.txt
../local/unicode/2.1/UnicodeData.txt:
	mkdir -p ../local/unicode/2.1
	$(WGET) -O $@ http://www.unicode.org/Public/2.1-Update4/UnicodeData-2.1.9.txt
../local/unicode/3.0/UnicodeData.txt:
	mkdir -p ../local/unicode/3.0
	$(WGET) -O $@ http://www.unicode.org/Public/3.0-Update1/UnicodeData-3.0.1.txt
../local/unicode/3.2/UnicodeData.txt:
	mkdir -p ../local/unicode/3.2
	$(WGET) -O $@ http://www.unicode.org/Public/3.2-Update/UnicodeData-3.2.0.txt
../local/unicode/5.0/UnicodeData.txt:
	mkdir -p ../local/unicode/5.0
	$(WGET) -O $@ http://www.unicode.org/Public/5.0.0/ucd/UnicodeData.txt
../local/unicode/5.2/UnicodeData.txt:
	mkdir -p ../local/unicode/5.2
	$(WGET) -O $@ http://www.unicode.org/Public/5.2.0/ucd/UnicodeData.txt
../local/unicode/6.0/UnicodeData.txt:
	mkdir -p ../local/unicode/6.0
	$(WGET) -O $@ http://www.unicode.org/Public/6.0.0/ucd/UnicodeData.txt
../local/unicode/6.1/UnicodeData.txt:
	mkdir -p ../local/unicode/6.1
	$(WGET) -O $@ http://www.unicode.org/Public/6.1.0/ucd/UnicodeData.txt
../local/unicode/6.2/UnicodeData.txt:
	mkdir -p ../local/unicode/6.2
	$(WGET) -O $@ http://www.unicode.org/Public/6.2.0/ucd/UnicodeData.txt
../local/unicode/6.3/UnicodeData.txt:
	mkdir -p ../local/unicode/6.3
	$(WGET) -O $@ http://www.unicode.org/Public/6.3.0/ucd/UnicodeData.txt
../local/unicode/latest/UnicodeData.txt:
	mkdir -p ../local/unicode/latest
	$(WGET) -O $@ http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt

clean-unicode-latest:
	rm -fr ../local/unicode/latest