#!/bin/bash

self_identity="autoupdatebot"
svn_path=$(sed -n 's|^svn[\t ]*\(.*\)|\1|p' $HOME/.svndir)
script_dir="$svn_path/../projects/$self_identity"
p_list="$script_dir/packages.list"
updates_file="$script_dir/fresh_updates.txt"
#mysql_password=$(cat $HOME/.autoupdatebot_mysql_password)

# Send this function the name of the HTML file it will clean up.
# This function removes all the unnecessary bits from an HTML file.
# When this function is done, the link to the most recent tarball should be at the top.
function clean_html()
{
	sed -i -f normal.sed $1.html
}

# Send this function:
# 1. The name of the package
# 2. The URL
# 3. Optional: the user agent string
function fetch_html()
{
	if [[ $3 == "" ]]; then
		wget -qt 3 -O $1.html --force-clobber --no-check-certificate $2
	else
		wget -qt 3 -O $1.html --force-clobber --no-check-certificate $2 -U "$3"
	fi
}

# Send this function:
# 1. The name of the program
# 2. The tarball name
# It will return the version number
function get_tarball_version()
{
	echo $2 | sed -e "s|$1-\(.*\).[tz][abgli][rpz][2m]*a*.*|\1|" | sed -e 's|-*m*i*n*src||' -e 's|-Source||'
}

# Send this function the name of the package
# It will return the version number as listed in the spec file
function get_local_version()
{
	local local_version
	local_version=$(sed -n 's|^Version:[\t ]*\(.*\)|\1|p' $svn_path/$1/F/$1.spec)
	# If the package version number is not explicitly identified at the Version tag, use rpm to extract the version
	if [[ $(echo $local_version | cut -c1) == "%" ]]; then
		cp -f $svn_path/$1/F/$1.spec ./
		# Missing patches cause errors when querying the spec file
		sed -i -e '/^Patch/ d' -e '/^%patch/ d' $1.spec
		local_version=$(rpm -q --qf "%{version}\n" --specfile $1.spec | awk 'NR==1')
	fi
	echo $local_version
}

# Send this function the name of the package
# It will return the release number as listed in the spec file
function get_spec_rel()
{
	local rel
	rel=$(sed -n 's|^Release:[\t ]*\(.*\)|\1|p' $svn_path/$1/F/$1.spec)
	# If the package version number is not explicitly identified at the Version tag, use rpm to extract the version
	if [[ $(echo $rel | cut -c1) == "%" ]]; then
		cp -f $svn_path/$1/F/$1.spec ./
		# Missing patches cause errors when querying the spec file
		sed -i -e '/^Patch/ d' -e '/^%patch/ d' $1.spec
		rel=$(rpm -q --qf "%{release}\n" --specfile $1.spec | awk 'NR==1')
	fi
	echo $rel
}

# Send this function the name of the package
# It will return the name of the packager and e-mail address
function get_packager_info()
{
	local packager email
	# First we look for a packager tag
	packager=$(grep ^Packager $svn_path/$1/F/$1.spec | awk '{print $2}')
	email=$(grep ^Packager $svn_path/$1/F/$1.spec | sed -n 's|.*\(<.*>\).*|\1|g p')
	# If the packager tag is not present or empty
	if [[ $packager == "" ]]; then
		packager=$(grep -A1 %changelog $svn_path/$1/F/$1.spec | awk 'NR==2' | awk '{print $6}')
		email=$(grep -A1 %changelog $svn_path/$1/F/$1.spec | sed -n 's|.*\(<.*>\).*|\1|g p')
	fi
	echo $packager $email
}

