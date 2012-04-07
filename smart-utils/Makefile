NAME=smart-utils

TEXTDOMAIN   = ${NAME}

MSGFMT       = /usr/bin/msgfmt


bindir=/usr/bin
sbindir=/usr/sbin
datadir=/usr/share
localedir=$(datadir)/locale
sysconfdir=/etc
drakdir=$(prefix)/lib/libDrakX


INSTLOCALES := ${patsubst po/%.po,%,${wildcard po/*.po}}
TMPPOS := ${wildcard po/*.po.tmp}
POS := ${wildcard po/*.po}
TMPPOS := ${patsubst %,%.tmp,${POS}}
MOS := ${patsubst %.po,%.mo,${POS}}

.PHONY: all clean installdirs install ${INSTLOCALES}

all: ${MOS}

${MOS}: po/%.mo : po/%.po
	$(MSGFMT) -o $@ $<

installdirs:
	install -d -m 0755 $(sbindir)
	install -d -m 0755 $(sysconfdir)/smart/channelsets
	install -d -m 0755 $(sysconfdir)/sysconfig
	install -d -m 0755 $(drakdir)


${INSTLOCALES}: %: po/%.mo
	install -d -m 755 $(localedir)/$@/LC_MESSAGES/
	install -m 644 $< $(localedir)/$@/LC_MESSAGES/${TEXTDOMAIN}.mo

install: all installdirs ${INSTLOCALES}
	install -m 0755 smart-update-channels	$(sbindir)/
	install -m 0755 smart-setup-auto	$(sbindir)/
	install -m 0755 smart-setup		$(sbindir)/
	install -m 0755 smart.pm		$(drakdir)/
	install -m 0755 smart-setup-lock	$(sysconfdir)/sysconfig/

clean:
	rm -f po/*.mo
