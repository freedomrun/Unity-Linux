<?php
//phpinfo();
/*
 *  This script does:
 *  1) authenticate the user
 *     user is just mysql db user; but must exist in the db.  admin adds.
 *  2) show all status information for this particular build of this particular pkg.
 *     
 */

require_once('settings.php');
auth_user();

if (!isset($_REQUEST['jobid'])) {
	echo "You must pass valid job id<br>\n";
} else {
	$jobid = $_REQUEST['jobid'];
	if (isset($_REQUEST['viewlog'])) {
		if (!isset($_REQUEST['logfile'])) {
			print "You must pass a valid logfile.<p/>";
		} else {
			display_log($jobid, $_REQUEST['logfile'], $_REQUEST['viewlog']);
		}
	} else {
		display_pkg_stats($jobid);
	}
}

function display_log($jobid, $file, $type)
{
	$filename = "build_logs/" . $file . ".$type$jobid";
	if (!file_exists($filename)) {
		print "Cannot display logfile for $filename<p/>";
	}

	$log = @file_get_contents($filename);
	$log = str_replace("\n", "<br/>\n", $log);
	print $log;
}

function display_pkg_stats($jobid)
{
	$items=fetch_pkg_stats($jobid);
	$num_rows=count($items);
	if ($num_rows > 0 ) {
		echo "<H3>Job ID: " . $jobid . "</H3>\n";
		foreach ($items as $row) {
			_start_table(array('', ''));
			
			$columns = array();
			$columns[] = array('data' => "<b>Package:</b>");
			$columns[] = array('data' => GetLinkToSvnPackage($row['pkgs_prefix'], $row['pkg_name'], $row['pkg_name'] . '-' . $row['pkg_ver'] . '-' . $row['pkg_rel']));
			_disp_table_row($columns);

			$columns = array();
			$columns[] = array('data' => "<b>Version:</b>");
			$columns[] = array('data' => $row['pkg_ver']);
			_disp_table_row($columns);

			$columns = array();
			$columns[] = array('data' => "<b>Committer:</b>");
			$columns[] = array('data' => $row['committer']);
			_disp_table_row($columns);

			$columns = array();
			$columns[] = array('data' => "<b>Commit #</b>");
			$columns[] = array('data' => GetLinkToSvnCommit($row['pkgs_prefix'], $row['commit'], $row['commit']));
			_disp_table_row($columns);

			$columns = array();
			$columns[] = array('data' => "<b>Log Message:</b>");
			$columns[] = array('data' => $row['log_msg']);
			_disp_table_row($columns);

			$columns = array();
			$columns[] = array('data' => "<b>Pkg Summary:</b>");
			$columns[] = array('data' => $row['pkg_summary']);
			_disp_table_row($columns);

			$columns = array();
			$columns[] = array('colspan' => 2, 'data' => "<center><form name='build_list' action='avail.php" . session_link() . "' method='post'><INPUT TYPE=SUBMIT VALUE='Reschedule Build'><input type='hidden' name='" . $row['pkgs_prefix']  ."_rebuild' value='" .  $row['pkg_name']. "'></form></center>");
			_disp_table_row($columns);

			_end_table();
		}

		echo "<center>";
		$items1=fetch_buildevents($jobid);
		echo "<H3>BuildEvents</H3>\n";
		_start_table(array('Event', 'Time'));
		foreach ($items1 as $row1) {
			$columns = array();
			$columns[] = array('data' => $row1['event']);
			$columns[] = array('data' => $row1['TS']);
			_disp_table_row($columns);
		}
		_end_table();
		echo "<br/>";



		// Ok, put the prebuild chk table here
		//

		$items1=fetch_prebuild_checks($jobid);
		echo "<H3>Prebuild Checks</H3>\n";
		_start_table(array('Check', 'Status'));
		foreach ($items1 as $row1) {
			$bgstr = "bgcolor='lightgreen'";
			$status = 'Pass';
			if ($row1['pass'] == 0) {  // In mysql false=0
				$bgstr="bgcolor=\"lightpink\"";
				$status = 'Fail';
			}
			$columns = array();
			$columns[] = array('tdformat' => $bgstr, 'data' => $row1['tag']);
			$columns[] = array('tdformat' => $bgstr, 'data' => $status);
			_disp_table_row($columns);
		}
		_end_table();
		echo "<br/>";

		// *****************************************
		echo "<H3>Build Checks</H3>\n";
		_start_table(array('Check', 'Status', 'Output'));
		$items1=fetch_build_checks($jobid);
		foreach ($items1 as $row1) {
			$bgstr = "bgcolor='lightgreen'";
			$status = 'Pass';
			if ($row1['pass'] == 0) {  // In mysql false=0
				$bgstr="bgcolor=\"lightpink\"";
				$status = 'Fail';
			}
			$columns = array();
			$columns[] = array('tdformat' => $bgstr, 'data' => $row1['tag']);
			$columns[] = array('tdformat' => $bgstr, 'data' => $status);
			$columns[] = array('tdformat' => $bgstr, 'data' => $row1['note']);
			_disp_table_row($columns);
		}
		_end_table();
		echo "<br/>";


		// *****************************************
		echo "<H3>PostBuild Checks</H3>\n";
		_start_table(array('Check', 'Status', 'Output'));
		$items1=fetch_postbuild_checks($jobid);
		foreach ($items1 as $row1) {
			$bgstr = "bgcolor='lightgreen'";
			$status = 'Pass';
			if ($row1['pass'] == 0) {  // In mysql false=0
				$bgstr="bgcolor=\"lightpink\"";
				$status = 'Fail';
			}
			$columns = array();
			$columns[] = array('tdformat' => $bgstr, 'data' => $row1['tag']);
			$columns[] = array('tdformat' => $bgstr, 'data' => $status);
			$columns[] = array('tdformat' => $bgstr, 'data' => $row1['note']);
			_disp_table_row($columns);
		}
		_end_table();
		echo "<br/>";

		// *****************************************
		echo "<H3>RPMs produced by this job</H3>\n";
		_start_table(array('arch', 'Name'));
		foreach (fetch_built_rpms($jobid) as $row) {
			$columns = array();
			$columns[] = array('data' => $row['arch']);
			$columns[] = array('data' => $row['RpmName']);
			_disp_table_row($columns);
		}
		_end_table();
		echo "<br/>";

		// *****************************************
		echo "<H3>Logfiles</H3>\n";
		$items1=fetch_build_stats($jobid);
		$logfile=$items1[0]['pkg_name'] . "_"  . $items1[0]['submitter'] . "_" . $items1[0]['commit'];
		print "<a href='" . session_link() . "&viewlog=e&logfile=" . urlencode(basename($logfile)) . "&jobid=$jobid'>Stderr</a>  |  ";
		print "<a href='" . session_link() . "&viewlog=o&logfile=" . urlencode(basename($logfile)) . "&jobid=$jobid'>Stdout</a>";
		echo "<br><br>";

	} else {
		echo "Invalid jobid: $jobid<br>\n";
	}
}

?>
