# Adapted from Rules.mk in mklivecd project

# Version identifiers: These should only be changed by the release
# manager as part of making a new release
PKGNAME=tinyme_localization
SCRIPTNAME=translateme
DBNAME=lang_database
MAJORVER=0
MINORVER=1
PATCHVER=0
RELVER=1
CVSVER=yes

# Automatic variable updates, leave alone
TRANSLATEMEVER=$(MAJORVER).$(MINORVER).$(PATCHVER)
ifeq "$(CVSVER)" "yes"
	CVSDATE=$(shell date +%Y%m%d)
	TRANSLATEMEREL=0.$(CVSDATE).$(RELVER)
	ARCHIVEVER=$(TRANSLATEMEVER)-$(CVSDATE)
else
	TRANSLATEMEREL=$(RELVER)
	ARCHIVEVER=$(TRANSLATEMEVER)
endif
SPECDATE=$(shell LC_ALL=C date +"%a %b %e %Y")

# Internal directories: don't edit
DISTDIR=dist
LANGPACKSDIR=langpacks
TRANSLATEMEDIST=$(PKGNAME)-$(ARCHIVEVER)

# Destination directories: you can change the locations for your site either
# here or as an override on the make command-line (preferred)
DESTDIR=
PREFIX=/usr
SBINPREFIX=$(PREFIX)
BINDIR=$(PREFIX)/bin
LIBDIR=$(PREFIX)/lib/$(PKGNAME)
SHAREDIR=$(PREFIX)/share/$(PKGNAME)
DOCDIR=$(PREFIX)/share/doc/$(PKGNAME)-$(TRANSLATEMEVER)
SBINDIR=$(SBINPREFIX)/sbin
RCDIR=$(SHAREDIR)/init.d
DESKTOPDIR=$(PREFIX)/share/applications
LOCALEDIR=$(PREFIX)/share/locale

# Utility programs: you can change the locations for your site either
# here or as an override on the make command-line (preferred)
BZIP2=$(shell which bzip2)
CAT=$(shell which cat)
CP=$(shell which cp)
GZIP=$(shell which gzip)
CHMOD=$(shell which chmod)
INSTALL=$(shell which install)
MD5SUM=$(shell which md5sum)
MKDIR=$(shell which mkdir)
LN=$(shell which ln)
RM=$(shell which rm)
RPMBUILD=$(shell which rpmbuild)
SED=$(shell which sed)
TAR=$(shell which tar)
TOUCH=$(shell which touch)

# langpacks/ content
LANGPACKS=${wildcard $(LANGPACKSDIR)/*.tar.xz}

# these are files in the root dir
DOCDIST=\
	AUTHORS \
	CHANGELOG \
	COPYING \
	README
	
BUILDDIST=\
	Makefile \
	Rules.mk \
	$(SCRIPTNAME).in.in \
	$(PKGNAME).spec.in.in \
	$(DBNAME).in \
	gen_database.sh \
	gen_script.sh.in \
	gen_spec.sh \
	$(PKGNAME).spec

# these are files in the langpack dir
LANGPACKSDIST=\
	$(LANGPACKS)
