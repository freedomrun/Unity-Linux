<?php

require_once('settings.php');
auth_user();

# make sure that only ADMINs ior higher are able to access this page!
if (!is_admin()) {
	header('Location:main.php' . session_link());
	exit;
}

############################################################
# These are the actions for this page
# ##########################################################

if(isset($_POST['delete_session']))
{
	$current_session_name = session_name();
	session_write_close();

	foreach ($_POST as $sid => $dummy) {
		if ($sid == 'delete_session') continue;

		session_id($sid);
		session_start();
		session_destroy();
	}

	begin_bs_session($current_session_name);
} else if (isset($_REQUEST['create_user'])) {
	if (is_super()) {
		if ($_REQUEST['pwd1'] != $_REQUEST['pwd2']) {
			print "Error: Passwords do not match.\n";
		} else {
			if (is_user($_REQUEST['username'])) {
				print "Error: this user already exists.\n";
			} else {
				if ($_REQUEST['userlevel'] == '') {
					print "Error: need to specify user level.\n";
				} else {
					if (create_user($_REQUEST['username'], $_REQUEST['pwd1'], $_REQUEST['userlevel'], $_REQUEST['active'])) {
						print "Successfully created new user.\n";
					} else {
						print "Error creating new user.\n";
					}
				}
			}
		}
		exit;
	}
} else if (isset($_REQUEST['promo_user'])) {
	if (is_super()) {
		if (($_REQUEST['username'] == '') || ($_REQUEST['userlevel'] == '')) {
			print "Invalid username or level selected.\n";
		}  else {
			$tmp = change_user($_REQUEST['username'], $_REQUEST['userlevel'], $_REQUEST['active']);
			if ($tmp) {
				$msg = "Successfully changed user status for ";
			} else {
				$msg = "There was an error changing the user status for ";
			}
			print $msg . $_REQUEST['username'] . " to " .  $_REQUEST['userlevel'] . " level with " . $_REQUEST['active'] . " status\n";
		}
		exit;
	}
} else if (isset($_REQUEST['delete_user'])) {
	if (is_super()) {
		if ($_REQUEST['username'] == '') {
			print "Error: need to specify username\n";
		} else {
			if (delete_user($_REQUEST['username'])) {
				print "Successfully deleted user.\n";
			} else {
				print "Error deleting user.\n";
			}
		}
		exit;
	}
}


###################################################
# Tab contents for Session Control
# #################################################

$active_users = "<form name='form_delete_session' action='" .  session_link() . "' method='post'>";
$active_users .= <<<END
Currently logged in users<p/>
<table border='1'>
  <tr>
    <td><b>Username</b></td>
    <td><b>Last Active</b></td>
    <td><b>Delete Session</b></td>
  </tr>
END;

foreach (Session::get_active_sessions() as $detail) {
	$active_users .= "<tr><td>&nbsp;" . $detail['name'] . "</td><td>" . $detail['last'] . "</td>";
	$active_users .= "<td><center><input type=\"checkbox\" name='" . $detail['sid'] ."'></center></td></tr>\n";
}
$active_users .= "<tr><td colspan='3'><center><input type='submit' name='delete_session' value='Delete'></td></tr></table></form><p>";


##############################################
# Manage User
##############################################
$all_users = get_all_users();
sort($all_users);

if (is_super()) {
	$user_choice = "<select name='username'>";
	foreach ($all_users as $user) {
		$user_choice .= "<option value='" . $user['user'] . "'>" . $user['user'] . "\n";
	}
	$user_choice .= "<option selected value=''>\n";
	$user_choice .= "</select>\n";

	$user_levels = array('newbie', 'normal', 'admin', 'super');
	$user_level_choice = "<select name='userlevel'>";
	foreach ($user_levels as $level) {
		$user_level_choice .= "<option value='$level'>$level\n";
	}
	$user_level_choice .= "<option selected value=''>\n";
	$user_level_choice .= "</select>\n";

	$status_choice = "<select name='active'><option value='0'>Inactive<option value='1'>Active</select>";


	$promote_user = "Current User Level Report.<br/>\n";
	$promote_user .= "<table border='1'><tr><td><b>Username</b></td><td><b>Level</b></td><td><b>Status</b></td></tr>";
	foreach ($all_users as $user) {
		$status = 'Inactive';
		if ($user['active']) {
			$status = 'Active';
		}
		$promote_user .= "<tr><td>" .  $user['user'] . "</td><td>" . $user['grp'] . "</td><td>$status</td></tr>\n";
	}
	$promote_user .= "</table><p/>\n";

	$promote_user .= "<form name='form_promo_user' action='" .  session_link() . "' method='post'>";
	$promote_user .= "<table border='1'><tr><td><b>Select User:</b></td><td>$user_choice</td></tr>\n";
	$promote_user .= "<tr><td><b>Select New Level:</b></td><td>$user_level_choice</td></tr>\n";
	$promote_user .= "<tr><td><b>Select Status:</b></td><td>$status_choice</td></tr></table>\n";
	$promote_user .= "<input type='submit' name='promo_user' value='Change User'></form>\n";
}


################################################
# Tab contents for New User Creation
################################################
if (is_super()) {
	$create_user = "<form name='form_create_user' action='" .  session_link() . "' method='post'>\n";
	$create_user .= "<table border='1'><tr><td><b>Username:</b></td><td><input type='text' name='username' size=15 maxlength=40 tabindex='1' /></td></tr>\n";
	$create_user .= "<tr><td><b>Password:</b></td><td><input type='password' name='pwd1' size=15 maxlength=40 tabindex='1' /></td></tr>\n";
	$create_user .= "<tr><td><b>Confirm Password:</b></td><td><input type='password' name='pwd2' size=15 maxlength=40 tabindex='1' /></td></tr>\n";
	$create_user .= "<tr><td><b>User Level:</b></td><td>$user_level_choice</td></tr>\n";
	$create_user .= "<tr><td><b>Status:</b></td><td>$status_choice</td></tr></table>\n";
	$create_user .= "<input type='submit' name='create_user' value='Create User'></form>\n";
}


###########################################
# Tab for deleting a user
###########################################
if (is_super()) {
	$delete_user = "<form name='form_delete_user' action='" .  session_link() . "' method='post'>\n";
	$delete_user .= $user_choice;
	$delete_user .= "<input type='submit' name='delete_user' value='Delete User'></form>\n";
}


###############################################
# Display the tabs
###############################################
add_tab("Current Users", $active_users);
if (is_super()) add_tab("Create User", $create_user);
if (is_super()) add_tab("Manage User", $promote_user);
if (is_super()) add_tab("Delete User", $delete_user);

display_tabs();

?>
