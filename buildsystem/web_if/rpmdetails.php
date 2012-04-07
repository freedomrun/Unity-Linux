<?php

require_once('settings.php');
auth_user();

if (!array_key_exists('rpm', $_REQUEST)) {
	print "No RPM was specified. \n";
	exit;
}

$rpm = urldecode($_REQUEST['rpm']);
if (!file_exists($rpm)) {
	print "The speficied RPM '<b>$rpm</b>' does not exist.\n";
	exit;
}

print "<br/>Details for '<b>$rpm</b>'<p/>";

exec("perl $projects_path/anyutils/dump_rpm_tags.pl $rpm", $output, $retval);

_start_table(array('Context', 'Tag', 'Value'));
foreach ($output as $row) {
	if (preg_match('/^(\w+)\.(\w+):\s?(.*)$/', $row, $match)) {
		$columns = array();
		$columns[] = array('data' => $match[1]);
		$columns[] = array('data' => $match[2]);
		$columns[] = array('data' => $match[3]);
		_disp_table_row($columns);
	}	
}
_end_table();


?>
