<?php

require_once('settings.php');
require_once('cleanup_dups.php');
require_once('cleanup_promote.php');

auth_user();

if(isset($_REQUEST['action'])) {
	switch ($_REQUEST['action']) {
	case 'disp_dups': 
		display_duplicates_report(); 
		break;
	case 'process_dups':
		process_duplicates();
		break;
	case 'confirm_dups':
		delete_duplicates();
		break;

	case 'disp_promote':
		display_promote_report();
		break;
	case 'prom_find_pattern':
		display_found_by_pattern();
		break;
	case 'process_prom':
		process_promote_selection();
		break;
	case 'confirm_prom':
		commit_promote_selection();
		break;

	case 'last_modified_info':
		show_last_modified_info();
		break;

	default:
		print_debug("Invalid action requested\n");
	}
} else {
	remove_dups_sesson();
	remove_cleanup_session();

	print "<p/>This page can be used to cleanup the repositories. Please selection your cleanup action:";
	print "<ul>\n";
	print "  <li><a href='" . session_link() . "&action=disp_dups'>Retire duplicate packages</a></li>\n";
	print "  <li><a href='" . session_link() . "&action=disp_promote'>Promote packages to intended channels</a></li>\n";
	print "</ul>\n";
}

####################################################
#   Supporting function
####################################################

# this function will fetch the most recent history on an RPM
function show_last_modified_info()
{
	$file = urldecode($_REQUEST['file']);
	$arch = urldecode($_REQUEST['arch']);

	$info = fetch_rpm_history($file, $arch);
	if (array_key_exists('0', $info)) {
		print $info[0]['RpmName'] . " in " . $info[0]['arch'] . " repo was last modified by " . $info[0]['LastModifiedBy'] . " on " . $info[0]['LastModifiedOn'] . " with action: " . $info[0]['LastMod'] . "<p/>\n";
	} else {
		print "There is no record of " . $_REQUEST['file'] . " in " . $_REQUEST['arch'] . " repo<p/>\n";
	}
}

# checks to see if the user is allowed to manipulate the RPM
# return s array (can_see, can retire)
function is_user_allowed_to_manip($file, $arch)
{
	# default to failsafe
	$can_see = false;
	$can_retire = false;

	# users with admin privs can do anything
	# so save the CPU and return right away
	if (is_admin()) {
		$can_see = true;
		$can_retire = true;
		return array($can_see, $can_retire);
	}

	# noarch channels are treated special
	if (preg_match('/.*(noarch|i586|x86_64)\.rpm/', $file, $match)) {
		if ($match[1] == 'noarch') {
			$arch .= '/noarch';
		}
	}

	# Let's get some info on this RPM
	$info = fetch_rpm_history($file, $arch);

	if (array_key_exists('0', $info)) {
		# if there is information on this RPM in the table ...
		if (($info[0]['CreatedBy'] == $_SESSION['userName'])) {
			$can_see = true;
			if (is_normal()) {
				$can_retire = true;
			}
		}
	} else {
		# the rpms table does not yet have an entry for this file, so treat it as though it's modifyable
		$can_see = true;
		if (is_normal()) {
			$can_retire = true;
		}
	}

	$debug = "The values are: can_see=";
	if ($can_see) {
		$debug .= '1 ';
	} else {
		$debug .= '0 ';
	}
	$debug .= 'can_retire=';
	if ($can_retire) {
		$debug .= '1 ';
	} else {
		$debug .= '0 ';
	}

	return array($can_see, $can_retire);
}

function remove_dups_sesson()
{
	unset($_SESSION['dups']);
}

function remove_cleanup_session()
{
	unset($_SESSION['promote']);
	unset($_SESSION['prom_conf']);
}

?>

