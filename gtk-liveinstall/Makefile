NAME = gtk-liveinstall
VERSION = 0.9.2

DESTDIR = /
DATADIR = $(DESTDIR)/usr/share
ICONSDIR = $(DATADIR)/icons
SBINDIR = $(DESTDIR)/usr/sbin
BINDIR = $(DESTDIR)/usr/bin
LOCALEDIR = $(DESTDIR)/usr/share/locale

SUBDIRS = po

DESKTOPINFILES = ${wildcard *.desktop.in}
DESKTOPFILES = ${patsubst %.in, %, $(DESKTOPINFILES)}

all: $(DESKTOPFILES) $(NAME)
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done

%.desktop: %.desktop.in
	intltool-merge po -d -u $< $@

$(NAME): $(NAME).in
	cat $(NAME).in | sed -e 's,@VERSION@,$(VERSION),g' | \
	sed -e 's,@APPNAME@,$(NAME),g' > $(NAME)

clean:
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done
	rm -f $(DESKTOPFILES)
	rm -f $(NAME)

install: all
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done
	install -d $(SBINDIR)
	install -m755 $(NAME) $(SBINDIR)
	install -d $(DATADIR)/$(NAME)
	install -m644 message $(DATADIR)/$(NAME)
	install -d $(ICONSDIR)
	install -m644 *.png $(ICONSDIR)
	install -d $(DATADIR)/applications
	install -m644 *.desktop $(DATADIR)/applications