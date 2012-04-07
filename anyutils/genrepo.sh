#! /bin/bash -e

# location of your local repo
LOGDIR=/home/builduser/logs
DEVEL_SERVER_ROOT=`/usr/sbin/unity_repo_details.sh -d`
CUR_REPO=`/usr/sbin/unity_repo_details.sh -z`
LOCALDIR=`/usr/sbin/unity_repo_details.sh -r`
REMOTEDIR32=i586
REMOTEDIR64=x86_64
REMOTEDIRARM=armv5te
LOCALREPO32=$LOCALDIR/$REMOTEDIR32
LOCALREPO64=$LOCALDIR/$REMOTEDIR64
LOCALREPOARM=$LOCALDIR/$REMOTEDIRARM
REPO_SECTS=`/usr/sbin/unity_repo_details.sh -c`
PLF_SECTS=`/usr/sbin/unity_repo_details.sh -p`
LOCKBASE=$LOCALDIR/locks/
#REPOMDBIN=/home/unity/rpm5.2/lib/rpm/bin/
PLFSERVER=plf-unity@ryu.zarb.org:/home/projects/plf-unity/ftp/unity/$CUR_REPO
PLFREPO32=$PLFSERVER/$REMOTEDIR32
PLFREPO64=$PLFSERVER/$REMOTEDIR64
PLFREPOARM=$PLFSERVER/$REMOTEDIRARM
ERRORREPORTEMAIL=unity-qa@googlegroups.com
ERRORREPORTSENDER="Unity <mattydaw@gmail.com>"

BS_PATH=/var/www/scripts
BS_PENDING_ACTIONS=pending_actions.sh

RPMREPOCMD=/usr/lib/rpm/bin/rpmrepo 

usage()
{
        printf $"Usage: %s [-h|--help] [-i|--ignore-locks] [-p|--plf] [-g|--genhdlist] [-c|--check] [--32] [--64] [--arm] [list of channels]\n\n" $0
        exit -1
}

function rpmcheck_pp
{
rpmcheck -failures -explain | awk '
BEGIN {
    ERR=0
    ORS="\a"
}

/FAILED/ {
    ERR=ERR+1
    print "\n= " $0 " ="
    next
}

/^  / {
    gsub("^  ", "  * ")
    print
    next
}

{
    print
}

END {
    print "\n9999999999Total " ERR " errors"
}
' | sort | tr '\a' '\n' | awk "
/^9999999999Total/ {
    gsub(\"^9999999999\", \"\")
    print
    print \$2 >\"$1\"
    next
}

{
    print
}
"
}

function update_content_list()
{
# debug stuff
    echo "-------------------- $(date)" >> /tmp/genrepo.log
    echo "Running \"update_content_list $1\"" >> /tmp/genrepo.log
    echo "--------------------" >> /tmp/genrepo.log
    [ -d /tmp/"$1" ] || mkdir -p /tmp/"$1"
    cp -f "$1"/.rpmlist /tmp/"$1"/.rpmlist
    cd "$1" && find . -name '*.rpm' | sort > "$1"/.rpmlist
    echo >> /tmp/genrepo.log
}

function content_changed()
{
    echo "-------------------- $(date)" >> /tmp/genrepo.log
    echo "Running \"content_changed $1 $2\"" >> /tmp/genrepo.log
    echo "--------------------" >> /tmp/genrepo.log
    cd "$1" && find . -name '*.rpm' | sort > "$1"/.rpmlist.$$
    if [ ! -f "$2" ]
    then
        return 0
    fi
    RESULT=1
    diff -u "$2" "$1"/.rpmlist.$$ >> /tmp/genrepo.log || RESULT=0
    echo "Result: $RESULT" >> /tmp/genrepo.log
    echo >> /tmp/genrepo.log
    return $RESULT
}

eval set -- `getopt -o hipg --long help,check,ignore-locks,plf,genhdlist,32,64,arm -n $(basename $0) -- "$@"`

echo "`date` - Called with following args: $@" >> $LOGDIR/genrepo_error.log

while true ; do
	case "$1" in
		-i|--ignore-locks) ignore_locks=1 ; shift ;;
		-h|--help) usage ; shift ;;
		-p|--plf) sync_plf=1 ; shift ;;
		-g|--genhdlist) genhdlist=1 ; shift ;;
		-c|--check) check=1 ; shift ;;
		--32) do32=1 ; shift ;;
		--64) do64=1 ; shift ;;
		--arm) doARM=1 ; shift ;;
		--) shift ; break ;;
		*) echo "Internal error!" ; exit 1 ;;
	esac
