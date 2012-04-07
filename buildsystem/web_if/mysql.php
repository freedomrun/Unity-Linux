<?php

require_once('debug.php');

// This class contains only the backend access methods for accessing the MySQL database
class mysql_db
{
	private static $connection;

	// Class constructor
	function __construct($db, $user, $passwd, &$status)
	{
		global $database_location;

		$status = true;

		$this->connection = @mysql_connect($database_location, $user, $passwd);
		if (!$this->connection) {
			$status = false;
		}

		if ($status) {
			if (!mysql_select_db($db, $this->connection)) {
				$status = false;
			}
		}

		if (!$status) {
			print_debug('mysql_db error: ' . mysql_error());
		}
	}

	function close()
	{
		return mysql_close($this->connection);
	}

	function query($query)
	{
		//print "Query: $query\n<br>";
		$result = mysql_query($query, $this->connection);

		if (!$result) {
			print_debug('Invalid query: ' . mysql_error());
			return null;
		} else {
			if (!is_bool($result)) {
				$tmp = array();
				while ($row = mysql_fetch_assoc($result)) {
					$tmp[]=$row;
				}
			} else {
				$tmp = $result;
			}
		}
		return $tmp;
	}
};

// Below are the BS specific accessor functions for the database
function fetch_pkg_stats($jobid)
{
	// Let's first find out which pkgs table this jobid was scheduled from
	$query = sprintf("SELECT pkgs_prefix FROM jobs WHERE job_id=%s", $jobid);
	$tmp = read_from_db($query);
	$prefix = $tmp[0]['pkgs_prefix'];

	$query = sprintf("SELECT * FROM pkgs$prefix JOIN jobs USING (pkg_name, commit) WHERE job_id='%s'", $jobid);
	return read_from_db($query);
}

function fetch_prebuild_checks($jobid)
{
	$query = sprintf("select * from jobs_history where stage='PreBuild' and job_id='%s'", $jobid);
	return read_from_db($query);
}

function fetch_build_checks($jobid)
{
	$query = sprintf("select * from jobs_history where stage='Build' and job_id='%s' order by id", $jobid);
	return read_from_db($query);
}

function fetch_postbuild_checks($jobid)
{
	$query = sprintf("select * from jobs_history where stage='PostBuild' and job_id='%s'", $jobid);
	return read_from_db($query);
}

function fetch_built_rpms($jobid)
{
	$query = sprintf("SELECT * FROM rpms WHERE JobID='%s'", $jobid);
	return read_from_db($query);
}

function fetch_rpm_history($name, $arch) 
{
	$query = sprintf("SELECT * FROM rpms WHERE RpmName='%s' AND arch='%s'", $name, $arch);
	return read_from_db($query);
}

function update_rpm_history($name, $arch, $user, $action)
{
	$query = sprintf("UPDATE rpms SET LastModifiedBy='%s', LastModifiedOn=NOW(), LastMod='%s' WHERE RpmName='%s' AND arch='%s'", $user, $action, $name, $arch);
	if (read_from_db($query)) {
		return true;
	}
	return false;
}

function fetch_build_stats($jobid)
{
	$query = sprintf("select * from jobs where job_id=%d", trim($jobid));
	return read_from_db($query);
}

function fetch_buildevents($jobid)
{
	// Let's first find out which pkgs table this jobid was scheduled from
	$query = sprintf("SELECT pkgs_prefix FROM jobs WHERE job_id=%s", $jobid);
	$tmp = read_from_db($query);
	$prefix = $tmp[0]['pkgs_prefix'];

	// let's build a table that has all the history events and then return that
	$query  = 'SELECT * FROM ( ';
	$query .=     "(SELECT 'Avail for Build' AS event,pkgs$prefix.TS,job_id FROM pkgs$prefix JOIN jobs USING (pkg_name, commit)) ";
	$query .=     "UNION ";
	$query .=     "(SELECT 'Commit Time' AS event,commit_time,job_id FROM pkgs$prefix JOIN jobs USING (pkg_name, commit)) ";
	$query .=     "UNION ";
	$query .=     "(SELECT stage AS event,TS,job_id FROM jobs_history where stage like 'Queued') ";
	$query .=     "UNION ";
	$query .=     "(SELECT tag AS event,TS,job_id FROM jobs_history where tag in ('Build Start', 'Build Stop')) ";
	$query .= ") AS tmp WHERE job_id=$jobid ORDER BY TS";

	return read_from_db($query);
}

function change_user_passwd($new_passwd)
{
	$query = "set password = PASSWORD('$new_passwd')";
	if (read_from_db($query)) {
		return true;
	}

	return false;
}

