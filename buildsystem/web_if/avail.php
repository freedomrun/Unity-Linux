<?php
//phpinfo();
/*
 *  This script does:
 *  1) list all packages that are available to the user for submission
 *     a query returns this list; for admins it is ALL unbuilt committed pkgs, 
 *     for newbies it is just pkgs they have comitted to svn but not successfully build yet
 *     also displayed:
 *        committer, commit date, svn_ver/link to svn, commit msg
 *     we don't update the status table during build because if the job
 *     gets cancelled we have no way to guarantee the table gets updated to state that.
 *     so we'll just query against the currently queued jobs.
 *  3) submit selected pckgs for build
 *     
 */

require_once('settings.php');
auth_user();

print "<p><center><h3>" . be_avail_readable() . "</h3></center></p>";
if (be_avail()==$EBE_AVAIL) {
	print "You can view available packages, but you will not be able to submit them for build.<br>\n";
}

/* ******************************** */
function create_jobfile ($pkg, $svnver, $target, $type) 
{
	global $bs_scripts_path;

	$jobid=0;
	$cmdstr = "$bs_scripts_path/createjob.sh $pkg $svnver " . $_SESSION['userName'] . " $target $type";
	# print_debug("Cmd str: $cmdstr\n");

	exec($cmdstr, $output, $retval);
	foreach ($output as $row) {
		#echo "DEBUG: " .$row . "<br>";
		if (substr($row, 0, 7) == "JobNum:") {
			$jobid = trim(substr($row, 7));
			//echo "JOBNUM!!!! $jobid\n";
			break;
		}
	}
	return $jobid;
}

/* ********************************************** */
/* Display all the MDV cooker packages that this user can submit for building.
 * The package needs to be listed in the db table and have a pkginfo file
 */
function display_avail_pkgs_mdv()
{
	global $BE_AVAIL, $BE_MSTRAVAIL, $repo_path, $pkgs_table_suffix, $packages_path, $projects_path;
	$retval = be_avail();
	$action_button = "<INPUT TYPE=SUBMIT VALUE='Schedule MDV Build'>";

	echo "You can submit any of the following Mandriva Cooker packages for building on the build server<br>\n";
	echo "<form name='build_list_mdv'><p align='center'>" . session_link(false);
	if ($retval==$BE_AVAIL || $retval==$BE_MSTRAVAIL) {
		echo "<center>$action_button</center><br/>";
	}

	print "Search: <input type='text' name='mpackage' /><input type='submit' value='Submit' /><input type='hidden' name='mpage' value=1><br/>\n";

	$cur_page = 1;
	if (array_key_exists('mpage', $_REQUEST)) {
		$cur_page = $_REQUEST['mpage'];
	}
	$package = '';
	if (array_key_exists('mpackage', $_REQUEST)) {
		$package = $_REQUEST['mpackage'];
	}

	$rows = fetch_avail_pkgs_mdv('', 0, $package);
	print_pagination_ribbon($rows, $cur_page, $per_page, "&mpage=");

	$items = fetch_avail_pkgs_mdv($cur_page, $per_page, $package);
	_start_table(array('Build?', 'Package', 'Cur Unity Ver', 'commiter', 'log msg', 'Commit', 'Commit Time'));

	if (!empty($items)) {
		$i = 0;
		foreach ($items as $row) {
			$pkginfo_file = "$packages_path/" . $row['pkg_name'] . "/" . $row['pkg_name'] . ".pkginfo";
			if (file_exists($pkginfo_file)) {
				$output = array();
				exec("perl $projects_path/anyutils/dump_rpm_tags.pl `find $repo_path/i586/ -name '" . $row['pkg_name'] . "-[1234567890]*' -type f | head -1` VERSION RELEASE", $output, $retval);
				if (isset($output[0]) && isset($output[1])) {
					$unity_ver = $output[0] . '-' . $output[1];
				} else {
					$unity_ver = 'unknown';
				}

				$columns = array();
				$columns[] = array('data' => "<input type='checkbox' name='". $pkgs_table_suffix['mdv']  . "_pkg_$i' value='" . urlencode($row['pkg_name']) . "'>");
				$columns[] = array('data' => GetLinkToSvnPackage($pkgs_table_suffix['mdv'], $row['pkg_name'], $row['pkg_name'] . "-" . $row['pkg_ver'] . "-" . $row['pkg_rel']));
				$columns[] = array('data' => $unity_ver);
				$columns[] = array('data' => $row['committer']);
				$columns[] = array('data' => $row['log_msg']);
				$columns[] = array('data' => GetLinkToSvnCommit($pkgs_table_suffix['mdv'], $row['commit'], $row['commit']));
				$columns[] = array('data' => $row['commit_time']);

				_disp_table_row($columns);
				$i++;
			} else {
#				print_debug("The file '$pkginfo_file' not found\n");
			}
		}
	}
	
	_end_table();

	# only allow submitting if the backend is actually ready to accept new jobs
	if ($retval==$BE_AVAIL || $retval==$BE_MSTRAVAIL) {
		echo "<br/>$action_button</p></form>";
	}
	
}

/* **********************************************
 * Display all the packages that this user can submit for building.
 * The package needs to be listed in the db table and
 * be available to this user for building.  Either he/shi submitted it
 * or the user is an admin has access to more than just his/her pkgs.
 * 
 */
