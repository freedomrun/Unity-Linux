#!/bin/sh
URL=mdawkins.com
LOCKMACHINE='-p21 builduser@'$URL
DEVELDIR=$(ssh $LOCKMACHINE "/usr/sbin/unity_repo_details.sh -r")
LOCKBASE=$DEVELDIR/locks/
LOCKREPO32=$DEVELDIR/i586/
LOCKREPO64=$DEVELDIR/x86_64/
LOCKREPOARM=$DEVELDIR/armv5te/
CUR_REPO=$(ssh $LOCKMACHINE "/usr/sbin/unity_repo_details.sh -z")
LOGDIR=/home/builduser/logs
REPOPATH=/public/distributions/unity
REPODIR32=$REPOPATH/repo/$CUR_REPO/i586/
REPODIR64=$REPOPATH/repo/$CUR_REPO/x86_64/
REPODIRARM=$REPOPATH/repo/$CUR_REPO/armv5te/
REPOURL32=sftp://builduser:@$URL:21$DEVELDIR/i586/
REPOURL64=sftp://builduser:@$URL:21$DEVELDIR/x86_64/
REPOURLARM=sftp://builduser:@$URL:21$DEVELDIR/armv5te/
reponames=$(ssh $LOCKMACHINE "/usr/sbin/unity_repo_details.sh -c")

# Check to see if anyone has a lock on the devel server already
for I in `seq 10`
do
	LOCKCOUNT=$(ssh $LOCKMACHINE "ls $LOCKBASE | wc -l")
	if [ "$LOCKCOUNT" == "0" ]
	then
		break
	fi
	sleep 60
done

# if they do, then it's not released in 5 minutes, then let's call it quits
if [ "$LOCKCOUNT" != "0" ]
then
	# ibiblio is not able to send emails
	#echo "Cannot aquire lock." | mail -s "ibiblio sync failed" david@unity-linux.org gri6507@gmail.com
	echo "Cannot aquire lock."
	ssh $LOCKMACHINE "echo \"`date`: Cannot aquire lock in 5 mins.\" >> $LOGDIR/ibiblio_sync_errors.log"
	exit 1
fi

# place our own lock
ssh $LOCKMACHINE "date > $LOCKBASE/$HOSTNAME.$$"

# make sure we are the only ones who placed the lock
for I in `seq 10`
do
	LOCKCOUNT=$(ssh $LOCKMACHINE "ls $LOCKBASE | wc -l")
        if [ "$LOCKCOUNT" == "1" ]
        then
                break
        fi
        sleep 60
done
	
# if we were not, clean up our lock and exit
if [ "$LOCKCOUNT" != "1" ]
then
        ssh $LOCKMACHINE "echo \"`date`: Meanwhile another lock detected and not released in 5 mins.\" >> unity-repo/ibiblio_sync_errors.log"
	ssh $LOCKMACHINE "rm -f $LOCKBASE/$HOSTNAME.$$"
        exit 2
fi

# cleanup in case of an interrupt
trap 'ssh $LOCKMACHINE "chmod u+w $LOCKREPO32/*; chmod u+w $LOCKREPO64/*; chmod u+w $LOCKREPOARM/*" 2>/dev/null; ssh $LOCKMACHINE "rm -f $LOCKBASE/$HOSTNAME.$$" 2>/dev/null; exit' 0 1 2 3 7 13 15

# Make sure repo dirs are writable
ssh $LOCKMACHINE "chmod u+w $LOCKREPO32/*"
ssh $LOCKMACHINE "chmod u+w $LOCKREPO64/*"
ssh $LOCKMACHINE "chmod u+w $LOCKREPOARM/*"

# refresh metadata on remote machine
ssh $LOCKMACHINE "/usr/sbin/genrepo.sh -i --plf --32 --64 -arm --check ${reponames[@]}"

echo "===================== Done With genrepo.sh execution ======================="

# Since we want to ensure that sync runs on content that isn't going to change on us in the middle, make the repo read-only
ssh $LOCKMACHINE "chmod u-w $LOCKREPO32/*"
ssh $LOCKMACHINE "chmod u-w $LOCKREPO64/*"
ssh $LOCKMACHINE "chmod u-w $LOCKREPOARM/*"

# Get the new content of the rpm directories
for reponame in ${reponames[@]}
do
        lftp -c "open -e 'mirror -r --ignore-time -v . '"$REPODIR32"$reponame  "$REPOURL32"$reponame"

        lftp -c "open -e 'mirror -r --ignore-time -v . '"$REPODIR64"$reponame  "$REPOURL64"$reponame"

        lftp -c "open -e 'mirror -r --ignore-time -v . '"$REPODIRARM"$reponame  "$REPOURLARM"$reponame"
done

