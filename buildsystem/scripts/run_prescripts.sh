# This script is called before a package is actually built.  It's used for sanity/safety checks.
#  This script runs thorugh all scripts located in the prebuild/ subdir.
#  The prebuild/ scripts return an exit code. This exit code is then recorded in the jobs table.
#  The script must be passed a jobid, pkg name.  This information is passed
#  to the prebuild/ scripts.

jobid=$1
pkg=$2
cd /var/www/scripts
retval=0
for tmp in $(ls prebuild/*.sh)
do
   check=$(basename $tmp .sh)
   $tmp $pkg
   value=$?
   if [ $value -eq 0 ]; then
     status="TRUE"
   else
     status="FALSE"
   fi
  mysql -u insertevent -pinsertevent BS -e"update jobs set stage='PreBuild', tag='$check', pass=$status, TS=now() where job_id=$jobid"

done
cd -
exit $retval
