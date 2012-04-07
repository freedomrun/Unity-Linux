<?php

###############################################
# Functions related to web SVN access
###############################################

function GetLinkToSvnPackage($type, $package, $text)
{
	global $web_svn;
	return sprintf($web_svn[$type]['package'], $package, $text);
}

function GetLinkToSvnCommit($type, $commit, $text)
{
	global $web_svn;
	return sprintf($web_svn[$type]['commit'], $commit, $text);
}


###############################################
# Functions related to data tables
###############################################

$table_num_columns = 0;
$rowspan_remaining = 0;
function _start_table($c)
{
	global $table_num_columns;

	print "<table border=1 cellspacing=1>\n";

	$header = array();
	$all_cells_empty = true;
	foreach ($c as $name) {
		if ($name != '') {
			$all_cells_empty = false;
		}
		$header[] = array('data' => $name, 'pre_data_format' => '<b><center>', 'post_data_format' => '</b></center>', 'tdformat' => 'bgcolor="#eeeeee"');
		$table_num_columns++;
	}
	if (!$all_cells_empty) {
		_disp_table_row($header);
	}
}

function _end_table()
{
	global $table_num_columns;
	print "</table><p/>\n";
	$table_num_columns = 0;
}

function _disp_table_separator($color)
{
	global $table_num_columns;
	print "<tr><td colspan='$table_num_columns' bgcolor='$color'/></tr>\n";
}

function _disp_table_row($c)
{
	global $rowspan_remaining;

	print "<tr>\n";
	foreach ($c as $cell) {
		if (array_key_exists('rowspan', $cell) && $rowspan_remaining) {
			$rowspan_remaining--;
			continue;
		}
		print "  <td";
		if (array_key_exists('tdformat', $cell)) {
			print " " . $cell['tdformat'];
		}
		if (array_key_exists('rowspan', $cell)) {
			if (!$rowspan_remaining) {
				print " rowspan='" . $cell['rowspan'] . "'";
				$rowspan_remaining = $cell['rowspan'] - 1;
			}
		}
		if (array_key_exists('colspan', $cell)) {
			print " colspan='" . $cell['colspan'] . "'";
		}
		print ">";
		if (array_key_exists('pre_data_format', $cell)) {
			print $cell['pre_data_format'];
		}
		print "&nbsp;" . $cell['data'] . "&nbsp;";
		if (array_key_exists('post_data_format', $cell)) {
			print $cell['post_data_format'];
		}
		print "</td>";
	}
	print "</tr>\n";
}

function paginate($total_rows, $cur_page, &$per_page) {
	if (!defined('per_page')) define('per_page', 25);
	if (!defined('max_num_pages_to_show')) define('max_num_pages_to_show', 3);
	$per_page = constant('per_page');

	$num_pages = ceil($total_rows/constant('per_page'));
	$start_1_page = $cur_page - constant('max_num_pages_to_show') + 1;
	if ($start_1_page < 1) {
		$start_1_page = 1;
	}
	$end_1_page = $start_1_page + constant('max_num_pages_to_show');
	if ($end_1_page > $num_pages) {
		$start_2_page = 0;
		$end_2_page = 0;
		$end_1_page = $num_pages;
	} else {
		$end_2_page = $num_pages;
		$start_2_page = $num_pages - constant('max_num_pages_to_show');
		if ($start_2_page <= $end_1_page) {
			$start_2_page = 0;
			$end_2_page = 0;
			$end_1_page = $num_pages;
		}
	}

#	print_debug("s1=$start_1_page, e1=$end_1_page, s2=$start_2_page, e2=$end_2_page, total=$num_pages");

	$pagination = array();

	if ($num_pages == 1) {
		return $pagination;
	}

	$pagination[] = array('Jumpt to Page: ');

	if ($start_1_page > 1) {
		$pagination[] = array(1, 'First');
		if ($start_1_page > 2) {
			$pagination[] = array('...');
		}
	}
	$i = $start_1_page;
	while ($i <= $end_1_page) {
		if ($i != $cur_page) {
			$pagination[] = array($i, $i);
		} else {
			$pagination[] = array($i);
		}
		$i++;
	}
	if ($start_2_page) {
		$pagination[] = array('...');
		$i = $start_2_page;
		while ($i <= $end_2_page) {
			if ($i != $cur_page) {
				$pagination[] = array($i, $i);
			} else {
				$pagination[] = array($i);
			}
			$i++;
		}
	}

	if (($cur_page > 1) || ($cur_page < $num_pages)) {
		 $pagination[] = array(' | ');
	}
	if ($cur_page > 1) {
		$pagination[] = array($cur_page-1, '&lt;Prev');
	}
	if ($cur_page < $num_pages) {
		$pagination[] = array($cur_page+1, 'Next&gt;');
	}

	return $pagination;
}

function print_pagination_ribbon($rows, $cur_page, &$per_page, $action)
{
	foreach ( paginate($rows, $cur_page, $per_page) as $page) {
		if (count($page) == 1) {
			print "$page[0] ";
		} else {
			print "<a href='" . session_link() . $action . $page[0] . "'>" . $page[1] . "</a> ";
		}
	}
	print "<p/>\n";
}

###############################################
# functions related to pending actions
###############################################

function read_pending_actions()
{
	global $bs_scripts_path;

	$filename = "$bs_scripts_path/pending_actions.sh";
	$data = array();

	if ($fp = fopen($filename, 'r')) {
		if (flock($fp, LOCK_SH | LOCK_NB)) {
			$data = explode("\n", @fread($fp, filesize($filename)));
		}
		fclose($fp);
}
return $data;
}

