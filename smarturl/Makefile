PACKAGE=smarturl
VERSION := $(shell rpm -q --qf '%{version}\n' --specfile $(PACKAGE).spec | head -1)
RELEASE := $(shell rpm -q --qf '%{release}\n' --specfile $(PACKAGE).spec | head -1)

TEXTDOMAIN   = ${PACKAGE}

RPM          = /usr/bin/rpm

PRODUCT      = "PCLinuxOS 2007"
export PRODUCT

MSGFMT       = /usr/bin/msgfmt


bindir=/usr/bin
configdir=/etc
sbindir=/usr/sbin
datadir=/usr/share
localedir=$(datadir)/locale


INSTLOCALES := ${patsubst l10n/%.po,%,${wildcard l10n/*.po}}
POS := ${wildcard l10n/*.po}
MOS := ${patsubst %.po,%.mo,${POS}}

.PHONY: all clean installdirs install cleandist distdir localcopy tar rpm rpm-install ${INSTLOCALES}

all: ${MOS}

${MOS}: l10n/%.mo : l10n/%.po
	$(MSGFMT) -o $@ $<

installdirs:
	install -d -m 0755 $(prefix)/$(bindir)
	install -d -m 0755 $(prefix)/$(configdir)/gconf/schemas/
	install -d -m 0755 $(prefix)/$(datadir)/services/

${INSTLOCALES}: %: l10n/%.mo
	install -d -m 755 $(prefix)/$(localedir)/$@/LC_MESSAGES/
	install -m 644 $< $(prefix)/$(localedir)/$@/LC_MESSAGES/${TEXTDOMAIN}.mo

install: all installdirs ${INSTLOCALES}
	install -m 0755 ${PACKAGE} $(prefix)/$(bindir)/${PACKAGE}
	install -m 0644 ${PACKAGE}.schemas $(prefix)/$(configdir)/gconf/schemas/${PACKAGE}.schemas
	install -m 0644 ${PACKAGE}.protocol $(prefix)/$(datadir)/services/${PACKAGE}.protocol


clean:
	rm -f l10n/*.mo
	rm -f l10n/.intltool-merge-cache

cleandist:
	rm -rf $(PACKAGE)-$(ARCHIVEVER) $(PACKAGE)-$(VERSION).tar.bz2

distdir:
	if [ ! -d $(PACKAGE)-$(VERSION) ]; then mkdir $(PACKAGE)-$(VERSION); fi

localcopy: clean distdir
	tar cp --exclude=.svn --exclude=$(PACKAGE)-$(VERSION) --exclude=*.tar.bz2  . | tar xp -C $(PACKAGE)-$(VERSION)
	
tar: localcopy cleandist
	tar cjvf $(PACKAGE)-$(VERSION).tar.bz2 $(PACKAGE)-$(VERSION)
	rm -rf $(PACKAGE)-$(VERSION)

rpm: tar
	rpmbuild -ta $(PACKAGE)-$(VERSION).tar.bz2
