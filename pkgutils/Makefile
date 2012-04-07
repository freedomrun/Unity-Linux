NAME = pkgutils
VERSION = 0.6.7
RELEASE = 1

##########################################################

DESTDIR =
prefix = /usr
SBINPREFIX = $(prefix)
BINDIR = $(DESTDIR)$(prefix)/bin
LIBDIR = $(DESTDIR)$(prefix)/lib/$(NAME)
SHAREDIR = $(DESTDIR)$(prefix)/share/$(NAME)
ICONSDIR = $(DESTDIR)$(prefix)/share/pixmaps
DOCDIR = $(DESTDIR)$(prefix)/share/doc/$(NAME)-$(VERSION)
SBINDIR = $(DESTDIR)$(SBINPREFIX)/sbin
RCDIR = $(DESTDIR)$(SHAREDIR)/init.d
ROOTBINDIR = $(DESTDIR)$(prefix)/../bin
DESKTOPDIR = $(DESTDIR)$(prefix)/share/applications
LOCALEDIR = $(DESTDIR)$(prefix)/share/locale

###########################################################

ROOTBINDIRSCRIPTS := freeme jailme
SHAREDIRSCRIPTS := spec-clean-sed.sources
BINDIRSCRIPTS := bldchrt bldpkg create-basesystem cs i586 lo mkrepo pinfo rc req rmp rmvpkg saddpkg slinkin spec-clean splog svnadd svninst um unmet xzc xzz
SCRIPTNAMES := $(ROOTBINDIRSCRIPTS) $(SHAREDIRSCRIPTS) $(BINDIRSCRIPTS)

SUBDIRS = po

SCRIPTDIR = scripts
LANGDIR = po

BUILDFILES = \
	$(NAME).spec.in \
	Makefile

SCRIPTLIST = $(addprefix $(SCRIPTDIR)/,$(SCRIPTNAMES))

LANGFILES = \
	$(LANGDIR)/Makefile \
	$(LANGDIR)/$(NAME).pot \
	$(LANGDIR)/*.po

TARNAME = $(NAME)-$(VERSION)

SPLOG=$(shell which splog)

all:
	@for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done

install:
	@echo
	@echo '                     ***Installation START***'
	@echo
	@mkdir -p $(ROOTBINDIR)
	@echo 'Created directory $(ROOTBINDIR)'
	@mkdir -p $(BINDIR)
	@echo 'Created directory $(BINDIR)'
	@mkdir -p $(SHAREDIR)
	@echo 'Created directory $(SHAREDIR)'
	@install -m 755 $(addprefix $(SCRIPTDIR)/,$(BINDIRSCRIPTS)) $(BINDIR)
	@echo 'Installed $(BINDIRSCRIPTS) to $(BINDIR)'
	@install -m 644 $(addprefix $(SCRIPTDIR)/,$(ROOTBINDIRSCRIPTS)) $(ROOTBINDIR)
	@echo 'Installed $(ROOTBINDIRSCRIPTS) to $(ROOTBINDIR)'
	@install -m 644 $(addprefix $(SCRIPTDIR)/,$(SHAREDIRSCRIPTS)) $(SHAREDIR)
	@echo 'Installed $(SHAREDIRSCRIPTS) to $(SHAREDIR)'
	@for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done
	@echo
	@echo '                     ***Installation END***'
	@echo

clean:
	@for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done
	@rm -f $(TARNAME).tar.xz
	@rm -f $(NAME).spec
	@rm -rf $(TARNAME)
	@find -name '*~' -exec rm {} \;
	@echo
	@echo "Cleaning complete"
	@echo

$(NAME).spec: $(NAME).spec.in
	@sed -n "1,$$[$$(grep -n "@FILE_LIST@" $(NAME).spec.in | cut -f1 -d:)-1]p"  $< | \
        sed 's/@VERSION@/$(VERSION)/g' | sed 's/@RELEASE@/$(RELEASE)/g' > $@
	@for i in $(BINDIRSCRIPTS); do \
		echo "%{_bindir}/$$i" >> $@ ; \
	done
	@for i in $(ROOTBINDIRSCRIPTS); do \
		echo "/bin/$$i" >> $@ ; \
	done
	@echo %dir %{_datadir}/%{name} >> $@
	@for i in $(SHAREDIRSCRIPTS); do \
		echo "%{_datadir}/%{name}/$$i" >> $@ ; \
	done
	@sed -n "$$[$$(grep -n "@FILE_LIST@" $(NAME).spec.in | cut -f1 -d:)+1],\$$p" $< >> $@
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

lang-update: clean
	@for d in $(LANGDIR); do ( cd $$d ; rm -f *.pot ) ; done
	@for d in $(LANGDIR); do ( cd $$d ; make update_n_merge ) ; done
	@echo
	@echo "All lang files are now up to date"
	@echo

dist: spec
	@mkdir -p $(TARNAME)/$(LANGDIR)
	@mkdir -p $(TARNAME)/$(SCRIPTDIR)
	@cp $(BUILDFILES) $(TARNAME)/
	@cp $(SCRIPTLIST) $(TARNAME)/$(SCRIPTDIR)
	@cp $(LANGFILES) $(TARNAME)/$(LANGDIR)/

tar: dist
	@tar -Jcf $(TARNAME).tar.xz $(TARNAME)
	@echo
	@echo "$(TARNAME).tar.xz generated in $$PWD"
	@echo

version:
	@echo
	@echo "$(NAME), $(VERSION)-$(RELEASE)"
	@echo


maintenance-help:
	@echo
	@echo '                  ********************************'
	@echo '                  ******PKGUTILS MAINTENANCE******'
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
