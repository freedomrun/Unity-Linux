#!/bin/bash

#This script checks to see if there are new commits to the svn repo since
# last time this script was ran.

# lastrev_file holds the svn revision of the last time this script was ran.
# it allows the script to only fetch only the new revisions.
# At the end of the script, it is updated so next time this script is ran
# it again only fetches the new revisions.

#####################################################
#  Configuration Section
#####################################################
UNITY_SVN_DIR=`/usr/sbin/unity_repo_details.sh -m`
MDV_SVN_DIR=`/usr/sbin/unity_repo_details.sh -o`
LAST_REV_FILE=last_rev
#####################################################
# End of Configuration Section
####################################################

usage()
{
	printf $"Usage: %s [-h|--help] <[-u|--unity]|[-m|--mandriva]>\n\n" $0
	exit -1
}

function finish
{
	echo -n "Stop time: "
	date
	echo "========================="
	exit $1
}


eval set -- `getopt -o hum --long help,unity,mandriva -n $(basename $0) -- "$@"`
called_args=$@
while true ; do
	case "$1" in
		-h|--help) usage ; shift ;;
		-u|--unity) do_unity=1 ; shift ;;
		-m|--mandriva) do_mdv=1 ; shift ;;
		--) shift ; break ;;
		*) echo "Internal error!" ; exit 1 ;;
	esac
done

if [ -z "$do_unity" -a -z "$do_mdv" ]
then
	usage
fi
if [ -n "$do_unity" -a -n "$do_mdv" ]
then
	usage
fi

fdir=$(dirname $0)
if [ -n "$do_unity" ]
then
	svn_dir=$UNITY_SVN_DIR
	lastrev_file=$fdir/$LAST_REV_FILE.txt
else 
	if [ -n "$do_mdv" ]
	then
		svn_dir=$MDV_SVN_DIR
		lastrev_file="$fdir/${LAST_REV_FILE}_mdv.txt"
	fi
fi

# Ok - let's start the execution
echo "-------------------------"
echo -n "Start time: "
date
echo "Called with following args: $called_args"

# make sure that the user has the SVN access priviledges - currently that's just builduser
if [ "$USER" != "builduser" ];
then
	echo "You dont' have sufficient svn privs to run this script."
	finish 1
fi

# check the current SVN revision against what was recorded in a file from last execution of this script
last_rev=$(cat $lastrev_file)
set -o pipefail
cur_rev=$(svn -rHEAD info $svn_dir | grep "^Revision: " | awk '{print $2}')
svnretval=$?

#in case something goes wrong with svn
if [ $svnretval -ne 0 ];
then
	echo "ERROR: Error fetching latest svn commit revision"
	finish 1
fi

# if SVN was changed, then updated the local copy
if [ "$last_rev" = "$cur_rev" ]; then
	echo "SAME"
else
	echo "DIFF"

	# Unity SVN contains both packages and other stuff. If anything changed, update everything
	if [ -n "$do_unity" ]
	then
		pushd $UNITY_SVN_DIR
	else 
		if [ -n "$do_mdv" ]
		then
			pushd $svn_dir
		fi
	fi

	# perform the SVN update
	svn up --accept theirs-full 2>&1
	popd

	# fetch the updated revisions
	tmpfile=$(mktemp)
	$fdir/fetch_revs.pl $svn_dir $last_rev $cur_rev $tmpfile
	if [ -n "$do_unity" ]
	then
		table=pkgs
	else
		if [ -n "$do_mdv" ]
		then
			table=pkgs_mdv
		fi
	fi

	$fdir/update_dbtbl.sh $tmpfile $table

	if [ $? -eq 0 ];
	then
		echo $cur_rev > $lastrev_file
	fi
fi
finish 0

