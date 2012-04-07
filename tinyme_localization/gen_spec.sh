#!/bin/sh

# Before proceeding, it cleans up the any previous generated file.
rm -f tinyme_localization.spec

# It finds the position of the tags in tinyme_localization.spec.in and how many
# languages are supported.
c=1
for tagname in @@DATAPACKAGES@@ @@FILESDATAPKGS@@; do
	position[$c]=$(grep -n "$tagname" tinyme_localization.spec.in|cut -f1 -d:)
	((c++))
done

numberoflines=$(grep -c ".*" lang_database)

# The generation of translateme starts here
touch tinyme_localization.spec

sed -n "1,$[${position[1]}-1]p" tinyme_localization.spec.in >> tinyme_localization.spec

c=1
while [ $c -le $numberoflines ]; do
	langcode=$(sed -n "${c}p" lang_database|cut -d';' -f1)
	extlang=$(sed -n "${c}p" lang_database|cut -d';' -f2)
	echo -e "%package $langcode
Group:		System/Internationalization
Summary: 	Data for TinyMe localization in $extlang
Requires:	tinyme_localization-common

%description $langcode
It provides data for localization of a fresh TinyMe install in $extlang.
" \
	>> tinyme_localization.spec
	((c++))
done

sed -n "$[${position[1]}+1],$[${position[2]}-1]p" tinyme_localization.spec.in >> tinyme_localization.spec

c=1
while [ $c -le $numberoflines ]; do
	langcode=$(sed -n "${c}p" lang_database|cut -d';' -f1)
	echo -e "%files $langcode
%defattr(-,root,root,-)
%{_datadir}/%{name}/$langcode.tar.xz
" \
	>> tinyme_localization.spec
	((c++))
done

sed -n "$[${position[2]}+1],\$p" tinyme_localization.spec.in >> tinyme_localization.spec
