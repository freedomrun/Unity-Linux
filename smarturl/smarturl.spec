%define name smarturl
%define version 1.2
%define release %mkrel 1


Summary:	smart protocol handler allowing web-based one-click package installing
Summary(cs):	Obsluhovač protokolu smart umožňující webovou instalaci balíčků jedním klikem
Name:		%{name}
Version:	%{version}
Release: 	%{release}
URL:		http://www.pclinuxos.com/
Source:		%{name}-%{version}.tar.bz2
Group:		System/Base
License:	GPL
BuildRoot:	%_tmppath/%{name}-%{version}-%{release}-root
BuildArch:	noarch
Requires:	smart
Requires:	smart-gui
BuildRequires:	gettext

%description
smart protocol handler allowing web-based one-click package installing.
Allows URIs in form: 'smart:[//]install=<package>[,package[,...]]'.
Works with Firefox, Konqueror and Opera.

%description -l cs
Obsluhovač protokolu smart umožňující webovou instalaci balíčků jedním klikem.
Umožňuje používat URI ve formě: 'smart:[//]install=<balíček>[,balíček[,...]].
Funguje s Firefoxem, Konquerorem a Operou.

%prep

%setup -q

%build

%install
rm -fr %buildroot/
make install prefix=%buildroot
%find_lang %{name}

%clean
rm -fr %buildroot

%files -f %{name}.lang
%defattr(-,root,root,-)
%_bindir/smarturl
%defattr(0644,root,root,0755)
%_sysconfdir/gconf/schemas/smarturl.schemas
%_datadir/services/smarturl.protocol

%post
if [ "$1" == "1" ]
then
# Gnome & Firefox 3
    %post_install_gconf_schemas smarturl
    
# Firefox 2
    for FIREFOX_INSTALL in `find /usr/lib/ -path "/usr/lib/firefox*/greprefs"`
    do
	cat <<EOT > $FIREFOX_INSTALL/smarturl.js
pref("network.protocol-handler.app.smart", "%_bindir/smarturl");
pref("network.protocol-handler.warn-external.smart", false);
EOT
    done

# Opera
    if [ -f /etc/opera6rc ]
    then
	grep "^[^;].*smarturl" /etc/opera6rc >/dev/null 2>&1
	if [ "$?" != "0" ]
	then
	    cat <<EOT3 >> /etc/opera6rc
[Trusted Protocols]
smart="0,0,"%_bindir/smarturl""
EOT3
	fi
    fi
fi

%preun
if [ "$1" == "0" ]
then
# Gnome & Firefox 3
    %preun_uninstall_gconf_schemas smarturl
    
# Firefox 2
    for FIREFOX_INSTALL in `find /usr/lib/ -path "/usr/lib/firefox*/greprefs"`
    do
	rm -f $FIREFOX_INSTALL/smarturl.js 2>/dev/null
    done

# Opera
    if [ -f /etc/opera6rc ]
    then
	grep "^[^;].*smarturl" /etc/opera6rc >/dev/null 2>&1
	if [ "$?" == "0" ]
	then
	    sed -i.old -e '/\[Trusted Protocols\]/d; /smart="0,0,".*smarturl""/d' /etc/opera6rc
	fi
    fi
fi

%changelog
* Tue Jun 30 2009 David Smid <david@smidovi.eu> 1.2-1-unity2009
- Added support for URIs with two slashes (smart://) to make smart URIs usable in wiki
- Added ability to remove package
- Added smart-gui dependency

* Thu Apr 02 2009 David Smid <david@smidovi.eu> 1.1-2unity2009
- Due to stupid mistake registering/unregistering for Konqueror and Opera didn't work
- smarturl.protocol added to file list

* Wed Apr 01 2009 David Smid <david@smidovi.eu> 1.1-1unity2009
- Registering/unregistering code moved from script to SPEC
- Added support for Gnome & Firefox 3

* Wed Oct 08 2008 David Smid <david@smidovi.eu> 1.0-1pclos2007
- Initial build
