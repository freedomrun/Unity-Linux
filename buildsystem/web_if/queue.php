<?php
/* This file displays the current queue.  It calls the backend function which then fetches
 * the information.
 *
 */

require_once('settings.php');
auth_user();

$items=get_queue();
if (isset($_REQUEST['jobid'])) {
	$jobid=$_REQUEST['jobid'];
} else {
	$jobid=0;
}

print "<p><center><h3>" . be_avail_readable() . "</h3></center></p>";
_start_table(array('Job ID', 'Package', 'Submitter', 'Date', 'State', 'Load'));
if (!empty($items)) {
	foreach ($items as $job) {
		$bgstr="";
		if ($job['id'] == $jobid) {
			$bgstr="bgcolor=\"lightgreen\"";
		}
		$columns = array();
		$columns[] = array('tdformat' => $bgstr, 'data' => "<a href='pkg.php" . session_link() . "&jobid=" . $job['id'] . "'>" . $job['id'] . "</a>");
		$columns[] = array('tdformat' => $bgstr, 'data' => $job['pkg']);
		$columns[] = array('tdformat' => $bgstr, 'data' => $job['submitter']);
		$columns[] = array('tdformat' => $bgstr, 'data' => $job['date'] . " " . $job['time']);
		$columns[] = array('tdformat' => $bgstr, 'data' => $job['state']);
		$columns[] = array('tdformat' => $bgstr, 'data' => $job['loadavg']);
		_disp_table_row($columns);
	}
}
_end_table();

?>
