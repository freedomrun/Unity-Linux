<?php

require_once('settings.php');

function authenticate ($userName, $pwd, $sn) {
	global $database_name;
	global $database_instance;

	$database_instance = new mysql_db($database_name, $userName, $pwd, $status);

	if ( $status ) {
		begin_bs_session($sn);

		$_SESSION['userName'] = $userName;
		get_user_privs($normal, $admin, $super, $active);

		if (!$active) {
			print "Your account is INACTIVE. Please contact one of the administrators to re-enable it.\n";
			return false;
		}
		
		$_SESSION['pwd'] = $pwd;
		$_SESSION['loggedIn'] = 'youAreLogged';
		$_SESSION['sn'] = $sn;
		$_SESSION['is_normal'] = $normal;
		$_SESSION['is_admin'] = $admin;
		$_SESSION['is_super'] = $super;

		return true;
	} else {
		return false;
	}
}

if(isset($_POST['submit1']))
{
	if (!get_magic_quotes_gpc()) {
		$s_loginid = addslashes($_POST['loginid']);$s_pwd = addslashes($_POST['pwd']);
	} else {
		$s_loginid = $_POST['loginid']; $s_pwd = $_POST['pwd'];
	}

	if(authenticate($s_loginid, $s_pwd, $_POST['sn']) == true)
	{
		$redirect = "Location:main.php" . session_link();
		header($redirect);
	}
	else
	{
		echo '<html> <head> <link rel="stylesheet" type="text/css" href="style-sheet.css"/> </head> ';
		echo "\n<body>\n<br/><br/><br/>";
		echo '<P style="font-size:16px;font-weight:bold;text-align:center;color:maroon;">Either username or password is Incorrect.<br/>';
		echo "\n<br/><a href='javascript:window.location=\"index.php\"' id=\"try\" name=\"try\">Try Again!</a><br/>";
		echo '<br/></P>';
		echo "\n</html>";
		exit;
	}
}

?>

<form name="form1" action="" method="post" >

<FIELDSET style="border-style:solid;border-width:3px;border-color:brown;noshade:noshade;" >
<LEGEND align="center" style="color:brown;padding-left:1px;padding-right:1px;font-size:14px;font-weight:bold;" >Unity Linux Build Server Sign In</LEGEND>
<br />
<br />
<br />
<table align="center" cellspacing="0px" cellpadding="6px" border=0>
  <tr>
    <td align="left"><SPAN class="label">Login ID:</SPAN></td>
    <td align="left"><input type="text" name="loginid" size=15 maxlength=40 tabindex="1" /></td>
  </tr>
  <tr>
    <td align="left"><SPAN class="label">Password:</SPAN></td>
    <td align="left"><input type="password" name="pwd" size=15 maxlength=40 tabindex="2" /></td>
  </tr>
  <tr align="center">
    <td colspan=2><input type="submit" name="submit1" value="Login"></td>
  </tr>
  <tr>
    <td />
    <td align="center" />
  </tr>
</table>
</FIELDSET>

<input type="hidden" name="sn" value="<?php echo uniqid(); ?>">
</form>

