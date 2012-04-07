<?php

require_once('settings.php');
auth_user();

print "<H1>Repo Error Reports</H1>";
print "<ul>";
print "  <li><a href='" . session_link() . "&action=error_32'>32-bit repo errors</a></li>";
print "  <li><a href='" . session_link() . "&action=error_64'>64-bit repo errors</a></li>";
print "</ul>\n";

if (isset($_REQUEST['action'])) {
	global $bs_scripts_path;

	$error_file = '';
	if ($_REQUEST['action'] == 'error_32') {
		$error_file = "$bs_scripts_path/rpmcheck.out.32.txt";
		$error_report_type = '32-bit';
	} else if ($_REQUEST['action'] == 'error_64') {
		$error_file = "$bs_scripts_path/rpmcheck.out.64.txt";
		$error_report_type = '64-bit';
	}

	$file = @file_get_contents($error_file);
	if (!$file) {
		print "Error processing error report file '$error_file'\n";
	} else {
		$output = '';

		foreach (explode("\n", $file) as $line) {
			$line = preg_replace('/^=\s+(.*)\s+=/', "<b>$1</b>", $line);
			$output .= "$line<br/>";
		}
	#	$file = str_replace("\n", "<br/>", $file);

		print "<h2>$error_report_type error report:</h2> $output";
	}
}

?>
