# This script is used for checking things after a build is done.   This script will
# not be called if the build fails.
#  This script runs thorugh all scripts located in the postbuild/ subdir.
#  The postbuild/ scripts return an exit code. This exit code is then recorded in the jobs table.
#  The script must be passed a jobid, pkg name, jobfile, svn version, and username.  This information is passed
#  to the postbuild/ scripts.
jobid=$1
pkg=$2
jobfile=$3
svnver=$4
user=$5
target=$6
cd /var/www/scripts

for tmp in $(ls postbuild/*.sh postbuild/*.pl)
do
  check=$(basename $tmp .sh)
  outstr=$($tmp $pkg $jobid $jobfile $svnver $user $target)
  value=$?
   if [ $value -eq 0 ]; then
     status="TRUE"
   else
     status="FALSE"
   fi
  mysql -u insertevent -pinsertevent BS -e"update jobs set stage='PostBuild', tag='$check', pass=$status, note='$outstr', TS=now() where job_id=$jobid"


done
cd -
