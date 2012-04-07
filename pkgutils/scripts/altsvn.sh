#!/bin/sh
# to be done in every dir to be linked in
#mkdir $name
#cd $name
#echo "name $(basename `pwd`)" > $(basename `pwd`).pkginfo; echo "url http://svn.mandriva.com/svn/packages/cooker" >> $(basename `pwd`).pkginfo; echo "path $(basename `pwd`)/current" >> $(basename `pwd`).pkginfo

#
ALTSVNDIR="/home/builduser/src/cooker"
SVNDIR="$HOME/src/svn"
pkginfo="pkginfo"
#

getvalue () {
	#$1 is key, $2 is filename to read from
	[ -r "$2" ] && sed -n "s|^$1[ \t]*||p" "$2"
}

oneup () {
	name=$(getvalue "name" "$1")
	# error checking
	if [ -z "$name" ]; then
		echo "Missing name in $1"
		#logit "Missing name in $1"
		return
	fi
	url=$(getvalue "url" "$1")
	# error checking
	if [ -z "$url" ]; then
		echo "Missing url in $1"
		#logit "Missing url in $1"
		return
	fi
	path=$(getvalue "path" "$1")
	# error checking
	if [ -z "$path" ]; then
		echo "Missing path in $1"
		#logit "Missing path in $1"
		return
	fi
	dir="${path#*/}"
	# error checking
	if [ -z "$dir" ]; then
		echo "Missing directory component of path in $1"
		#logit "Missing directory component of path in $1"
		return
	fi
	
	#check out of new dir
	if ! [ -d "$name" ]; then
		echo -e "\r\033[K$name does not exist, will try to create..."
		c=$(svn up ./$name -N 2>&1)
		if [ $? -ne 0 -o "$c" == "Skipped '$name'" -o "${c:0:12}" == "At revision " ]; then
			echo "Checkout of $name from $url/$name failed"
			return
		else
			cd $name
			svn up ./$dir --set-depth infinity
			if [ $? -ne 0 ]; then
				echo "Checkout of $name from $url/$name failed"
			fi
			cd -
		fi
	else
		echo -ne "\r\033[K$name exists, skipping..."
	fi
}

# # # # # # # # # # # # # #
#  Execution starts here  #
# # # # # # # # # # # # # #

cd $ALTSVNDIR
[ $? -eq 0 ] || exit 1

if [ $# -ne 0 ]; then
	while [ $# -gt 0 ]; do
		b=$(basename $1)
		p="${SVNDIR}/${b}/${b}.${pkginfo}"
		[ -s "$p" ] && oneup $p
		shift
	done
else
	for p in $(find $SVNDIR -mindepth 1 -maxdepth 2 -type f -name "*${pkginfo}"); do
		oneup $p
	done
fi
