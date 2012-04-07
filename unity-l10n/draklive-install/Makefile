NAME = draklive-install
localedir = ${prefix}/share/locale
PL_FILES = ../$(NAME) $(shell find .. -type f -name "*pm")

MERGE_POFILES = $(shell for i in ../../../perl-install/share/po/*.po; do basename $$i; done)
POFILES = $(wildcard *.po)
MOFILES = $(POFILES:%.po=%.mo)
LANGS = $(POFILES:%.po=%)

all: $(NAME).pot $(POFILES) $(MOFILES)

%.mo: %.po
	msgfmt -o $@ $<

update_n_merge: $(NAME).pot merge

merge:
	for n in $(MERGE_POFILES); do \
		echo "Merging $$n"; \
		msgmerge "$$n" $(NAME).pot > "$$n"t; \
		mv -f "$$n"t "$$n"; \
	done

$(NAME).pot:
	intltool-update --gettext-package desktopstuff --pot
	perl_checker -q --generate-pot $(NAME)_tmp.pot $(PL_FILES)
	[ ! -e $(NAME)_tmp.pot ] || msgcat --use-first $(NAME)_tmp.pot desktopstuff.pot > $@
	rm -f desktopstuff.pot $(NAME)_tmp.pot 

install: all
	for l in $(LANGS); do \
		install -d $(localedir)/$$l/LC_MESSAGES; \
		install -m 644 $$l.mo $(localedir)/$$l/LC_MESSAGES/$(NAME).mo; \
	done

clean:
	rm -rf *.mo $(POFILES:%=%t)
	find -name '*~' -exec rm {} \;