include Rules.mk

all: prep

version:
	@echo "$(PKGNAME), $(TRANSLATEMEVER)-$(TRANSLATEMEREL)"

$(DBNAME): $(DBNAME).in
	$(shell ./gen_database.sh)

$(SCRIPTNAME).in: $(SCRIPTNAME).in.in
	$(CAT) $(SCRIPTNAME).in.in | \
		$(SED) -e 's,@PKGNAME@,$(PKGNAME),g' \
			>$(SCRIPTNAME).in

gen_script.sh: gen_script.sh.in
	$(CAT) gen_script.sh.in | \
		$(SED) -e 's,@SCRIPTNAME@,$(SCRIPTNAME),g' \
			>gen_script.sh
	$(CHMOD) 755 gen_script.sh
	
$(SCRIPTNAME): $(SCRIPTNAME).in $(DBNAME) gen_script.sh
	$(shell ./gen_script.sh)

$(PKGNAME).spec.in: $(SCRIPTNAME)
	$(CAT) $(PKGNAME).spec.in.in | \
		$(SED) -e 's,@PKGNAME@,$(PKGNAME),g' | \
		$(SED) -e 's,@SCRIPTNAME@,$(SCRIPTNAME),g' | \
		$(SED) -e 's,@TRANSLATEMEVER@,$(TRANSLATEMEVER),g' | \
		$(SED) -e 's,@TRANSLATEMEREL@,$(TRANSLATEMEREL),g' | \
		$(SED) -e 's,@SPECDATE@,$(SPECDATE),g' | \
		$(SED) -e 's,@ARCHIVEVER@,$(ARCHIVEVER),g' \
			>$(PKGNAME).spec.in

$(PKGNAME).spec: $(PKGNAME).spec.in
	$(shell ./gen_spec.sh)

spec: $(PKGNAME).spec

prep: $(PKGNAME).spec
	$(MKDIR) -p $(DISTDIR)/$(LANGPACKSDIR)
	$(CP) -f $(SCRIPTNAME) $(DISTDIR)
	$(CP) -f $(PKGNAME).spec $(DISTDIR)
	$(CP) -f $(LANGPACKSDIST) $(DISTDIR)/$(LANGPACKSDIR)

install:
	$(MKDIR) -p $(DESTDIR)$(SHAREDIR)
	$(MKDIR) -p $(DESTDIR)$(BINDIR)
	$(INSTALL) -m 644 $(DISTDIR)/$(LANGPACKSDIR)/*.tar.xz $(DESTDIR)$(SHAREDIR)
	$(INSTALL) -m 755 $(DISTDIR)/$(SCRIPTNAME) $(DESTDIR)$(BINDIR)

install-doc:
	$(MKDIR) -p $(DESTDIR)$(DOCDIR)
	$(CP) -f $(DOCDIST) $(DOCDIR)

clean:
	$(RM) -rf $(TRANSLATEMEDIST)
	$(RM) -rf $(DISTDIR)
	$(RM) -f $(DBNAME)
	$(RM) -f $(SCRIPTNAME).in
	$(RM) -f $(SCRIPTNAME)
	$(RM) -f $(PKGNAME).spec.in
	$(RM) -f $(PKGNAME).spec
	$(RM) -f gen_script.sh

dist: prep
	$(MKDIR) -p $(TRANSLATEMEDIST)/$(LANGPACKSDIR)
	$(CP) $(DOCDIST) $(TRANSLATEMEDIST)
	$(CP) $(BUILDDIST) $(TRANSLATEMEDIST)
	$(CP) -f $(LANGPACKSDIST) $(TRANSLATEMEDIST)/$(LANGPACKSDIR)
	$(TAR) --xz -cvf $(DISTDIR)/$(TRANSLATEMEDIST).tar.xz $(TRANSLATEMEDIST)
	$(MD5SUM) $(DISTDIR)/$(TRANSLATEMEDIST).tar.xz >$(DISTDIR)/$(TRANSLATEMEDIST).tar.xz.md5
	$(RM) -rf $(TRANSLATEMEDIST)

rpm: dist
	$(RPMBUILD) -ta $(DISTDIR)/$(TRANSLATEMEDIST).tar.xz --clean
