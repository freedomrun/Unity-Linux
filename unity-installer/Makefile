NAME = draklive-install
ALTNAME = unity-installer
VERSION = 1.3
RELEASE = 11

SUBDIRS = po
LANGDIR = po

###############First boot options###############
FINISH_INSTALL=yes
LICENSE=no
LANGUAGE=no
KEYBOARD=no
COUNTRY=no
TIMEZONE=no
NETWORK=no
AUTHENTICATION=no
USERS=with_root
USER_AUTOLOGIN_FIRST=no
GLX=no
SMART=no
################################################

DESKTOPINFILES = ${wildcard *.desktop.in}
DESKTOPFILES = ${patsubst %.in, %, $(DESKTOPINFILES)}

BUILDFILES = \
	$(ALTNAME).spec.in \
	Makefile

ICONFILES = \
	$(NAME)-16.png \
	$(NAME)-32.png \
	$(NAME)-48.png

GRAPHICSFILES = \
	Unity-format.png \
	Unity-install.png \
	Unity-wizard.png

LANGFILES = \
	$(LANGDIR)/Makefile \
	$(LANGDIR)/POTFILES.in \
	$(LANGDIR)/$(NAME).pot \
	$(LANGDIR)/*.po

TARNAME = $(ALTNAME)-$(VERSION)

##########################################################
DESTDIR =
prefix = /usr
SBINPREFIX = $(prefix)
BINDIR = $(prefix)/bin
LIBDIR = $(prefix)/lib/$(ALTNAME)
SHAREDIR = $(prefix)/share/$(ALTNAME)
ICONSDIR = $(prefix)/share/icons
MICONSDIR = $(prefix)/share/icons/mini
LICONSDIR = $(prefix)/share/icons/large
DOCDIR = $(prefix)/share/doc/$(ALTNAME)-$(VERSION)
SBINDIR = $(SBINPREFIX)/sbin
RCDIR = $(SHAREDIR)/init.d
DESKTOPDIR = $(prefix)/share/applications
LOCALEDIR = $(prefix)/share/locale

LIBDRAKXPIXDIR = $(prefix)/share/libDrakX/pixmaps
###########################################################

SPLOG=$(shell which splog)

all: $(NAME) $(DESKTOPFILES)
	@for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done

%.desktop: %.desktop.in
	@intltool-merge po -d -u $< $@
	@echo "$@ generated in $$PWD"
	@echo

$(NAME): $(NAME).in
	@cat $< | \
	sed -e 's,@FINISH_INSTALL@,$(FINISH_INSTALL),g' | \
	sed -e 's,@LICENSE@,$(LICENSE),g' | \
	sed -e 's,@LANGUAGE@,$(LANGUAGE),g' | \
	sed -e 's,@KEYBOARD@,$(KEYBOARD),g' | \
	sed -e 's,@COUNTRY@,$(COUNTRY),g' | \
	sed -e 's,@TIMEZONE@,$(TIMEZONE),g' | \
	sed -e 's,@NETWORK@,$(NETWORK),g' | \
	sed -e 's,@AUTHENTICATION@,$(AUTHENTICATION),g' | \
	sed -e 's,@USERS@,$(USERS),g' | \
	sed -e 's,@USER_AUTOLOGIN_FIRST@,$(USER_AUTOLOGIN_FIRST),g' | \
	sed -e 's,@GLX@,$(GLX),g' | \
	sed -e 's,@SMART@,$(SMART),g' > $(NAME)
	@echo
	@echo "draklive-install generated with the following 1st boot options:"
	@echo
	@echo "FINISH_INSTALL=$(FINISH_INSTALL)"
	@echo "LICENSE=$(LICENSE)"
	@echo "LANGUAGE=$(LANGUAGE)"
	@echo "KEYBOARD=$(KEYBOARD)"
	@echo "COUNTRY=$(COUNTRY)"
	@echo "TIMEZONE=$(TIMEZONE)"
	@echo "NETWORK=$(NETWORK)"
	@echo "AUTHENTICATION=$(AUTHENTICATION)"
	@echo "USERS=$(USERS)"
	@echo "USER_AUTOLOGIN_FIRST=$(USER_AUTOLOGIN_FIRST)"
	@echo "GLX=$(GLX)"
	@echo "SMART=$(SMART)"
	@echo

install: 
	@echo
	@echo '                     ***Installation START***'
	@echo
	@mkdir -p $(DESTDIR)$(SHAREDIR)
	@echo 'Created directory $(DESTDIR)$(SHAREDIR)'
	@mkdir -p $(DESTDIR)$(DESKTOPDIR)
	@echo 'Created directory $(DESTDIR)$(DESKTOPDIR)'
	@mkdir -p $(DESTDIR)$(ICONSDIR)
	@echo 'Created directory $(DESTDIR)$(ICONSDIR)'
	@mkdir -p $(DESTDIR)$(MICONSDIR)
	@echo 'Created directory $(DESTDIR)$(MICONSDIR)'
	@mkdir -p $(DESTDIR)$(LICONSDIR)
	@echo 'Created directory $(DESTDIR)$(LICONSDIR)'
	@mkdir -p $(DESTDIR)$(LIBDRAKXPIXDIR)
	@echo 'Created directory $(DESTDIR)$(LIBDRAKXPIXDIR)'
	@install -m 755 $(NAME) $(DESTDIR)$(SHAREDIR)
	@echo 'Installed $(NAME) to $(DESTDIR)$(SHAREDIR)'
	@install -m 644 $(DESKTOPFILES) $(DESTDIR)$(DESKTOPDIR)
	@echo 'Installed desktop file to $(DESTDIR)$(DESKTOPDIR)'
	@install -m 644 $(NAME)-16.png $(DESTDIR)$(MICONSDIR)/$(ALTNAME).png
	@install -m 644 $(NAME)-32.png $(DESTDIR)$(ICONSDIR)/$(ALTNAME).png
	@install -m 644 $(NAME)-48.png $(DESTDIR)$(LICONSDIR)/$(ALTNAME).png
	@echo 'Installed icons'
	@install -m 644 $(GRAPHICSFILES) $(DESTDIR)$(LIBDRAKXPIXDIR)
	@echo 'Installed graphics'
	@for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done
	@echo
	@echo '                     ***Installation END***'
	@echo

check: $(NAME)
	@perl -cw $(NAME)

clean:
	@rm -f $(NAME)
	@rm -f $(ALTNAME).spec
	@rm -f $(DESKTOPFILES)
	@rm -f $(TARNAME).tar.xz
	@rm -rf $(TARNAME)
	@find -name '*~' -exec rm {} \;
	@for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done
	@echo
	@echo "Cleaning complete"
	@echo

$(ALTNAME).spec: $(ALTNAME).spec.in
	@cat $< | sed 's/@VERSION@/$(VERSION)/g' | sed 's/@RELEASE@/$(RELEASE)/g' | \
	sed 's/@PACKAGER@/$(pname) <$(pmail)>/g' > $@
	@echo
	@echo "$(ALTNAME).spec generated in $$PWD"
	@echo

spec: $(ALTNAME).spec

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

	@$(SPLOG) -p "$(pname) <$(pmail)>" $(taglist) $(ALTNAME).spec
	@echo
	@echo "The %changelog section of $(NAME).spec has been updated with the provided info."
	@echo "Run 'make spec-merge' if you want to merge it back into the spec template, but first check it out!"
	@echo


spec-merge: spec
	@head -n $$(($$(grep -n "%changelog" $(ALTNAME).spec.in | cut -f1 -d:)-1)) $(ALTNAME).spec.in > temp.spec
	@tail -n $$(($$(wc -l < $(ALTNAME).spec)-$$(grep -n "%changelog" $(ALTNAME).spec | cut -f1 -d:)+1)) $(ALTNAME).spec >> temp.spec
	@mv -f temp.spec $(ALTNAME).spec.in
	@echo
	@echo "The %changelog section of $(ALTNAME).spec has been merged back into the spec template."
	@echo

lang-update: clean
	@for d in $(LANGDIR); do ( cd $$d ; rm -f *.pot ) ; done
	@for d in $(LANGDIR); do ( cd $$d ; make update_n_merge ) ; done
	@echo
	@echo "All lang files are now up to date"
	@echo

dist: spec
	@mkdir -p $(TARNAME)/$(LANGDIR)
	@cp $(NAME).in $(TARNAME)/
	@cp $(BUILDFILES) $(TARNAME)/
	@cp $(ICONFILES) $(TARNAME)/
	@cp $(GRAPHICSFILES) $(TARNAME)/
	@cp $(DESKTOPINFILES) $(TARNAME)/
	@cp $(LANGFILES) $(TARNAME)/$(LANGDIR)/

tar: dist
	@tar -Jcf $(TARNAME).tar.xz $(TARNAME)
	@echo
	@echo "$(TARNAME).tar.xz generated in $$PWD"
	@echo

version:
	@echo
	@echo "$(ALTNAME), $(VERSION)-$(RELEASE)"
	@echo

maintenance-help:
	@echo
	@echo '                  ********************************'
	@echo '                  **UNITY-INSTALLER  MAINTENANCE**'
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
	@echo ' Changelog into the spec template $(ALTNAME).spec.in'
	@echo ' In order to do so, use the following command:'
	@echo
	@echo ' make spec-merge'
	@echo
	@echo ' Please, note that you must edit $(ALTNAME).spec.in directly, if you'
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
