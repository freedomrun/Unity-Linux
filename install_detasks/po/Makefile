# Installation directory
LOCALEDIR = $(DESTDIR)/usr/share/locale

PGOAL = install_detasks

# file to search translatable strings in
SH_FILE = ../install_detasks

POFILES = $(shell ls *.po)
MOFILES = $(POFILES:%.po=%.mo)
LANGS = $(POFILES:%.po=%)

GOALS = $(PGOAL).pot $(MOFILES)

all: $(GOALS)

install: all
	for l in $(LANGS); do \
		install -d $(LOCALEDIR)/$$l/LC_MESSAGES; \
		install -m 644 $$l.mo $(LOCALEDIR)/$$l/LC_MESSAGES/$(PGOAL).mo; \
	done

clean:
	rm -f *~ $(GOALS)

%.mo: %.po
	msgfmt -o $@ $<

$(PGOAL).pot: $(SH_FILE) POTFILES.in
	intltool-update --gettext-package desktopstuff --pot
	sed -e 's/gettext//' $(SH_FILE) > $(PGOAL)
	xgettext -k_ --language=Shell $(PGOAL) -o $(PGOAL)_tmp1.pot
	sed -e 's/\\\\/\\/g' $(PGOAL)_tmp1.pot > $(PGOAL)_tmp2.pot
	msgcat --use-first $(PGOAL)_tmp2.pot desktopstuff.pot > $(PGOAL).pot
	rm -f $(PGOAL) $(PGOAL)_tmp1.pot $(PGOAL)_tmp2.pot desktopstuff.pot

update_n_merge: $(PGOAL).pot merge

merge:
	@for n in $(POFILES); do \
		echo "Merging $$n"; \
		msgmerge -C "$$n" "$$n" $(PGOAL).pot > "$$n"t; \
		mv -f "$$n"t "$$n"; \
	done

