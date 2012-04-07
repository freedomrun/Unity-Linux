<?php

/* All functionality that is tied to the Sun Grid Engine (SGE) is put in this file.  
 * The frontend (web i/f) calls these functions to talk to the SGE.
 *
 */


/*possible status contitions of backend
 * master not running
 * slave not running
 * master and slave both running
 */
$BE_AVAIL=0;     // master and exec(slave) both running
$BE_MSTRAVAIL=1; // master running; execd not
$EBE_AVAIL=2;    // neither running
$BE_NAMES = array(
	$BE_AVAIL     => "<font color='#33cc00'>Both backend server and execution daemon are running.</font>",
	$BE_MSTRAVAIL => "<font color='#cc6600'>The execution daemon is not running. Job submission is enabled but jobs will not actually run until the daemon is re-enabled.</font>",
	$EBE_AVAIL    => "<font color='#cc0000'>The backend server is not running. Job submission is disabled until the backed is running.</font>",
);

function get_queue()
{
/*
This function does a system() or exec() to 'qstat -q all.q' and catches the output.
job-ID  prior   name       user         state submit/start at     queue         slots ja-task-ID 
-----------------------------------------------------------------------------------------------------------------
75 0.55500 sudo       builduser    r     02/07/2010 23:36:27 all.q@cheetos        1        
76 0.55500 sudo       builduser    qw    02/07/2010 23:36:20                      1        
77 0.55500 sudo       builduser    qw    02/07/2010 23:36:21                      1        


and returns an array with the current jobs in the queue
 */


	exec('source /usr/share/gridengine/default/common/settings.sh; qstat -r -q all.q -u "*"',  $queue_output, $retval);

	// strip off the first two lines.  They're column headers.
	array_shift($queue_output);
	array_shift($queue_output);

	$cntr=0;
	foreach($queue_output as $temp_output) {

		if (strpos($temp_output, "Full jobname:") != FALSE) {
			list($blah,$jobname)=preg_split("/:/", trim($temp_output));
			// the job name consists of the pkg plus commit #, so we fetch those out for later use.
			$extpos=strrpos($jobname,'.');
			$svnpos=strrpos($jobname,'_');
			$userpos=strrpos($jobname, "_", -(strlen($jobname) - $svnpos+1));
			$fullpkgname=substr($jobname,0,$userpos);
			$user=substr($jobname,$userpos+1,$svnpos-$userpos-1);
			$commit=substr($jobname,$svnpos+1,$extpos-$svnpos-1);

			$jobarr[$cntr]['id']=$jobid;
			$jobarr[$cntr]['loadavg']=$loadavg;
			$jobarr[$cntr]['pkg']=trim($fullpkgname);
			//$jobarr[$cntr]['commit']=trim($commit);
			$jobarr[$cntr]['submitter']=trim($user);
			$jobarr[$cntr]['state']=$state;
			$jobarr[$cntr]['date']=$submitdate;
			$jobarr[$cntr]['time']=$submittime;
			$cntr++;
		} else if (strpos($temp_output, "Hard Resources:") != FALSE) {
		} else if (strpos($temp_output, "Soft Resources:") != FALSE) {
		} else if (strpos($temp_output, "Master Queue:") != FALSE) {
		} else {
			@list($jobid,$loadavg, $pkgname, $submitter,$state,$submitdate,$submittime,$queuename,$slot)= preg_split("/[\s]+/",trim($temp_output));
		}
	}
	if (isset($jobarr)) {
		return $jobarr;
	} else {
		return NULL;
	}
}

/* Check to see if backend is running */
function be_avail()
{
	global $BE_AVAIL;     // master and exec(slave) both running
	global $BE_MSTRAVAIL; // master running; execd not
	global $EBE_AVAIL;    // neither running
	exec('ps aux | grep -v "grep " | grep -q sge_qmaster',  $queue_output, $mstr_retval);
	exec('ps aux | grep -v "grep " | grep -q sge_execd',  $queue_output, $exec_retval);

	/* how to report exec is waiting for current job to complete? */

	if (($mstr_retval == 0) && ($exec_retval == 0)) {$retval=$BE_AVAIL;}
	if (($mstr_retval == 0) && ($exec_retval == 1)) {$retval=$BE_MSTRAVAIL;}
	if (($mstr_retval == 1) && ($exec_retval == 1)) {$retval=$EBE_AVAIL;}
	return $retval;
}

function be_avail_readable()
{
	global $BE_AVAIL; 
	global $BE_MSTRAVAIL;
	global $EBE_AVAIL;
	global $BE_NAMES;

	return $BE_NAMES[be_avail()];
}

?>
