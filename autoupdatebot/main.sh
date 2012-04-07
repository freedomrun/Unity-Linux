#!/bin/bash
# (C) 2011 Kaleb Marshall
# This script is the main one in a set which checks for updated packages.
# There are generic scripts written for raw directories, SourceForge, and Google Code.
# Other places which may be coded in the future:
# Launchpad
# Suckless
# Github
# Some packages have to be specifically coded.
# Scripts may be written in any language, but bash would probably be the easiest
# as many of the generic functions have already been written.
# See the packages.list for more information.

source ./generic_functions.sh

echo -e "New Package\t\tLocal Version\t\tLatest Available Version"
sections=$(sed -n 's|^( Start \(.*\) )|\1|p' $p_list | sed -e '/Special/ d' -e '/Universal/ d')

# If this program is passed the name(s) of (a) package(s), then search for just that/those package(s).
# Otherwise, check all packages for updates
if [[ $@ == "" ]]; then
	# Re-initialize the fresh_updates.txt file
	rm -f $updates_file
	touch $updates_file

	# Universe
	packages=$(sed -n -e "/( Start Universal )/,/( End Universal )/ s/\(.*\)/\1/p" $p_list | sed -e '/^#/ d' -e '/^(/ d' -e '/^$/ d' | awk '{print $1}')
	for i in $packages; do
		$script_dir/universal_version_check $i
	done

	# Site packages
	for q in $sections; do
		function=$(echo $q | tr [:upper:] [:lower:])
		packages=$(sed -n -e "/( Start $q )/,/( End $q )/ s/\(.*\)/\1/p" $p_list | sed -e '/^#/ d' -e '/^(/ d'  -e '/^$/ d' | awk '{print $1}')
		for i in $packages; do
#			echo "checking $i"
			$script_dir/site_$function $i
		done
	done

	# Special case packages
#	packages=$(sed -n -e "/( Start Special )/,/( End Special )/ s/\(.*\)/\1/p" $p_list | sed -e '/^#/ d' -e '/^(/ d' | awk '{print $1}')
#	for i in $packages; do
#		$script_dir/special_$i
#	done
#else
#	for k in $@; do
		# TODO
		# Find out what section this package belongs to
#		echo stuff
#	done
fi

#time sudo $script_dir/build_packages.sh -b all

#commit_packages_to_svn

#rm -f *html *spec
