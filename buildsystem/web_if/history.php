<?php

/*
 *  This file shows the build history.  It calls a backend function which
 *  fetches the information.
 *     
 */

require_once('settings.php');
auth_user();

print "<br/>";

$cur_page = $_REQUEST['page'];
$rows = fetch_build_history();
print_pagination_ribbon($rows, $cur_page, $per_page, "&page=");

$items = fetch_build_history($cur_page, $per_page);
_start_table(array('Job ID', 'Package', 'Committer', 'Build Submitter', 'Commit Time', 'Stage'));

foreach ($items as $row) {
	$bgstr="bgcolor = 'lightgreen'";
	if ($row['pass'] == 0) {  // In mysql false=0
		$bgstr = "bgcolor='lightpink'";
	}

	$columns = array();
	$columns[] = array('tdformat' => $bgstr, 'data' => "<a href='pkg.php" . session_link() . "&jobid=" . $row['job_id'] . "'>" . $row['job_id'] . "</a>");
	$columns[] = array('tdformat' => $bgstr, 'data' => GetLinkToSvnPackage($row['pkgs_prefix'], $row['pkg_name'], $row['pkg_name'] . "-" . $row['pkg_ver'] . "-" . $row['pkg_rel']));
	$columns[] = array('tdformat' => $bgstr, 'data' => $row['committer']);
	$columns[] = array('tdformat' => $bgstr, 'data' => $row['submitter']);
	$columns[] = array('tdformat' => $bgstr, 'data' => $row['commit_time']);
	$columns[] = array('tdformat' => $bgstr, 'data' => $row['stage']);

	_disp_table_row($columns);
}

_end_table();
print "<br/>";

?>
