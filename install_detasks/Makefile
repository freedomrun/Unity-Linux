NAME = install_detasks

DESTDIR = /
SYSCONFDIR = $(DESTDIR)/etc
SKELDIR = $(SYSCONFDIR)/skel
DESKTOPTDIR = $(SKELDIR)/Desktop/Install\ Desktop\ Environments/
DATADIR = $(DESTDIR)/usr/share
ICONSDIR = $(DATADIR)/icons
SBINDIR = $(DESTDIR)/usr/sbin
BINDIR = $(DESTDIR)/usr/bin
LOCALEDIR = $(DESTDIR)/usr/share/locale

SUBDIRS = po

ICONFILES = ${wildcard icons/*.png}
DESKTOPINFILES = ${wildcard applications/*.desktop.in}
DESKTOPFILES = ${patsubst %.in, %, $(DESKTOPINFILES)}

all: $(DESKTOPFILES)
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done

applications/%.desktop: applications/%.desktop.in
	intltool-merge po -d -u $< $@

clean:
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done
	rm -f $(DESKTOPFILES)

install: all
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done
	install -d $(SBINDIR)
	install -m755 $(NAME) $(SBINDIR)
	install -d $(ICONSDIR)
	install -m644 $(ICONFILES) $(ICONSDIR)
	install -d $(DESKTOPTDIR)
	install -m644 $(DESKTOPFILES) $(DESKTOPTDIR)