function display_avail_pkgs()
{
	global $BE_AVAIL, $BE_MSTRAVAIL, $pkgs_table_suffix;
	$retval=be_avail();
	$action_button = "<INPUT TYPE=SUBMIT VALUE='Schedule Build'>";

	echo"You can submit any of the following Unity Native packages for building on the build server<br>\n";
	echo "<form name=\"build_list\"><p align=\"center\">" . session_link(false);
	if ($retval==$BE_AVAIL || $retval==$BE_MSTRAVAIL) {
		echo "<center>$action_button</center><br/>";
	}

	print "Search: <input type='text' name='upackage' /><input type='submit' value='Submit' /><input type='hidden' name='upage' value=1><br/>\n";

	$cur_page = 1;
	$package = '';
	if (array_key_exists('upackage', $_REQUEST)) {
		$package = $_REQUEST['upackage'];
	}
	if (array_key_exists('upage', $_REQUEST)) {
		$cur_page = $_REQUEST['upage'];
	}

	$rows = fetch_avail_pkgs('', 0, $package);
	print_pagination_ribbon($rows, $cur_page, $per_page, "&upage=");

	_start_table(array('Build?', 'Package', 'commiter', 'log msg', 'Commit', 'Commit Time', 'TS (db update time)'));
	$items = fetch_avail_pkgs($cur_page, $per_page, $package);

	if (!empty($items)) {
		$i = 0;
		foreach ($items as $row) {
			$columns = array();
			$columns[] = array('data' => "<input type='checkbox' name='" . $pkgs_table_suffix['unity']  ." _pkg_$i' value='" . urlencode($row['pkg_name']) . "'>");
			$columns[] = array('data' => GetLinkToSvnPackage($pkgs_table_suffix['unity'], $row['pkg_name'], $row['pkg_name'] . "-" . $row['pkg_ver'] . "-" . $row['pkg_rel']));
			$columns[] = array('data' => $row['committer']);
			$columns[] = array('data' => $row['log_msg']);
			$columns[] = array('data' => GetLinkToSvnCommit($pkgs_table_suffix['unity'], $row['commit'], $row['commit']));
			$columns[] = array('data' => $row['commit_time']);
			$columns[] = array('data' => $row['TS']);

			_disp_table_row($columns);
			$i++;
		}
	}
	_end_table();
	
	# only allow submitting if the backend is actually ready to accept new jobs
	if ($retval==$BE_AVAIL || $retval==$BE_MSTRAVAIL) {
		echo "<br/>$action_button</p></form>";
	}
}

function ConfirmPackages($pkgname)
{
	global $repo_channels, $pkgs_table_suffix;

	print "<H3>Confirm your selection</h3>\n";
	print "<form name='frm_dups' action='" . session_link() . "' method='post'><p/>\n";
	_start_table(array('Package', 'SVN Version', 'Target Channel', 'Confirm'));

	$target = "<select name='%s_tgt_%d'>\n";
	foreach ($repo_channels as $index => $ch) {
		$choice = '';
		if (strtolower($ch) == 'test') {
			$choice = 'selected';
		}
		$target .= "<option $choice value='$ch'>$ch\n";
	}
	$target .= "</select>\n";

	$i = 0;
	foreach ($pkgs_table_suffix as $type) {
		if (array_key_exists($type, $pkgname)) {
			foreach ($pkgname[$type] as $item) {
				$svnver = check_pkg_validity($item, $type);
				if ($svnver > 0) {
					$columns = array();
					$columns[] = array('data' => $item);
					$columns[] = array('data' => $svnver);
					$columns[] = array('data' => sprintf($target, $type, $i));
					$columns[] = array('data' => "<input type='checkbox' name='chk_$i' value='$item'><input type='hidden' name='svn_$i' value='$svnver'");
					_disp_table_row($columns);
					$i++;
				}
			}
		}
	}

	_end_table();
	print "<input type='submit' name='action' value='Confirm'></form><p/>";
}
/* ********************************************** */

/* **********************************************
 * Since anything could be passed via the POST, we need to verify it
 * before actually submitting it.  We just make sure that this pkg is in
 * the db table and submittable by this user.
 */

if(isset($_REQUEST['action'])) {
	global $pkgs_table_suffix;

	$jobid = 0;
	foreach ($_REQUEST as $key => $value) {
		foreach ($pkgs_table_suffix as $type) {
			if (preg_match('/^(' . $type . ')_tgt_(\d+)/', $key, $match)) {
				$i = $match[2];
				if (isset($_REQUEST["chk_$i"]) && isset($_REQUEST["svn_$i"])) {
					$tmp = create_jobfile($_REQUEST["chk_$i"], $_REQUEST["svn_$i"], $_REQUEST[$key], $type);
					if ($jobid == 0) {
						$jobid = $tmp;
					}
				}
			}
		}
	}
	header("Location: queue.php" . session_link() . "&jobid=". $jobid);
}
else
{
	global $pkgs_table_suffix;

	// A user could have selected a buch of checkboxes from the list of available packages
	foreach ($_REQUEST as $key => $value) {
		foreach ($pkgs_table_suffix as $type) {
			if (preg_match('/(' . $type . ')_pkg_(\d+)/', $key, $match)) {
				$pkgname[$match[1]][] = urldecode($value);
			}
		}
	}

	// A user could request to rebuild a package - so process that request also
	foreach ($pkgs_table_suffix as $type) {
		if (isset($_REQUEST[$type . '_rebuild'])) {
			$pkgname[$type][] = urldecode($_REQUEST[$type . '_rebuild']);
		}
	}

	$jobid=0;
	if (isset($pkgname) && count($pkgname)>0) {
		ConfirmPackages($pkgname);
	} else {
		ob_start();
		display_avail_pkgs();
		$unity_pkgs = ob_get_clean();

		ob_start();
		display_avail_pkgs_mdv();
		$mdv_unity = ob_get_clean();

		add_tab("Unity native", $unity_pkgs);
		add_tab("MDV Cooker for Unity", $mdv_unity);
		display_tabs('98%');
	}
}

?>