# Send this function:
# 1. The name of the package.
# 2. The new %release number.
function change_spec_rel()
{
	# First see if the release # is set at the Release: tag
	if [[ $(sed -n "s|^Release:\s.*\s\(.*\)|\1| p" $svn_path/$1/F/$1.spec | cut -c1) != "%" ]]; then
		# Check to make sure the release isn't already set to where it's supposed to be
		if [[ $(sed -n "s|^Release:\s.*\s\(.*\)|\1| p" $svn_path/$1/F/$1.spec) != $2 ]]; then
			sed -i "s|^\(Release:\s*%mkrel\s*\).*|\1$2|" $svn_path/$1/F/$1.spec
		fi
	# If it isn't, then see if it's set in a '%define rel 1' statement
	elif [[ $(sed -n "s|^%define\s*rel\s\s*\(.*\)|\1| p" $svn_path/$1/F/$1.spec | grep -c ".*") -eq 1 ]]; then
		# Check to make sure the release isn't already set to where it's supposed to be
		if [[ $(sed -n "s|^%define\s*rel\s\s*\(.*\)|\1| p" $svn_path/$1/F/$1.spec) != $2 ]]; then
			sed -i "s|^%define\srel\s|\(%define\trel\)[\t ].*|\1\t$2|" $svn_path/$1/F/$1.spec
		fi
	# If it's neither of those cases, then autoupdatebot isn't smart enough to handle it.
	else
		echo "You will have to update the spec file manually"
		text-editor $svn_path/$1/F/$1.spec
	fi
}

# Send this function:
# 1. The name of the package
# 2. The version # of the tarball
# 3. Whether we're updating the version or release.
# 4. Optional. If a %release update, the %release number.
function update_spec()
{
	# Add changelog entry
	# First check and make sure there isn't already a changelog entry
	# This check is *very* rudimentary - it may very well place a duplicate entry
	local rel pinfo latest_entry
	latest_entry=$(grep -A3 %changelog $svn_path/$1/F/$1.spec | awk 'NR==3' | cut -c3-)
	if [[ $(echo $latest_entry | grep -o $2) != "$2" ]]; then
		pinfo=$(get_packager_info $1)
		if [[ $4 == "" ]]; then
			rel=1
		else
			rel=$4
		fi
		line1="* $(date '+%a %b %d %Y') $pinfo $2-$rel"
		line2="- $2 ($self_identity)"
		sed -i "s|%changelog|&\n$line1\n$line2\n|" $svn_path/$1/F/$1.spec
	fi

	if [[ $3 == "version" ]]; then
		# Update version
		sed -i "s|^Version:\([\t ]*\).*|Version:\1$2|" $svn_path/$1/F/$1.spec
		update_spec_rel $1 1
	elif [[ $3 == "release" ]]; then
		update_spec_rel $1 $rel
	fi
	
}

# Send this function:
# 1. Name of package - foobar
# 2. Local version - 1.2.3
# 3. Updated version - 1.2.4
# 4. Complete URL to tarball
# Example: foobar 1.2.3 1.2.4 http://www.example.com/source/example-1.2.4.tar.gz
function print()
{
	echo -e "$1\t$2\t$3\t$4" >> $updates_file
	case $(echo $1 | wc -c) in
		[1-8])
			echo -ne "$1\t\t\t";;
		[9])
			echo -ne "$1\t\t";;
		1[0-5])
			echo -ne "$1\t\t";;
		1[6-9])
			echo -ne "$1\t\t";;
		2[0-2])
			echo -ne "$1\t";;
	esac
	case $(echo $2 | wc -c) in
		[1-8])
			echo -ne "$2\t\t\t";;
		[9])
			echo -ne "$2\t\t";;
		1[0-5])
			echo -ne "$2\t\t";;
		1[6-9])
			echo -ne "$2\t\t";;
		2[0-2])
			echo -ne "$2\t\t";;
	esac
	echo $3
}

function commit_packages_to_svn()
{
	# Commit packages to SVN
	package_list=$(awk '{print $1}' $updates_file)
	for p in $package_list; do
		cp -f $svn_path/$1/F/$1.spec ./
		# Missing patches cause errors when querying the spec file
		sed -i -e '/^Patch/ d' -e '/^%patch/ d' $1.spec
		version=$(rpm -q --qf "%{version}\n" --specfile $p.spec | awk "NR==1")
		echo $version
		what_we_should_find=$(grep "Source[0-9]*:[\t \]*" $p.spec | sed -e "s|%{*version}*|$version|" -e "s|%{*name}*|$p|" | awk -F/ '{print $NR}')
		echo $what_we_should_find
		what_is_there=$(ls -1 $svn_path/$p/S/)
		echo $what_is_there
	#	svn del $svn_path/$p/S/$p-$o
	#	svn add $svn_path/$p/S/$p-$newver*
	
	#	svn commit -m "$p: update to $version (autoupdatebot)"
	done
}

function mysql_query()
{
	dbase=$(mysql -u$self_identity -p$mysql_password -e ”use MYDATABASE; select * from MYTABLE where id = 1;”)
}
