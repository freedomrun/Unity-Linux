NAME = draklive-install

prefix = /usr
localedir = $(DESTDIR)${prefix}/share/locale

PL_FILES = ../$(NAME) $(shell find .. -type f -name "*pm")

POFILES = $(wildcard *.po)
MOFILES = $(POFILES:%.po=%.mo)
LANGS = $(POFILES:%.po=%)

all: $(NAME).pot $(POFILES) $(MOFILES)

%.mo: %.po
	@msgfmt -o $@ $<
	@echo "$@ generated in $$PWD"

update_n_merge: $(NAME).pot merge

merge:
	@for n in $(POFILES); do \
		echo "Merging $$n"; \
		msgmerge "$$n" $(NAME).pot > "$$n"t; \
		mv -f "$$n"t "$$n"; \
	done
	@echo
	@echo "All catalogs updated to current template"
	@echo 

$(NAME).pot:
	@intltool-update --gettext-package desktopstuff --pot
	@perl_checker -q --generate-pot $(NAME)_tmp.pot $(PL_FILES)
	@[ ! -e $(NAME)_tmp.pot ] || msgcat --use-first $(NAME)_tmp.pot desktopstuff.pot > $@
	@rm -f desktopstuff.pot $(NAME)_tmp.pot
	@echo
	@echo "New $(NAME).pot generated from $(PL_FILES)"
	@echo 

install: all
	@echo
	@for l in $(LANGS); do \
		install -d $(localedir)/$$l/LC_MESSAGES; \
		install -m 644 $$l.mo $(localedir)/$$l/LC_MESSAGES/$(NAME).mo 2> /dev/null; \
		echo "Installed $$l.mo to $(localedir)/$$l/LC_MESSAGES"; \
	done
	@echo

clean:
	@rm -rf *.mo $(POFILES:%=%t)
	@find -name '*~' -exec rm {} \;
	@echo
	@echo "Cleaning complete"
	@echo