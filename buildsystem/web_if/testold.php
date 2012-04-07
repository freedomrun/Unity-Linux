<?php

require_once('settings.php');
auth_user();

if(isset($_REQUEST['action'])) {
	switch ($_REQUEST['action']) {
	case 'perl':
	case 'mandy':
	case 'gnome':
		old_pkg_report($_REQUEST['action']);
		break;

	default:
		print_debug("Invalid action requested\n");
	}
	exit;
}

print "<p/>This page can be used to check which packages in our repo are out of date:";
print "<ul>\n";
print "  <li><a href='" . session_link() . "&action=perl'>Check Perl modules</a></li>\n";
print "  <li><a href='" . session_link() . "&action=mandy'>Check Mandriva tools</a></li>\n";
print "  <li><a href='" . session_link() . "&action=gnome'>Check Gnome packages</a></li>\n";
print "</ul>\n";

function old_pkg_report($type)
{
	$cur_page = 1;
	if (array_key_exists('page', $_REQUEST)) {
		$cur_page = $_REQUEST['page'];
	}

	$rows = fetch_old_pkgs('', 0, $type);
	print_pagination_ribbon($rows, $cur_page, $per_page, "&action=$type&page=");	

	$items = fetch_old_pkgs($cur_page, $per_page, $type);
	_start_table(array('Name', 'Local Repo Version', 'Local SVN version', 'Remote Version', 'Arch'));

	if (!empty($items)) {
		foreach ($items as $row) {
			$columns = array();
			$columns[] = array('data' => $row['pkg_name']);
			$columns[] = array('data' => $row['localrepo']);
			$columns[] = array('data' => $row['localsvn']);
			$columns[] = array('data' => $row['remote']);
			$columns[] = array('data' => $row['arch']);
			_disp_table_row($columns);
		}
	}
	_end_table();
}

?>