function fetch_build_history($page='', $per_page=0)
{
	global $pkgs_table_suffix;

	if ($page == '') {
		$query = "SELECT COUNT(job_id) AS count FROM (";
	} else {
		$query = "SELECT * FROM (";
	}

	$i = 0;
	foreach ($pkgs_table_suffix as $type) {
		if ($i) {
			$query .= ' UNION ';
		}
		$query .= sprintf('(SELECT job_id,pkg_name,pkg_ver,pkg_rel,committer,submitter,commit_time,stage,pass,pkgs_prefix FROM pkgs%s JOIN jobs USING (commit, pkg_name))', $type);
		$i++;
	}
	$query .= ') AS tmp ORDER BY job_id';

	// if we were not asked for a specific page, then return the number of entries returned by the query
	if ($page == '') {
		$tmp = read_from_db($query);
		return $tmp[0]['count'];
	} else {
   		$query .= '	DESC LIMIT ' . ($page - 1) * $per_page . ", $per_page";
		return read_from_db($query);
	}
}

function check_pkg_validity($pkgname, $table='')
{
	if (is_admin()) {
		$query = sprintf("SELECT commit FROM pkgs$table WHERE pkg_name='%s'", $pkgname);
	} else {
		$query = sprintf("SELECT commit FROM pkgs$table WHERE committer='%s' and pkg_name='%s'", $_SESSION['userName'], $pkgname);
	}

	// User has access to this pkg? (if pkg exists)
	$tmp = read_from_db($query);
	if (count($tmp) > 0) {
		$svnver=$tmp[0]['commit'];
	#	print_debug("$pkgname is a valid pkg with svnver=$svnver<br>\n");
		return $svnver;
	} else {
		return -1;
	}
}

function fetch_old_pkgs($page='', $per_page=0, $type='')
{
	if ($page == '') {
		$query = "SELECT COUNT(id) AS count FROM (";
	} else {
		$query = "SELECT * FROM (";
	}

	$query .= sprintf("SELECT * FROM pkg_perl_mdv_gnome WHERE (localsvn <> localrepo OR localsvn <> remote OR localrepo <> remote) AND type='$type'");
	$query .= ') AS tmp ORDER BY pkg_name ';

	// if we were not asked for a specific page, then return the number of entries returned by the query
	if ($page == '') {
		$tmp = read_from_db($query);
		return $tmp[0]['count'];
	} else {
		$query .= ' LIMIT ' . ($page - 1) * $per_page . ", $per_page";
		return read_from_db($query);
	}
}


function fetch_avail_pkgs($page='', $per_page=0, $package='')
{
	if ($page == '') {
		$query = "SELECT COUNT(id) AS count FROM (";
	} else {
		$query = "SELECT * FROM (";
	}


	if (is_admin()) {
		$query .= sprintf("select * from pkgs where concat(pkg_name,commit)  not in (select concat(pkg_name,commit) as pkg from jobs) and date(commit_time) > subdate(curdate(),127) order by pkgs.id DESC");

	} else {
		$query .= sprintf("select * from pkgs where committer='%s' and concat(pkg_name,commit)  not in (select concat(pkg_name,commit) as pkg from jobs) and date(commit_time) > subdate(curdate(),7) order by pkgs.id DESC", $_SESSION['userName']);
	}

	$query .= ') AS tmp ';
	if ($package != '') {
		$query .= "WHERE pkg_name LIKE '%$package%' ";
	}
	$query .= 'ORDER BY commit';

	// if we were not asked for a specific page, then return the number of entries returned by the query
	if ($page == '') {
		$tmp = read_from_db($query);
		return $tmp[0]['count'];
	} else {
		$query .= ' DESC LIMIT ' . ($page - 1) * $per_page . ", $per_page";
		return read_from_db($query);
	}
}

function fetch_avail_pkgs_mdv($page='', $per_page=0, $package='')
{
	if ($page == '') {
		$query = "SELECT COUNT(commit) AS count FROM (";
	} else {
		$query = "SELECT * FROM (";
	}

	$query .= sprintf("SELECT pkgs_mdv.pkg_name AS pkg_name, pkgs_mdv.pkg_ver AS pkg_ver, pkgs_mdv.pkg_rel AS pkg_rel, pkgs_mdv.commit AS commit, pkgs_mdv.committer AS committer, pkgs_mdv.commit_time AS commit_time, pkgs_mdv.pkg_summary AS pkg_summary, pkgs_mdv.log_msg AS log_msg, pkgs_mdv.TS AS TS  FROM pkgs_mdv JOIN pkgs ON pkgs_mdv.pkg_name=pkgs.pkg_name WHERE pkgs_mdv.pkg_ver!='Unknown' AND DATE(pkgs.commit_time) < DATE(pkgs_mdv.commit_time) AND CONCAT(pkgs_mdv.pkg_name, pkgs_mdv.commit) NOT IN (SELECT CONCAT(pkg_name, commit) AS pkg FROM jobs) ORDER BY commit DESC");

	$query .= ') AS tmp ';
	if ($package != '') {
		$query .= "WHERE pkg_name LIKE '%$package%' ";
	}
	$query .= 'ORDER BY commit';

	// if we were not asked for a specific page, then return the number of entries returned by the query
	if ($page == '') {
		$tmp = read_from_db($query);
		return $tmp[0]['count'];
	} else {
		$query .= ' DESC LIMIT ' . ($page - 1) * $per_page . ", $per_page";
		return read_from_db($query);
	}
}

