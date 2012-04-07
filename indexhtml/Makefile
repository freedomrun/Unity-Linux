NAME := indexhtml
SHELL := /bin/bash
VERSION := 2012
RELEASE := 1
TARNAME := $(NAME)-$(VERSION)

TEXTDOMAIN := indexhtml

##########################################################
DESTDIR =
prefix = /usr

DATADIR = $(DESTDIR)$(prefix)/share
DOCDIR = $(DATADIR)/doc
LOCALEDIR = $(DATADIR)/locale
###########################################################

SPLOG := $(shell which splog)

INSTLOCALES := ${patsubst l10n/%.po,%,${wildcard l10n/*.po}}

# These are the locales for which the translation is complete (no untranslated & no fuzzy strings)
# Uncomplete locales will not be used to translate the html files
SUPPORTEDLOCALES := $(shell oklocales=""; \
                            for i in $(INSTLOCALES); \
                            do \
                            [[ $$(msgattrib -i l10n/$$i.po --fuzzy|grep -c msgid) -eq 0 && $$(msgattrib -i l10n/$$i.po --untranslated|grep -c msgid) -eq 0 ]] && oklocales="$$oklocales $$i"; \
                            done; \
                            echo $$oklocales)

POS := ${wildcard l10n/*.po}
DOCS := ${wildcard *.html}
INSTDOCS := ${patsubst %,inst/%,$(DOCS)}
TRANSDOCSDIRS := ${patsubst %,translated/%,$(SUPPORTEDLOCALES)}
TRANSDOCS := $(shell for l in $(TRANSDOCSDIRS); do for d in $(DOCS); do echo $$l/$$d; done; done )
INSTTRANSDOCSDIRS := ${patsubst translated/%,inst/%,$(TRANSDOCSDIRS)}
INSTTRANSDOCS := ${patsubst translated/%,inst/%,$(TRANSDOCS)}


$(TRANSDOCS) : DOMAIN = $(patsubst %.html,%,$(notdir $@))

$(TRANSDOCS) : LOCALE = $(patsubst translated/%/,%,$(dir $@))

$(INSTTRANSDOCS) : DOMAIN = $(patsubst %.html,%,$(notdir $@))

$(INSTTRANSDOCS) : LOCALE = $(patsubst inst/%/,%,$(dir $@))

$(INSTTRANSDOCSDIRS) : LOCALE = $(patsubst inst/%,%,$@)

$(INSTDOCS) : DOMAIN = $(patsubst %.html,%,$(notdir $@))

l10n/%.po : LOCALE = ${patsubst l10n/%.po,%,$@}

CSSDIR := css
CSSFILES := $(CSSDIR)/*

JAVASCRIPTDIR := js
JAVASCRIPTFILES := $(JAVASCRIPTDIR)/*
SUPPORTED := supported_locales.js

IMAGESDIR := images
IMAGESFILES := $(IMAGESDIR)/*


all: translated/$(JAVASCRIPTDIR)/$(SUPPORTED) $(TRANSDOCS)

translated/$(JAVASCRIPTDIR)/$(SUPPORTED):
	@[ -d translated/$(JAVASCRIPTDIR) ] || mkdir -p translated/$(JAVASCRIPTDIR)
	@echo "var supported = new Object();" > translated/$(JAVASCRIPTDIR)/$(SUPPORTED)

$(TRANSDOCS):
	@[ -d translated/$(LOCALE) ] || mkdir -p translated/$(LOCALE)
	@po2html -i l10n/$(LOCALE).po -o translated/$(LOCALE)/$(DOMAIN).tmp -t $(DOMAIN).html
	@cat translated/$(LOCALE)/$(DOMAIN).tmp | sed -e 's,css/,../css/,g' | sed -e 's,js/,../js/,g' | sed -e 's,images/,../images/,g' > translated/$(LOCALE)/$(DOMAIN).html
	@grep -q 'supported\["$(LOCALE)"\] = true' translated/$(JAVASCRIPTDIR)/$(SUPPORTED) || echo 'supported["$(LOCALE)"] = true' >> translated/$(JAVASCRIPTDIR)/$(SUPPORTED)
	@rm -rf translated/$(LOCALE)/$(DOMAIN).tmp; \

installdir:
	@install -d -m 0755 $(DOCDIR)/HTML
	@install -d -m 0755 $(DOCDIR)/HTML/{$(CSSDIR),$(JAVASCRIPTDIR),$(IMAGESDIR)}

$(INSTTRANSDOCSDIRS):
	@install -d -m 0755 $< $(DOCDIR)/HTML/$(LOCALE)
	
installdirs: installdir $(INSTTRANSDOCSDIRS)

$(INSTTRANSDOCS):
	@install -m 644 translated/$(LOCALE)/$(DOMAIN).html $(DOCDIR)/HTML/$(LOCALE)/$(DOMAIN).html

$(INSTDOCS):
	@install -m 644 $(DOMAIN).html $(DOCDIR)/HTML/$(DOMAIN).html

instextrafiles:
	@install -m 644 $(CSSFILES) $(DOCDIR)/HTML/$(CSSDIR)
	@install -m 644 $(JAVASCRIPTFILES) $(DOCDIR)/HTML/$(JAVASCRIPTDIR)
	@install -m 644 translated/$(JAVASCRIPTDIR)/$(SUPPORTED) $(DOCDIR)/HTML/$(JAVASCRIPTDIR)
	@install -m 644 $(IMAGESFILES) $(DOCDIR)/HTML/$(IMAGESDIR)

install: installdirs $(INSTDOCS) $(INSTTRANSDOCS) instextrafiles
	@echo
	@echo "Installation complete"
	@echo 



l10n/%.po: l10n/$(TEXTDOMAIN).pot
	@msginit -i l10n/$(TEXTDOMAIN).pot -l $(LOCALE) -o l10n/$(LOCALE).po


l10n/$(TEXTDOMAIN).pot: update-pot


update-pot: cleantranslated
	@html2po --duplicates=merge -i . -o l10n -P
	@rm -f l10n/$(TEXTDOMAIN).pot
	@msgcat l10n/*.pot > l10n/$(TEXTDOMAIN).tmp
	@rm -rf l10n/*.pot
	@mv l10n/$(TEXTDOMAIN).tmp l10n/$(TEXTDOMAIN).pot
	@echo
	@echo "Updated catalog template $(TEXTDOMAIN).pot"
	@echo 


update-pos: update-pot
	@for loc in $(INSTLOCALES) ; \
	do \
		echo "Merging $$n"; \
		msgmerge -U l10n/$$loc.po l10n/$(TEXTDOMAIN).pot ; \
	done
	@echo
	@echo "All catalogs updated to current template"
	@echo 

cleannotice:
	@echo
	@echo "Removing all rubbish first..."

cleandist:
	@rm -rf $(TARNAME) $(TARNAME).tar.xz

cleantranslated:
	@rm -rf translated

distdir:
	@if [ ! -d $(TARNAME) ]; then mkdir $(TARNAME); fi

localcopy: cleannotice clean distdir
	@tar cp --exclude=.svn --exclude=$(TARNAME) --exclude=*.tar.xz . | tar xp -C $(TARNAME)

tar: localcopy spec
	@tar cJf $(TARNAME).tar.xz $(TARNAME)
	@rm -rf $(TARNAME)
	@echo
	@echo "$(TARNAME).tar.xz generated in $$PWD"
	@echo

clean: cleandist cleantranslated
	@rm -f $(NAME).spec
	@rm -f l10n/*.{mo,po~}
	@find -name '*~' -exec rm {} \;
	@echo
	@echo "Cleaning complete"
	@echo

$(NAME).spec: $(NAME).spec.in
	@sed -n "1,$$[$$(grep -n "@LOCALIZED_FILES@" $(NAME).spec.in | cut -f1 -d:)-1]p"  $< | \
              sed 's/@VERSION@/$(VERSION)/g' | sed 's/@RELEASE@/$(RELEASE)/g' > $@
	@for i in $(SUPPORTEDLOCALES); do \
		echo "%lang($$i) %{_datadir}/doc/HTML/$$i/*" >> $@ ; \
	done
	@sed -n "$$[$$(grep -n "@LOCALIZED_FILES@" $(NAME).spec.in | cut -f1 -d:)+1],\$$p" $< >> $@
	@echo
	@echo "$(NAME).spec generated in $$PWD"
	@echo

spec: $(NAME).spec

spec-update: spec
ifeq ($(SPLOG),)
	$(error Can't find splog. Please, install 'pkgutils' and retry)
endif

ifeq ($(pname),)
	$(error Please, define the packager name by appending 'pname=name_of_the_packager')
endif 

ifeq ($(pmail),)
	$(error Please, define the packager e-mail by appending 'pmail=e-mail_of_the_packager')
endif

ifeq ($(taglist),)
	$(error Please, define the tag list by appending 'taglist="-t \"sentence to log\" -t \"other sentence to log\""')
endif

	@$(SPLOG) -p "$(pname) <$(pmail)>" $(taglist) $(NAME).spec
	@echo
	@echo "The %changelog section of $(NAME).spec has been updated with the provided info."
	@echo "Run 'make spec-merge' if you want to merge it back into the spec template, but first check it out!"
	@echo


spec-merge: spec
	@head -n $$(($$(grep -n "%changelog" $(NAME).spec.in | cut -f1 -d:)-1)) $(NAME).spec.in > temp.spec
	@tail -n $$(($$(wc -l < $(NAME).spec)-$$(grep -n "%changelog" $(NAME).spec | cut -f1 -d:)+1)) $(NAME).spec >> temp.spec
	@mv -f temp.spec $(NAME).spec.in
	@echo
	@echo "The %changelog section of $(NAME).spec has been merged back into the spec template."
	@echo

lang-update: update-pos
	@echo
	@echo "All lang files are now up to date"
	@echo

version:
	@echo
	@echo "$(NAME), $(VERSION)-$(RELEASE)"
	@echo

maintenance-help:
	@echo
	@echo '                  ********************************'
	@echo '                  *****INDEX.HTML MAINTENANCE*****'
	@echo '                  ********************************'
	@echo
	@echo '* SPEC UPDATE'
	@echo
	@echo ' Make sure you have bumped the release, or updated the version by'
	@echo ' modifying the values of VERSION or RELEASE in the Makefile.'
	@echo
	@echo ' [Please, note that you can view what the current version and'
	@echo ' release are by running `make version`]'
	@echo 
	@echo ' Once you have done that, and once you are happy with all your'
	@echo ' modifications, update the spec file with the following command:'
	@echo 
	@echo ' make spec-update pname="PKGRNAME" pmail="PKGRMAIL" taglist="TAGS"'
	@echo 
	@echo ' Where:'
	@echo '         PKGRNAME is the name of the packager'
	@echo 
	@echo '         PKGRMAIL is the e-mail address of the packager'
	@echo 
	@echo '         TAGS is a list of sentences to be logged in the Changelog'
	@echo '         in the form'
	@echo '         "-t \"First sentence to log\" -t \"Second sentence to log\""'
	@echo
	@echo ' Example:'
	@echo '          make spec-update pname="Unity packager" \'
	@echo '          pmail="packager@unity-linux.org" taglist="-t \"New version\""'
	@echo
	@echo ' If you are happy with the spec, you must merge back the updated'
	@echo ' Changelog into the spec template $(NAME).spec.in'
	@echo ' In order to do so, use the following command:'
	@echo
	@echo ' make spec-merge'
	@echo
	@echo ' Please, note that you must edit $(NAME).spec.in directly, if you'
	@echo ' need to modify any section of the spec other than the Changelog.'
	@echo
	@echo
	@echo '* TARBALL CREATION'
	@echo
	@echo ' You can easily create a tarball with the updated files with the'
	@echo ' following command:'
	@echo
	@echo ' make tar'
	@echo
	@echo
	@echo '* LANGUAGE FILES UPDATE'
	@echo
	@echo ' To update the template catalog and merge all language files with'
	@echo ' the new template, use the following command:'
	@echo
	@echo ' make lang-update'
	@echo
	@echo
	@echo '* TESTING INSTALL'
	@echo
	@echo ' If you want to check whether the install procedure runs smoothly, you'
	@echo ' might want to install to a different destination (for example: your'
	@echo ' home directory).'
	@echo ' Set the DESTDIR variable (case-sensitive) in this way:'
	@echo
	@echo ' make DESTDIR=/path/to/destination/dir install'
	@echo
	@echo 
	@echo 'NOTE: Whenever you change something, and you want to rebuild the spec,'
	@echo '      the tarball, etc., and especially before committing your changes,'
	@echo '      always launch first:'
	@echo
	@echo '      make clean'
	@echo
	@echo 
