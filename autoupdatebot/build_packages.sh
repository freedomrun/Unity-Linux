#!/bin/bash

# There are 2 methods of getting a list of packages to build:
# 1. Read in from a list
# 2. Scan the packages dir of the SVN repo and find all the .failed files

source ./generic_functions.sh

# This function will xz tarballs
function get_tarballs()
{
	local i present limit package url version tarball tball_no_ext
	limit=$(wc -l $updates_file)
	for package in $(awk '{print $1}' $updates_file); do
		version=$(grep $package $updates_file | awk '{print $3}')
		url=$(sed -n "s|$package.*\([hf]t*p://.*\)|\1|p" $updates_file)
		tarball=$(echo $url | sed -e 's|/download||' | awk -F/ '{print $NF}')
		# Strip the extension from the tarball name
		tball_no_ext=$(echo $tarball | awk 'BEGIN{FS=OFS="."}{$NF=""; NF--; print}')
		present=$(find $svn_path/$package/S/ -name $tball_no_ext* | fgrep -v .svn)
		if [[ $present == "" ]]; then
			wget -O $svn_path/$package/S/$tarball $url
			xzme $svn_path/$package/S/$tarball
		fi
	done
}

function failed_packages()
{
	echo $(find $svn_path -name .fail* | sed -e "s|$svn_path/\(.*\)/.fail.*|\1|")
}

function fresh_updates()
{
	echo $(awk '{print $1}' $updates_file)
	get_tarballs
}

# Do we build just the failed packages, the latest updates, or both?
# Default is both.
while getopts ":b:" opt; do
	case $OPTARG in
		failed)
			build_list=$(failed_packages)
		;;
		fresh)
			build_list=$(fresh_updates)
		;;
		all)
			build_list=$(echo $(failed_packages) $(fresh_updates))
		;;
		*)
			build_list=$2
		;;
	esac
done

#build_list=$(echo $build_list | sed 's|\s|\n|g' | sort | uniq)

echo Building: $build_list
for i in $build_list; do
	version=$(grep $i $updates_file | awk '{print $3}')
	update_spec $i $version version
done

time bldchrt -a 64 $(echo $build_list)