function fetch_nonunity_pkgs_mdv($page='', $per_page=0, $package='')
{
	if ($page == '') {
		$query = "SELECT COUNT(id) AS count FROM (";
	} else {
		$query = "SELECT * FROM (";
	}

	$query .= "SELECT id, pkg_name, commit, committer, commit_time, log_msg, TS FROM pkgs_mdv WHERE pkgs_mdv.pkg_ver='Unknown'";
	$query .= ') AS tmp ';
	if ($package != '') {
		$query .= "WHERE pkg_name LIKE '%$package%' ";
	}
	$query .= 'ORDER BY commit';
	
	// if we were not asked for a specific page, then return the number of entries returned by the query
	if ($page == '') {
		$tmp = read_from_db($query);
		return $tmp[0]['count'];
	} else {
		$query .= ' DESC LIMIT ' . ($page - 1) * $per_page . ", $per_page";
		return read_from_db($query);
	}
}


// This function checks the database to see if the user has admin priveledges
function get_user_privs(&$normal, &$admin, &$super, &$active)
{
	$normal = false;
	$admin = false;
	$super = false;

	$query = sprintf("select grp,active from usergroup where user='%s'", $_SESSION['userName']);
	$tmp = read_from_db($query);

	$active = $tmp[0]['active'];

	if ($tmp[0]['grp'] == "normal") {
		$normal = true;	
	} else if ($tmp[0]['grp']=="admin") {
		$normal = true;
		$admin = true;
	} else if ($tmp[0]['grp']=="super") {
		$normal = true;
		$admin = true;

		$query = sprintf("SELECT Grant_priv FROM mysql.user WHERE user='%s'", $_SESSION['userName']);
		$priv = read_from_db($query);
		if ($priv[0]['Grant_priv'] == 'Y') {
			$super = true;
		}
	}
}

// this function checks to see if the username is a valid user
function is_user($username) 
{
	$query = sprintf("select grp from usergroup where user='%s'", $username);
	$tmp = read_from_db($query);
	
	if (isset($tmp[0])) {
		return true;
	} else {
		return false;
	}
}

// This function returns all available BS users
function get_all_users() 
{
	$query = sprintf("SELECT user,grp,active FROM usergroup");
	return read_from_db($query);
}

// this function will change a given user's status
function change_user($user, $level, $active)
{
	# assume that the user may be demoted from super privileges, so revoke that first
	$query = sprintf("REVOKE ALL PRIVILEGES, GRANT OPTION FROM '%s'@'localhost'", $user);
	read_from_db($query);
	$query = sprintf("GRANT SELECT,UPDATE ON BS.* to '%s'@'localhost'", $user);
	read_from_db($query);
	read_from_db("FLUSH PRIVILEGES");

	# if this user is being promoted to a super level, then give that privilege
	if ($level == 'super') {
		$query = sprintf("GRANT ALL PRIVILEGES ON *.* TO '%s'@'localhost' WITH GRANT OPTION", $user);
		read_from_db($query);
		read_from_db("FLUSH PRIVILEGES");
	}

	# change the active status, and the level details for the user
	$query = sprintf("UPDATE usergroup SET grp='%s',active='%d' WHERE user='%s'", $level, $active, $user);
	read_from_db($query);

	return true;
}

// this function will create a new user at the desired level
function create_user($user, $pwd, $level, $active)
{
	$query = sprintf("CREATE USER '%s'@'localhost' IDENTIFIED BY '%s'", $user, $pwd);
	read_from_db($query);
	$query = sprintf("INSERT INTO BS.usergroup (user,grp,active) VALUES('%s', 'newbie', '%d')", $user, $active);
	read_from_db($query);
	$query = sprintf("GRANT SELECT ON BS.* to '%s'@'localhost' IDENTIFIED BY '%s'", $user, $pwd);
	read_from_db($query);
	read_from_db("FLUSH PRIVILEGES");
	
	if ($level != 'newbie') {
		change_user($user, $level, $active);
	}
	return true;
}

// this function will delete a user
function delete_user($user)
{
	$query = sprintf("DELETE FROM BS.usergroup WHERE user='%s'", $user);
	read_from_db($query);
	$query = sprintf("DROP USER '%s'@'localhost'", $user);
	read_from_db($query);
	return true;
}

// This function is for backwards compatibility
function read_from_db($query)
{
	global $database_instance;
	return $database_instance->query($query);
}

?>
