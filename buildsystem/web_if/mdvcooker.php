<?php

require_once('settings.php');
auth_user();

print "<br/>This page shows the activity of Mandriva Cooker commits. These packages are not currently available for building on the Build Server. This information is provided more as a reference to you so that you can easily see if Mandriva has had some activity on a package that may be of interest to you.<p/>";

print "<form name='mdv_cooker' action='" . session_link() . "'method='post'>\n";
print "Package: <input type='text' name='package' /><input type='submit' value='Submit' /><input type='hidden' name='page' value=1></form><br/>\n";


global $pkgs_table_suffix;
$package = '';
if (array_key_exists('package', $_REQUEST)) {
	$package = $_REQUEST['package'];
}
$cur_page = $_REQUEST['page'];
$rows = fetch_nonunity_pkgs_mdv('', 0, $package);

if ($package != '') {
	print "<b>Showing results only for packages containing '$package'</b><br/>\n";
}

print_pagination_ribbon($rows, $cur_page, $per_page, "&package=$package&page=");

$items = fetch_nonunity_pkgs_mdv($cur_page, $per_page, $package);
_start_table(array('Package', 'Commit', 'Committer', 'Commit Time', 'Log'));

foreach ($items as $row) {
	$columns = array();
	$columns[] = array('data' => GetLinkToSvnPackage($pkgs_table_suffix['mdv'], $row['pkg_name'], $row['pkg_name']));
	$columns[] = array('data' => $row['commit']);
	$columns[] = array('data' => $row['committer']);
	$columns[] = array('data' => $row['commit_time']);
	$columns[] = array('data' => $row['log_msg']);

	_disp_table_row($columns);
}

_end_table();
print "<br/>";

?>
