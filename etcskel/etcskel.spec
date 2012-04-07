Summary:	Unity Linux default files for new users' home directories
Name:		etcskel
Version:	1.66
Release:	1
License:	Public Domain
Group:		System/Base
# get the source from our svn repository
Source0:	%{name}-%{version}.tar.xz

Requires:	bash
BuildArch:	noarch

%description
The etcskel package is part of the basic Unity Linux system.

Etcskel provides the /etc/skel directory's files. These files are then placed
in every new user's home directory when new accounts are created.

%prep
%setup -q

%install
#Remove any .svn folders
find . -name .svn -print0 | xargs -0 rm -rvf
make install RPM_BUILD_ROOT=%{buildroot}

%files
%doc ChangeLog
%config(noreplace) /etc/skel/

%changelog
* Tue Feb 14 2012 mdawkins <mattydaw@gmail.com> 1.66-1-unity2012.0
- new version 1.66
- prep'ing files for new pcmanfm
- adding gvolwheel to panel for sound

* Mon Jan 17 2011 mdawkins <mattydaw@gmail.com> 1.65-1-unity2011
- new version 1.65
- changed net_applet to nm-applet

* Wed Dec 01 2010 JMiahMan <JMiahMan at Unity-Linux dot org> 1.64-4-synergy2010
- Rebuild

* Mon Nov 22 2010 JMiahMan <JMiahMan at Unity-Linux dot org> 1.64-3-synergy2010
- Fix Typos in Changelog

* Sun Nov 21 2010 JMiahMan <JMiahMan at Unity-Linux dot org> 1.64-2-synergy2010
- Fix Build Issues

* Sat Nov 20 2010 JMiahMan <JMiahMan at Unity-Linux dot org" 1.64-1-synergy2010
- Branched from Mandriva, no in Unity SVN
- Bump to 1.64 as we're now including configuration files for Unity

* Fri Apr 17 2009 mdawkins <mattydaw@gmail.com> 1.63-20unity2009
- just rebuild for unity
- at some point we need to move on from this

* Fri Nov 10 2006 Texstar <texstar@houston.rr.com> 1.63-19pclos2007
- Build for PCLinuxOS 2007
