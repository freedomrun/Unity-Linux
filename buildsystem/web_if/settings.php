<?php

# the BS database information
$database_name = 'BS';
$database_locaiton = 'localhost';
$database_instance = null;

# how the session information is accessed in the database
$session_user_username = 'session_user';
$session_user_passwd = 'session_passwd';

# details about various path
exec('unity_repo_details.sh -d', $output, $retval);
$server_repo_base_path = $output[0];

# rpm repo dir
exec('unity_repo_details.sh -r', $output2, $retval);
#$repo_path = "$server_repo_base_path/$output2[0]";
$repo_path = "$output2[0]";

# retire repo dir
exec('unity_repo_details.sh -x', $output3, $retval);
$retired_rpm_path = "$output3[0]";

# repo channels
exec('unity_repo_details.sh -e', $output4, $retval);
$repo_channels = split(" ", $output4[0]);

# packages svn path
exec('unity_repo_details.sh -m', $output5, $retval);
$packages_path = "$output5[0]";

# projects svn path
exec('unity_repo_details.sh -n', $output6, $retval);
$projects_path = "$output6[0]";

# web script path
$bs_scripts_path='/var/www/scripts/';


# Define which database table to access for the various distribution packages
# All package tables are named 'pkgs$suffix'.
$pkgs_table_suffix['unity'] = '';
$pkgs_table_suffix['mdv'] = '_mdv';

# How to access SVN over the web
$web_svn['']['package'] = '<a href="http://dev.unity-linux.org/projects/unitylinux/repository/show/packages/%s">%s</a>';
$web_svn['']['commit'] = '<a href="http://dev.unity-linux.org/projects/unitylinux/repository/revisions/%s">%s</a>';
$web_svn['_mdv']['package'] = '<a href="http://svn.mandriva.com/cgi-bin/viewvc.cgi/packages/cooker/%s">%s</a>';
$web_svn['_mdv']['commit'] = '<a href="http://svn.mandriva.com/cgi-bin/viewvc.cgi/packages?view=revision&revision=%s">%s</a>';

// turn on the debugging messages from BS
#$debug = false;
$debug = true;

//Turn on display_errors
ini_set('display_errors','1');

// Display ALL errors including notices
error_reporting (E_ALL);

// The BS is located in Mountain Time Zone
date_default_timezone_set('America/Denver');

// Display the fortunes in the header
$show_fortunes = true;
$path_to_fortune = '/usr/games/fortune';


// Pull in the necessary Build Server files
require_once('sessions.php');
require_once('buildserver_methods.php');
require_once('sge.php');
require_once('tabbed_forms.php');

?>
