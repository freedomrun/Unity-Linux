<?php

require_once('settings.php');
auth_user();

print "<p/><b>User Settings:</b>\n";

if(isset($_REQUEST['change_pwd']))
{
	if (!get_magic_quotes_gpc()) {
		$s_oldpwd  = addslashes($_REQUEST['old_pwd']);
		$s_newpwd1 = addslashes($_REQUEST['new_pwd']);
		$s_newpwd2 = addslashes($_REQUEST['new_pwd2']);
	} else {
		$s_oldpwd  = $_REQUEST['old_pwd'];
		$s_newpwd1 = $_REQUEST['new_pwd'];
		$s_newpwd2 = $_REQUEST['new_pwd2'];
	}

	# if the password used to start the session does not match
	# what the user has provided as a password for the "old password"
	# the ignore this request
	if ($s_oldpwd != $_SESSION['pwd']) {
		print "Your old password does not match our records. Please try again.<p/>";
	} else if ($s_newpwd1 != $s_newpwd2) {
		print "You misstyped the new password. Please try again.<p/>";
	} else {
		# the old password was correct. Now check to see if the new
		# password is strong enough.
		if (! preg_match("/^.*(?=.{8,})(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).*$/", $s_newpwd1)) {
			print "Your password is too weak. Please try again.<p/>";
		} else {
			if (change_user_passwd($s_newpwd1)) {
				print "Successfully changed the password.<p/>";
				$_SESSION['pwd'] = $s_newpwd1;
				session_write_close();
				exit;
			} else {
				print "An error occurred while changing the password.</p>";
			}
		}
	}
}

$passwd_change_form = <<<END
<table>
  <tr>
    <td>Old Password:</td>
    <td><input type="password" name="old_pwd" size=15 maxlength=40 tabindex="1" /></td>
  </tr>
  <tr>
    <td>New Password:</td>
    <td><input type="password" name="new_pwd" size=15 maxlength=40 tabindex="2" /></td>
  </tr>
  <tr>
    <td>Retype New Password:</td>
    <td><input type="password" name="new_pwd2" size=15 maxlength=40 tabindex="3" /></td>
  </tr>
  <tr>
    <td colspan='2'><center><input type="submit" name="change_pwd" value="Change"></td>
  </tr>
</table>
<p/>
<ul>
  <li>Must be at least 8 characters long
  <li>Must contain at least one upper case letter
  <li>Must contain at least one lower case letter
  <li>Mult contain at least one digit
</li>
END;

add_tab("Change Password", $passwd_change_form);
display_tabs('500px');


?>

