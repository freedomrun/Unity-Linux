<?php

require_once('settings.php');
auth_user();

if (isset($_SESSION['loggedIn'])) {

	$tmp = $_SESSION['userName'];
	session_destroy();
	$_SESSION['userName'] = $tmp;
	unset($_SESSION['loggedIn']);
} 

header('Location:index.php');  
exit;  

?>

