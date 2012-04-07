<?php

require_once('settings.php');
auth_user();

if (! array_key_exists('lib', $_REQUEST)) {
	print "<form name='rebuild_for' action='" . session_link() . "' method='post'><p/>\n";
	print "Enter the full library name (i.e. lib64openssl0.9.8): <input type='text' name='lib' /><input type='submit' value='Submit' /></form>\n";
	exit;
}

# $cmd = "smart info smart 2>&1";

$cmd = "for tmp in $(smart query --show-provides " . $_REQUEST['lib']  . " --show-requiredby | gawk -F\"        \" '{ print $2 }' | gawk -F\"@\" '{ print $1 }' | sort | uniq); do smart info \$tmp | grep \"^Source: \" | gawk -F\": \" '{ print $2 }' | sort | uniq ; done";

print "Rebuild list for <b>" . $_REQUEST['lib']  . "</b><br><ul>";

exec($cmd, $output, $retval);

$output = array_unique($output);
foreach ($output as $line) {
	print "<li>$line<br/>";
}

print "</ul>";

?>
