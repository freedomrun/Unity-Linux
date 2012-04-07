NAME = pkgutils

DESTDIR :=
prefix := /usr
LOCALEDIR := $(DESTDIR)${prefix}/share/locale

SH_FILES_DIR := ../scripts
SH_FILES := $(shell ls $(SH_FILES_DIR) --hide=old)
                                          

POFILES := $(wildcard *.po)
MOFILES := $(POFILES:%.po=%.mo)
LANGS := $(POFILES:%.po=%)

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
	@for i in $(SH_FILES); do \
		cat $(SH_FILES_DIR)/$$i | sed 's/\$$"//' > $$i.rmvthistag; \
	done
	@xgettext -k__ --add-comments=TRANSLATORS --sort-by-file --language=Shell -o tmp1.pot $(SH_FILES:%=%.rmvthistag)
	@sed -e 's/\\\\/\\/g' tmp1.pot > tmp2.pot
	@sed -e 's/\.rmvthistag//g' tmp2.pot > pkgutils.pot
	@rm -f *.rmvthistag
	@rm -f tmp{1,2}.pot
	@echo
	@echo "New $(NAME).pot generated from:"
	@printf "%s\t" $(SH_FILES)
	@echo; echo

install: all
	@echo
	@for l in $(LANGS); do \
		install -d $(LOCALEDIR)/$$l/LC_MESSAGES; \
		install -m 644 $$l.mo $(LOCALEDIR)/$$l/LC_MESSAGES/$(NAME).mo 2> /dev/null; \
		echo "Installed $$l.mo to $(LOCALEDIR)/$$l/LC_MESSAGES"; \
	done
	@echo

clean:
	@rm -rf *.mo $(POFILES:%=%t)
	@find -name '*~' -exec rm {} \;
	@echo
	@echo "Cleaning complete"
	@echo