function write_pending_action($cmd)
{
	global $bs_scripts_path;

	$status = false;

	if ($fp = fopen("$bs_scripts_path/pending_actions.sh", 'a')) {
		$start = microtime();
		do {
			$canWrite = flock($fp, LOCK_EX | LOCK_NB);

			// If lock not obtained sleep for 0 - 100 milliseconds, to avoid collision and CPU load
			if(!$canWrite) usleep(round(rand(0, 100)*1000));
		} while ((!$canWrite) and ((microtime()-$start) < 1000));

		if ($canWrite) {
			fwrite($fp, $cmd);
			$status = true;
		}
		fclose($fp);
	}
}

#############################################
# Main display style functions
#############################################

$starttime;

function StartTimer()
{
	global $starttime;

	$mtime = microtime();
	$mtime = explode(' ', $mtime);
	$mtime = $mtime[1] + $mtime[0];
	$starttime = $mtime;
}

function PrintTimer()
{
	global $starttime;

	$mtime = microtime();
	$mtime = explode(" ", $mtime);
	$mtime = $mtime[1] + $mtime[0];
	$endtime = $mtime;
	$totaltime = ($endtime - $starttime);
	$totaltime1 = round($totaltime*10000)/10;
	#echo 'This page was created in ' .$totaltime. ' seconds.';
	echo '<p/>This page was created in ' .$totaltime1. ' milliseconds.';
}

function print_bs_header()
{
	global $show_fortunes;
	global $path_to_fortune;

	$fortune = '&nbsp;';

	if ($show_fortunes) {
		exec("$path_to_fortune -n 60 -s" , $output, $retval);
		foreach ($output as $line) {
			$line = str_replace("\t", '&nbsp;&nbsp;&nbsp;&nbsp;', $line);
			$fortune .= str_replace(" ", '&nbsp;', $line) . "<br/>";
		}
	}

	echo <<<END
<html><title='Unity Linux Build Server'><body bgcolor="#ddeedd">

<center>
<table width="85%" border="2" cellspacing="0" cellpadding="0" bordercolor="#dd0000" bgcolor="#ffffff">
  <tr>
	<td>
		<table width="100%" border="0" cellspacing="0" cellpadding="0" style="clear: both; border-bottom-width: 0;">
		  <tr>
			<td width="30%" bgcolor="#000000">
			  <center><img src="http://unity-linux.org/wp-content/themes/Quadro/images/logo.gif"></center>
			</td>
			<td width="2" bgcolor="#dd0000"/>
			<td>
				<table width="100%" border="0" cellspacing="1" cellpadding="1" style="clear: both; border-bottom-width: 0;">
					<tr><td><center><font size='+3'><b>Build Server</b></font></center></td></tr>
					<tr><td>$fortune</td></tr>
					<tr>
					  <td>
						<table width="100%" border="0" cellspacing="1" cellpadding="1" style="clear: both; border-bottom-width: 0;">
						  <tr><td align="right"><b>
END;
	echo print_session_link($_SESSION['userName'], "preferences.php") . "</a></b> | ";

	if (is_admin()) {
		echo print_session_link('admin', 'admin.php') . " | ";
	}

	echo print_session_link('Logout', "logout.php");

	echo <<<END2
						  </td></tr>
						</table>
					  </td>
					</tr>
				</table>
			</td>
		  </tr>
		</table>
	</td>
  </tr>

  <tr height="2"><td bgcolor="#dd0000"/></tr>

  <tr>
	<td>
	  <table width="100%" border="0" cellspacing="0" cellpadding="0" style="clear: both; border-bottom-width: 0;">
		<tr>
		  <td width="200" border="2" bordercolor="#dd0000"  valign="top">
			<table width="100%" border="1" cellspacing="1" cellpadding="5" style="clear: both; border-bottom-width: 0;">
END2;
	echo "<tr><td>" . print_session_link('Server Status', 'main.php') . "</td></tr>\n";
	echo "<tr><td>" . print_session_link('Schedule Build', 'avail.php') . "</td></tr>\n";
	echo "<tr><td>" . print_session_link('View Queue', 'queue.php') . "</td></tr>\n";
	echo "<tr><td><a href='history.php" . session_link() . "&page=1'>Results</a></td></tr>\n";
	echo "<tr><td>" . print_session_link('Cleanup', 'cleanup.php') . "</td></tr>\n";
	echo "<tr><td>" . print_session_link('Repo Error Reports', 'errorreports.php') . "</td></tr>\n";
	echo "<tr><td><a href='mdvcooker.php" . session_link() . "&page=1'>MDV Cooker</a></td></tr>\n";
	echo "<tr><td>" . print_session_link('View Rebuild List', 'rebuildlist.php') . "</td></tr>\n";
	echo "<tr><td>" . print_session_link('Old Versions Test', 'testold.php') . "</td></tr>\n";


	echo <<<END3
			</table>
		  </td>
		  <td width="2" bgcolor="#dd0000"/>
		  <td width="5"/>
		  <td border="2" bordercolor="#dd0000">
END3;

	register_shutdown_function('print_bs_footer');
}

function print_bs_footer()
{
	 echo <<<END4
         </td>
       </tr>
     </table>
   </td>
  </tr>
</table>
END4;
	PrintTimer();
}

?>

