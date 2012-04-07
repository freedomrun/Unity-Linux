<?php

require_once('settings.php');
auth_user();

$others = 0;
foreach (Session::get_active_sessions() as $detail) {
	if (isset($detail['name']) && ($detail['name'] != '') && ($detail['name'] != $_SESSION['userName'])) {
		$others++;
	}
}

echo "Welcome to the Unity Linux Build Server. Please use the menu options to the left to select your desired action.<p>";
echo "There are $others other logged in users right now.<br/>The server status is: <u>" . be_avail_readable() . "</u><br/>\n";
echo "Since there is still lots of activity going on for the Build Server, the best way to relay our progress is to look directly in our SVN.";

print "<iframe width='95%' height='700' src='http://dev.unity-linux.org/projects/unitylinux/repository/show/projects/buildsystem'></iframe>\n";

?>
