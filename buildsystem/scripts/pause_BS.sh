#!/bin/bash

# This script pauses the SGE and waits for the currently active job to finish
# before returning.

if [ "$USER" != "mdawkins" -a "$USER" != "builduser" ];
then
   echo "You dont' have sufficient svn privs to run this script."
   exit 1
fi


source /usr/share/gridengine/default/common/settings.sh


# softstop kills the sge_execd daemon without killing the job
#/usr/bin/sge_execd softstop 
sudo /etc/init.d/sge_execd softstop

# now fetch the active job
jobid=$(qstat -s r -q all.q -u "*" | tail -n -1 | awk {'print $1'})

# a postbuild script updates the db at the end of the job.  
# we just poll the db waiting for this update that tells us
# this job is done.
#Not sure this is the best way, but need to investigate a better way
if [ "$jobid" != "" ]; then
   echo "Waiting on Job $jobid to finish"

   while /bin/true
   do
      res=$(mysql -s -u insertevent -pinsertevent BS -e "select count(*) from jobs_history where job_id=$jobid and stage='Build Stop'")
      if [ "$res" == "1" ]
      then  
         echo -n "."
      else 
	 echo ""
	 echo "Job $jobid done"
         break
      fi
      sleep 1
   done
else
   echo 'No Running job'
fi