# Get the new content of the repodata dirs
for reponame in ${reponames[@]}
do
        mkdir -p $REPODIR32/$reponame/.repodata
        lftp -c "open -e 'mirror -e --ignore-time -v . '"$REPODIR32"$reponame/.repodata  "$REPOURL32"$reponame"/repodata
        rm -Rf $REPODIR32/$reponame/repodata
        mv -f $REPODIR32/$reponame/.repodata $REPODIR32/$reponame/repodata

        mkdir -p $REPODIR64/$reponame/.repodata
        lftp -c "open -e 'mirror -e --ignore-time -v . '"$REPODIR64"$reponame/.repodata  "$REPOURL64"$reponame"/repodata
        rm -Rf $REPODIR64/$reponame/repodata
        mv -f $REPODIR64/$reponame/.repodata $REPODIR64/$reponame/repodata

        mkdir -p $REPODIRARM/$reponame/.repodata
        lftp -c "open -e 'mirror -e --ignore-time -v . '"$REPODIRARM"$reponame/.repodata  "$REPOURLARM"$reponame"/repodata
        rm -Rf $REPODIRARM/$reponame/repodata
        mv -f $REPODIRARM/$reponame/.repodata $REPODIRARM/$reponame/repodata
done

echo "=================== Done with repodata dir updates ============================"

# Get the new content of the media_info dirs
##for reponame in ${reponames[@]}
##do
##	mkdir -p $REPODIR32/$reponame/.media_info
##        lftp -c "open -e 'mirror -e --ignore-time -v . '"$REPODIR32"$reponame/.media_info  "$REPOURL32"$reponame"/media_info
##	rm -Rf $REPODIR32/$reponame/media_info
##	mv -f $REPODIR32/$reponame/.media_info $REPODIR32/$reponame/media_info

##        mkdir -p $REPODIR64/$reponame/.media_info
##        lftp -c "open -e 'mirror -e --ignore-time -v . '"$REPODIR64"$reponame/.media_info  "$REPOURL64"$reponame"/media_info
##        rm -Rf $REPODIR64/$reponame/media_info
##        mv -f $REPODIR64/$reponame/.media_info $REPODIR64/$reponame/media_info
##done

# Delete the local content that is not present on the remote (devel) server
for reponame in ${reponames[@]}
do
	# make sure that comething horrible didn't happen and that we are not about to whipe out the entire contents of the repo
	# the side effect is that if the devel server has an empty channel (one without *.rpm of file with name of empty) then old RPMS won't be cleaned up
	RPMCOUNT=$(ssh $LOCKMACHINE "find $LOCKREPO32/$reponame/ -name '*.rpm' -or -name 'empty' | wc -l")
	if [ "$RPMCOUNT" == "0" ]
	then
		ssh $LOCKMACHINE "echo \"`date`: the $LOCKREPO32/$reponame channel contains no RPMs and no file called 'empty'. Skipping for safety reasons.\"  >> unity-repo/ibiblio_sync_errors.log"
	else
        	lftp -c "open -e 'mirror -r -e --ignore-time -v . '"$REPODIR32"$reponame  "$REPOURL32"$reponame"
	fi

        # make sure that comething horrible didn't happen and that we are not about to whipe out the entire contents of the repo
        # the side effect is that if the devel server has an empty channel (one without *.rpm of file with name of empty) then old RPMS won't be cleaned up
        RPMCOUNT=$(ssh $LOCKMACHINE "find $LOCKREPO64/$reponame/ -name '*.rpm' -or -name 'empty' | wc -l")
        if [ "$RPMCOUNT" == "0" ]
        then
                ssh $LOCKMACHINE "echo \"`date`: the $LOCKREPO64/$reponame channel contains no RPMs and no file called 'empty'. Skipping for safety reasons.\"  >> unity-repo/ibiblio_sync_errors.log"
        else
        	lftp -c "open -e 'mirror -r -e --ignore-time -v . '"$REPODIR64"$reponame  "$REPOURL64"$reponame"
	fi

        # make sure that comething horrible didn't happen and that we are not about to whipe out the entire contents of the repo
        # the side effect is that if the devel server has an empty channel (one without *.rpm of file with name of empty) then old RPMS won't be cleaned up
        RPMCOUNT=$(ssh $LOCKMACHINE "find $LOCKREPOARM/$reponame/ -name '*.rpm' -or -name 'empty' | wc -l")
        if [ "$RPMCOUNT" == "0" ]
        then
                ssh $LOCKMACHINE "echo \"`date`: the $LOCKREPOARM/$reponame channel contains no RPMs and no file called 'empty'. Skipping for safety reasons.\"  >> unity-repo/ibiblio_sync_errors.log"
        else
        	lftp -c "open -e 'mirror -r -e --ignore-time -v . '"$REPODIRARM"$reponame  "$REPOURLARM"$reponame"
	fi
done

echo "====================== Done with deleting local content ========================="

# Clean up after ourselves
ssh $LOCKMACHINE "chmod u+w $LOCKREPO32/*"
ssh $LOCKMACHINE "chmod u+w $LOCKREPO64/*"
ssh $LOCKMACHINE "chmod u+w $LOCKREPOARM/*"
ssh $LOCKMACHINE "rm -f $LOCKBASE/$HOSTNAME.$$"

echo "========================== Updating Timestamp =============================="
perl -e 'printf "%s\n", time' > $REPOPATH/TIME
