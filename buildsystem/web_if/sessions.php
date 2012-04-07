<?php

// This is the code that does session authentication for users.
// This relies on the MySQL database backend for permanent storage.
require_once('mysql.php');

/* This assumes the following table:

CREATE TABLE IF NOT EXISTS `sessions` (
   `session` varchar(255) character set utf8 collate utf8_bin NOT NULL,
   `session_expires` int(10) unsigned NOT NULL default '0',
   `session_data` text collate utf8_unicode_ci,
   `username` varchar(30) default NULL,
    PRIMARY KEY  (`session`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

 */

class Session
{
	private static $session_db;

	public static function open()
	{
#		print_debug("Calling session:open()\n");
#		dump(debug_backtrace());

		global $database_name;
		global $session_user_username;
		global $session_user_passwd;

		self::$session_db = new mysql_db($database_name, $session_user_username, $session_user_passwd, $status);
		return $status;
	}

	public static function close()
	{
#		print_debug("calling session:close()\n");
#		dump(debug_backtrace());
		
		return self::$session_db->close();
	}

	public static function read($id)
	{
#		print_debug("Calling Sesion:read($id) and current time is " . mysql_real_escape_string(time()) . "\n");
#		dump(debug_backtrace());
		
		// perform garbage collection
		self::gc(ini_get('session.gc_maxlifetime'));

		$id = mysql_real_escape_string($id);
		$sql = sprintf("SELECT `session_data` FROM `sessions` WHERE `session` = '%s'", $id);
		$info = self::$session_db->query($sql);
		if (isset($info[0])) {
			return $info[0]['session_data'];
		}

		return '';
	}

	public static function write($id, $data)
	{
#		print_debug("Calling Session:Write($id)\n");
#		dump(debug_backtrace());

		$sql = sprintf("REPLACE INTO `sessions` VALUES('%s', '%s', '%s', '%s')",
			mysql_real_escape_string($id),
			mysql_real_escape_string(time()),
			mysql_real_escape_string($data),
			$_SESSION['userName']
		);
		return self::$session_db->query($sql);
	}

	public static function destroy($id) {
#		print_debug("Calling Session::destroy()\n");
#		dump(debug_backtrace());

		$sql = sprintf("DELETE FROM `sessions` WHERE `session` = '%s'", $id);
		return self::$session_db->query($sql);
	}

	public static function gc($max) {
#		print_debug("Calling Session:gc($max)\n");
#		dump(debug_backtrace());
#		print_debug("will try to delete all < " . mysql_real_escape_string(time() - $max) . "\n");

		$sql = sprintf("DELETE FROM `sessions` WHERE `session_expires` < '%s'",
			mysql_real_escape_string(time() - $max));
		return self::$session_db->query($sql);
	}

	function __destruct()
	{
#		dump(debug_backtrace());
	}

	public static function get_active_sessions()
	{
		$list = array();

		$sql = sprintf("SELECT * FROM `sessions`");
		$tmp = self::$session_db->query($sql);

		date_default_timezone_set('America/Denver');

		foreach ($tmp as $details) {
			array_push($list, array(
				'name' => $details['username'], 
				'last' => date("F j, Y, g:i:s a", $details['session_expires']),
				'sid'  => $details['session']
			));
		}

		return $list;
	}
	
};

ini_set('session.gc_probability', 1);
ini_set('session.gc_divisor', 100);
ini_set('session.gc_maxlifetime', 60000); # in seconds
ini_set('session.save_handler', 'user');

session_set_save_handler(
	array('Session', 'open'),
	array('Session', 'close'),
	array('Session', 'read'),
	array('Session', 'write'),
	array('Session', 'destroy'),
	array('Session', 'gc')
);
register_shutdown_function('session_write_close');

function show_sess_vars() {
	foreach ( $_SESSION as $key => $val ) {
		print_debug("Session var '$key': \t'$val'\n");
	}
}

// this function uses session information to see if the user is a normal user (not newbie)
function is_normal()
{
	if (array_key_exists('is_normal', $_SESSION)) {
		return $_SESSION['is_normal'];
	}
	return false;
}

// this function uses session information to see if the user is an admin
function is_admin()
{
	if (array_key_exists('is_admin',  $_SESSION)) {
		return $_SESSION['is_admin'];
	}
	return false;
}

// this function uses session information to see if the user is a super user
function is_super()
{
	if (array_key_exists('is_super', $_SESSION)) {
		return $_SESSION['is_super'];
	}
	return false;
}

// This function is the common way to start a new session
function begin_bs_session($sn)
{
	$current_session_id = null;
	if (isset($_REQUEST['sid'])) {
		$current_session_id = $_REQUEST['sid'];
	}

	session_id($current_session_id);
	session_start();
	session_name($sn);
}

// This should be the FIRST function called on every new page
function auth_user()
{
	StartTimer();
	begin_bs_session($_REQUEST['sn']);

	global $database_name;
	global $database_instance;

	$database_instance = new mysql_db($database_name, $_SESSION['userName'], $_SESSION['pwd'], $status);
	get_user_privs($normal, $admin, $super, $active);

	if (
		!isset($_SESSION['sn']) ||
		($_SESSION['sn'] != $_REQUEST['sn']) ||
		!isset($_SESSION['loggedIn']) ||
		!$status ||
		!$active
	) {
		header('Location:index.php');
	}

	print_bs_header();
}

function session_link($post = true)
{
	if ($post) {
		return "?sn=" . session_name() . "&sid=" . session_id();
	} else {
		return '<input type="hidden" name="sn" value="' . session_name() . '"><input type="hidden" name="sid" value="' . session_id() . "\">\n";
	}
}

function print_session_link($name, $target)
{
	return "<a href=\"$target" . session_link() . "\">$name</a>";
}

?>