done

if [ -n "$1" ]
then
	REPO_SECTS=$@
fi

if [ -n "$sync_plf" ]
then
	for SECT in $PLF_SECTS
	do
		REPO_SECTS[${#REPO_SECTS[*]}]=$SECT
	done

fi


#########################
# make sure to move all content from the BS into the repo
mvme_args=''
if [ -n "$do32" ]
then
	mvme_args="$mvme_args --32"
fi
if [ -n "$do32" ]
then
	mvme_args="$mvme_args --64"
fi
if [ -n "$doARM" ]
then
	mvme_args="$mvme_args --arm"
fi
if [ -n "$sync_plf" ]
then
	mvme_args="$mvme_args --plf"
fi

# pause the BS before moving any content - this may take a while
# this cmd must be added to nopasswd sudo
echo "##### Pausing the Build Server Queue #####"
$BS_PATH/pause_BS.sh

# we can now try to run the pending actions that were defined from the web browser interface
flock --exclusive --timeout=5 $BS_PATH/$BS_PENDING_ACTIONS sh $BS_PATH/$BS_PENDING_ACTIONS
RETVAL=$?
if [ $RETVAL -eq 0 ]
then
	truncate --size 0 $BS_PATH/$BS_PENDING_ACTIONS
else
	echo "Could not get exclusive lock on $BS_PATH/$BS_PENDING_ACTIONS - its action were not executed"
fi

# now we can safely move the remaining content
mvme $mvme_args

#############################

if [ -z "$ignore_locks" ]
then
	# if a lockfile persists for 2 hours or more, it's probably stale, so delete it
	echo "--- Make sure there aren't any stale locks first ---"
	/usr/sbin/tmpwatch -m 2 -v $LOCKBASE
	
	echo "--- Checking to see if anyone has a lock ---"
	for I in `seq 5`
	do
		LOCKCOUNT=$(ls $LOCKBASE | wc -l)
		if [ "$LOCKCOUNT" == "0" ]
		then
			break
		fi
		sleep 60
		echo -n "*"
	done
	echo

	if [ "$LOCKCOUNT" != "0" ]
	then
		echo "`date`: Cannot aquire lock in 5 mins." >> $LOCALDIR/genrepo_errors.log
		exit 1
	fi
	
	date > $LOCKBASE/$HOSTNAME.$$
	
	echo "--- Check to see if we are the only one who aquired the lock '$LOCKBASE/$HOSTNAME.$$' ---"
	for I in `seq 5`
	do
		LOCKCOUNT=$(ls $LOCKBASE | wc -l)
		if [ "$LOCKCOUNT" == "1" ]
		then
			break
		fi
		sleep 60
		echo -n "*"
	done
	echo
	
	if [ "$LOCKCOUNT" != "1" ]
	then
		echo "`date`: Meanwhile another lock detected and not released in 5 mins." >> $LOCALDIR/genrepo_errors.log
		rm -f $LOCKBASE/$HOSTNAME.$$
		exit 2
	fi
fi

# set the corret perms on all temporary files
umask 002

# cleanup in case of an interrupt
trap 'rm -Rf $LOCKBASE/$HOSTNAME.$$ $TMPREPO32 $TMPREPO64 $TMPREPOARM 2>/dev/null || true; chmod u+w $LOCALREPO32/* $LOCALREPO64/* $LOCALREPOARM/*; exit' 0 1 2 3 7 13 15

cd $LOCALDIR

date

# link RPMs to temporary directories
echo ""
echo "=============================================================="
echo "Linking packages to temporary directories"
echo "=============================================================="
echo ""
TMPREPO32=$LOCALDIR/tmp/$REMOTEDIR32.$$
TMPREPO64=$LOCALDIR/tmp/$REMOTEDIR64.$$
TMPREPOARM=$LOCALDIR/tmp/$REMOTEDIRARM.$$

cp -lr $LOCALREPO32 $TMPREPO32
cp -lr $LOCALREPO64 $TMPREPO64
cp -lr $LOCALREPOARM $TMPREPOARM

echo ""
echo "=============================================================="
echo "Making the repository dirs readonly"
echo "=============================================================="
echo ""
chmod u-w $LOCALREPO32/*
chmod u-w $LOCALREPO64/*
chmod u-w $LOCALREPOARM/*

echo ""
echo "=============================================================="
echo "Making sure the temporary repository dirs are writeable"
echo "=============================================================="
echo ""
chmod u+w $TMPREPO32/*
chmod u+w $TMPREPO64/*
chmod u+w $TMPREPOARM/*


# generate repodata (repo-md)
echo ""
echo "=============================================================="
echo "Generating repo-md metadata (repodata)"
echo "=============================================================="
echo ""
for SECT in ${REPO_SECTS[@]}
do
	if [ -n "$do32" ] && content_changed $TMPREPO32/$SECT/ $LOCALREPO32/$SECT/.rpmlist
	then
		echo "-- Channel $TMPREPO32/$SECT/ --"
#		find $TMPREPO32/$SECT/ -name '*.rpm' -exec chmod 644 {} \;
		cd $TMPREPO32/$SECT && createrepo --changelog-limit=4 --update . | grep '^Saving '
		#cd $TMPREPO32/$SECT && $RPMREPOCMD . | grep '^Saving '
	fi

	if [ -n "$do64" ] && content_changed $TMPREPO64/$SECT/ $LOCALREPO64/$SECT/.rpmlist
	then
		echo "-- Channel $TMPREPO64/$SECT/ --"
#		find $TMPREPO64/$SECT/ -name '*.rpm' -exec chmod 644 {} \;
		cd $TMPREPO64/$SECT && createrepo --changelog-limit=4 --update . | grep '^Saving '
		#cd $TMPREPO64/$SECT && $RPMREPOCMD . | grep '^Saving '
	fi
	
	if [ -n "$doARM" ] && content_changed $TMPREPOARM/$SECT/ $LOCALREPOARM/$SECT/.rpmlist
	then
		echo "-- Channel $TMPREPOARM/$SECT/ --"
#		find $TMPREPOARM/$SECT/ -name '*.rpm' -exec chmod 644 {} \;
		cd $TMPREPOARM/$SECT && createrepo --changelog-limit=4 --update . | grep '^Saving '
		#cd $TMPREPOARM/$SECT && $RPMREPOCMD . | grep '^Saving '
	fi
	
done


# generate media_infos
if [ -n "$genhdlist" ]
then
	echo ""
	echo "=============================================================="
	echo "Generating urpmi metadata (media_infos)"
	echo "=============================================================="
	echo ""
	for SECT in ${REPO_SECTS[@]}
	do
		if [ -n "$do32" ] && content_changed $TMPREPO32/$SECT/ $LOCALREPO32/$SECT/.rpmlist
		then
			echo "-- Channel $TMPREPO32/$SECT/ --"
			genhdlist2 --no-hdlist --xml-info --allow-empty-media --media_info-dir $TMPREPO32/$SECT/media_info $TMPREPO32/$SECT/
		fi

		if [ -n "$do64" ] && content_changed $TMPREPO64/$SECT/ $LOCALREPO64/$SECT/.rpmlist
		then
			echo "-- Channel $TMPREPO64/$SECT/ --"
			genhdlist2 --no-hdlist --xml-info --allow-empty-media --media_info-dir $TMPREPO64/$SECT/media_info $TMPREPO64/$SECT/
		fi

		if [ -n "$doARM" ] && content_changed $TMPREPOARM/$SECT/ $LOCALREPOARM/$SECT/.rpmlist
		then
			echo "-- Channel $TMPREPOARM/$SECT/ --"
			genhdlist2 --no-hdlist --xml-info --allow-empty-media --media_info-dir $TMPREPOARM/$SECT/media_info $TMPREPOARM/$SECT/
		fi
	done
fi


# push out the PLF content
if [ -n "$sync_plf" ]
then
	echo ""
	echo "=============================================================="
	echo "Pushing PLF content out to $PLF_SERVER"
	echo "=============================================================="
	echo ""
	for SECT in ${PLF_SECTS[@]}
	do
		if [ -n "$do32" ]
		then
			echo "-- Channel $TMPREPO32/$SECT/ --"
			rsync -avz --delete-after -e "ssh -i /home/builduser/.ssh/unity_plf" $TMPREPO32/$SECT  $PLFREPO32
		fi

		if [ -n "$do64" ]
		then
			echo "-- Channel $TMPREPO64/$SECT/ --"
			rsync -avz --delete-after -e "ssh -i /home/builduser/.ssh/unity_plf" $TMPREPO64/$SECT  $PLFREPO64
		fi

		if [ -n "$doARM" ]
		then
			echo "-- Channel $TMPREPOARM/$SECT/ --"
			rsync -avz --delete-after -e "ssh -i /home/builduser/.ssh/unity_plf" $TMPREPOARM/$SECT  $PLFREPOARM
		fi
	done
fi


echo ""
echo "=============================================================="
echo "Making the repository dirs writeable"
echo "=============================================================="
echo ""
chmod u+w $LOCALREPO32/*
chmod u+w $LOCALREPO64/*
chmod u+w $LOCALREPOARM/*


# replace metadata with newly generated stuff
echo ""
echo "=============================================================="
echo "Replacing original metadata with newly generated stuff"
echo "=============================================================="
echo ""
for SECT in ${REPO_SECTS[@]}
do
	if [ -n "$do32" ]
	then
		if [ -n "$genhdlist" ]
		then
			rm -Rf $LOCALREPO32/$SECT/media_info
			mv -f $TMPREPO32/$SECT/media_info $LOCALREPO32/$SECT/
		fi
		rm -Rf $LOCALREPO32/$SECT/repodata
		mv -f $TMPREPO32/$SECT/repodata $LOCALREPO32/$SECT/
                update_content_list $LOCALREPO32/$SECT/
	fi

	if [ -n "$do64" ]
	then
		if [ -n "$genhdlist" ]
		then
			rm -Rf $LOCALREPO64/$SECT/media_info
			mv -f $TMPREPO64/$SECT/media_info $LOCALREPO64/$SECT/
		fi			
		rm -Rf $LOCALREPO64/$SECT/repodata
		mv -f $TMPREPO64/$SECT/repodata $LOCALREPO64/$SECT/
                update_content_list $LOCALREPO64/$SECT/
	fi

	if [ -n "$doARM" ]
	then
		if [ -n "$genhdlist" ]
		then
			rm -Rf $LOCALREPOARM/$SECT/media_info
			mv -f $TMPREPOARM/$SECT/media_info $LOCALREPOARM/$SECT/
		fi			
		rm -Rf $LOCALREPOARM/$SECT/repodata
		mv -f $TMPREPOARM/$SECT/repodata $LOCALREPOARM/$SECT/
                update_content_list $LOCALREPOARM/$SECT/
	fi
done

if [ -n "$check" ]
then
	echo ""
	echo "=============================================================="
	echo "Checking for dependency problems"
	echo "=============================================================="
	echo ""

	RPMCHECKFILE=rpmcheck.out
	RPMCHECKFILE32=$RPMCHECKFILE.32.txt
	RPMCHECKFILE64=$RPMCHECKFILE.64.txt
	RPMCHECKFILEARM=$RPMCHECKFILE.ARM.txt
	RPMCHECKERRCNT32=$RPMCHECKFILE.32.cnt
	RPMCHECKERRCNT64=$RPMCHECKFILE.64.cnt
	RPMCHECKERRCNTARM=$RPMCHECKFILE.ARM.cnt
	timeout=1380 # how often the run the check (in minutes): 23h*60min=1380min

	email32=0
	email64=0
	emailARM=0
	errcnt32=0
	errcnt64=0
	errcntARM=0
	errcnt=0
	attachstring=''
	rightnow=`date`
	
	if [ -n "$do32" ]
	then
		echo "-- Analysing $TMPREPO32 --"

		if [ ! -f $LOCALDIR/hdlist32/$RPMCHECKFILE32 -o `eval find $LOCALDIR/hdlist32/ -name '$RPMCHECKFILE32' -mmin +$timeout | wc -l` -ne 0 ]
		then
			cd $TMPREPO32
			genhdlist-old --subdir $LOCALDIR/hdlist32 ${REPO_SECTS[@]}
			# Pretty print the report
			echo "Report generated at: $rightnow" > $LOCALDIR/hdlist32/$RPMCHECKFILE32;
			zcat $LOCALDIR/hdlist32/hdlist.cz | rpmcheck_pp $LOCALDIR/hdlist32/$RPMCHECKERRCNT32 >> $LOCALDIR/hdlist32/$RPMCHECKFILE32
			errcnt32=$(cat $LOCALDIR/hdlist32/$RPMCHECKERRCNT32)
			(( errcnt += errcnt32 )) || true

			if (( errcnt32 != 0 ))
			then
				email32=1
				attachstring="$attachstring -a $LOCALDIR/hdlist32/$RPMCHECKFILE32"
			fi

			# make the error reports accessible via the Build Server
			cp $LOCALDIR/hdlist32/$RPMCHECKFILE32 $BS_PATH
		fi
	fi

	if [ -n "$do64" ]
	then
		echo "-- Analysing $TMPREPO64 --"
		
		if [ ! -f $LOCALDIR/hdlist64/$RPMCHECKFILE64 -o `eval find $LOCALDIR/hdlist64/ -name '$RPMCHECKFILE64' -mmin +$timeout | wc -l` -ne 0 ]
		then
			cd $TMPREPO64
			genhdlist-old --subdir $LOCALDIR/hdlist64 ${REPO_SECTS[@]}
			# Pretty print the report
			echo "Report generated at: $rightnow" >  $LOCALDIR/hdlist64/$RPMCHECKFILE64
			zcat $LOCALDIR/hdlist64/hdlist.cz | rpmcheck_pp $LOCALDIR/hdlist64/$RPMCHECKERRCNT64 >> $LOCALDIR/hdlist64/$RPMCHECKFILE64
			errcnt64=$(cat $LOCALDIR/hdlist64/$RPMCHECKERRCNT64)
			(( errcnt += errcnt64 )) || true

			if (( errcnt64 != 0 ))
			then
				email64=1
				attachstring="$attachstring -a $LOCALDIR/hdlist64/$RPMCHECKFILE64"
			fi

			# make the error reports accessible via the Build Server
			cp $LOCALDIR/hdlist64/$RPMCHECKFILE64 $BS_PATH
		fi
   	fi

	if [ -n "$doARM" ]
	then
		echo "-- Analysing $TMPREPOARM --"
		
		if [ ! -f $LOCALDIR/hdlistARM/$RPMCHECKFILEARM -o `eval find $LOCALDIR/hdlistARM/ -name '$RPMCHECKFILEARM' -mmin +$timeout | wc -l` -ne 0 ]
		then
			cd $TMPREPOARM
			genhdlist-old --subdir $LOCALDIR/hdlistARM ${REPO_SECTS[@]}
			# Pretty print the report
			echo "Report generated at: $rightnow" >  $LOCALDIR/hdlistARM/$RPMCHECKFILEARM
			zcat $LOCALDIR/hdlistARM/hdlist.cz | rpmcheck_pp $LOCALDIR/hdlistARM/$RPMCHECKERRCNTARM >> $LOCALDIR/hdlistARM/$RPMCHECKFILEARM
			errcntARM=$(cat $LOCALDIR/hdlistARM/$RPMCHECKERRCNTARM)
			(( errcnt += errcntARM )) || true

			if (( errcntARM != 0 ))
			then
				emailARM=1
				attachstring="$attachstring -a $LOCALDIR/hdlistARM/$RPMCHECKFILEARM"
			fi

			# make the error reports accessible via the Build Server
			cp $LOCALDIR/hdlistARM/$RPMCHECKFILEARM $BS_PATH
		fi
   	fi

	if [ "$email32" == 1 -o "$email64" == 1 -o "$emailARM" == 1 ]
	then
		echo "-- $errcnt errors found, sending an email --"
		mail -s "Repo dependency error reports for $rightnow: $errcnt errors" $attachstring -r "$ERRORREPORTSENDER" "$ERRORREPORTEMAIL" < /dev/null
	fi
fi



echo ""
echo "=============================================================="
echo "Unlinking the temporary package tree"
echo "=============================================================="
echo ""
rm -Rf $TMPREPO32
rm -Rf $TMPREPO64
rm -Rf $TMPREPOARM


if [ -z "$ignore_locks" ]
then
	echo "--- Cleaning up the lock ---"
	rm -f $LOCKBASE/$HOSTNAME.$$
fi

# Change to existing directory
cd /

# restart the BS
# this cmd must be added to nopasswd sudo

echo "##### Updating smart in the chroots #####"
sudo bldchrt -c "smart upgrade --update -y"
#sudo bldchrt -b--with=plf -c "smart upgrade --update -y"
echo "##### Unpausing the Build Server Queue #####"
$BS_PATH/continue_BS.sh
