#!/bin/bash

# This script does the actual job file creation.  The  BS is based around Sun's (now Oracle's) Grid Engine, which uses 'job files'.   The PHP script calls this script which:
# 1) creates a job file that consists of the command to build the RPM (bldchrt)
# 2) submits the job file to the grid engine
# 3) creates a record in the jobs table that states a job has been submitted


## A job file consists of:
# 1) running pre-build scripts.
# 2) recoriding pre-build status in the jobs table
# 3) actually building the RPM
# 4) recording build status in the jobs table
# 5) running post-build scripts
# 6) recording post-build status in the jobs table


if [  $# -lt 4 ]; then
	echo "Usage: $0 <package name> <commit> <user> <target> [pkgs_table_prefix]" # the fifth argument should really become mandatory with no default
	echo "   This script creates an job file for SGE and then "
	echo "   schedules that jobfile in the queue."
	echo ""
	exit 1
fi

pkg=$1
commit=$2
user=$3
target=$4
if [ -z "$5" ]
then
	pkgs_table_prefix=''
else
	pkgs_table_prefix=$5
fi

BS_SCRIPT_PATH="/var/www/scripts"
logdir="/var/www/secure/BS/build_logs"

#tmpfname=$(TMPDIR="" mktemp -p ${logdir} ${pkg}_${user}_${commit})
tmpfname="${logdir}/${pkg}_${user}_${commit}"
cd $logdir
rm -fr $tmpfname

echo "Creating: $tmpfname"
cat >> $tmpfname << EOF
#$tmpfname $commit
$BS_SCRIPT_PATH/run_prescripts.sh \$JOB_ID $pkg

mysql -u insertevent -pinsertevent BS -e"update jobs set stage='Building', tag='Build Start', note='', TS=now() where job_id=\$JOB_ID"

# added x switch, so if 64bit fails don't continue to 32bit
sudo -n /usr/bin/bldchrt -B -xb-Bcrk $pkg

$BS_SCRIPT_PATH/parse_build_checks.pl /tmp/$pkg.log \$JOB_ID

str=\$(mysql -s -u insertevent -pinsertevent BS -e"select pass from jobs_history where job_id=\$JOB_ID and pass=0 limit 1")
if [ "\$str" == "" ]; 
then
   status="TRUE"
   stage="Built";
   $BS_SCRIPT_PATH/run_postscripts.sh \$JOB_ID $pkg $tmpfname $commit $user $target
else
   status="FALSE"
   stage="Not Built";
fi

mysql -u insertevent -pinsertevent BS -e"update jobs set stage='\$stage', tag='Build Stop', note='', pass=\$status, TS=now() where job_id=\$JOB_ID"

EOF
chmod 0555 $tmpfname

#cmdstr="/var/www/scripts/schedulepkg.sh $tmpfname"
source /usr/share/gridengine/default/common/settings.sh
cd $logdir
#cmdstr="sudo -E -H -u builduser qsub-ge -cwd -S /bin/bash -V $tmpfname"
cmdstr="sudo -E -H -u builduser /usr/bin/qsub-ge -cwd -S /bin/bash -V $tmpfname"
echo "Executing: $cmdstr"
jobsubstr=$($cmdstr)
#$cmdstr
jobnum=$(echo $jobsubstr | grep "^Your job " | awk '{print $3}')
echo "JobNum: $jobnum"

mysql -u insertevent -pinsertevent BS -e"insert into jobs (job_id,pkg_name, commit, submitter, stage, pass, TS, pkgs_prefix) values ($jobnum, '$pkg', '$commit', '$user', 'Queued', TRUE, now(), '$pkgs_table_prefix')"
 
