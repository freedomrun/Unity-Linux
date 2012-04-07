<?php

#########################################################
#
#                   main functions
#
#########################################################

function display_duplicates_report()
{
	global $packages_path;
	global $projects_path;
	global $repo_path;
	$cmd = "perl $projects_path/anyutils/clean_server.pl  --ignoretest --ignoreunstable --repopath=$repo_path --dups32 --dups64";
	run_duplicates_report($cmd, $dups);

	print "<form name='frm_dups' action='" . session_link() . "' method='post'><p/>\n";
	_start_table(array('Filename', 'Channel', 'Arch', 'Created By', 'Created On', 'Modified By', 'Modified On', 'Retire?'));

	# let's try to get a lock on the pending actions file because there may have already been scheduled events
	$pending_actions = array();
	$raw_actions = read_pending_actions();

	foreach ($raw_actions as $line) {
		if (preg_match('/^.?mv\s+(.*)\/([^\/]+)\/([^\/]+)\/([^\/]+)\s+(.*)\s+/', $line, $matches)) {
			if (preg_match('/retire/', $matches[5])) {
				$pending_actions[$matches[4]][] = array('channel'=>$matches[3], 'arch'=>$matches[2]);
			}
		}
	}

	$counter = 0;
	foreach ($dups as $sibling_id => $sibling_group) {
		_disp_table_separator('#dd0000');
		$num_groups = count($sibling_group);
		foreach ($sibling_group as $name => $pkg_group) {
			$is_duplicate = array();
			foreach ($pkg_group as $archname => $arch_group) {
				IdentifyDuplicates($arch_group, $is_duplicate);
				foreach ($arch_group as $entry) {
				 	# make sure that the user is allowed to do the cleanup action on this file
					list($can_see, $can_retire) = is_user_allowed_to_manip($entry['file'], $archname);

					$format = '';
					if ($is_duplicate[$entry['file']]) {
						$format = " bgcolor='#F3F781'";
					}

					$rpm_history = fetch_rpm_history($entry['file'], $archname);
					$full_path = $entry['path'] . '/' . $entry['file'];
					$stats = stat($full_path);

					$rpm_history_created_by = '&nbsp;';
					$rpm_history_created_on = '&nbsp;';
					$rpm_history_modified_by = '&nbsp;';
					$rpm_history_modified_on = date ("Y-m-d H:i", $stats[9]);
					if (array_key_exists('0', $rpm_history)) {
						$rpm_history_created_by = $rpm_history[0]['CreatedBy'];
						$rpm_history_created_on = $rpm_history[0]['CreatedOn'];
						$rpm_history_modified_by = $rpm_history[0]['LastModifiedBy'];
						$rpm_history_modified_on = "<a href='" . 
							session_link() . 
							"&action=last_modified_info&file=" . 
							urlencode($entry['file']) . 
							"&arch=" . urlencode($archname). "'>" . 
							$rpm_history[0]['LastModifiedOn'] . 
							"</a>";
						if ($rpm_history_modified_by == '') {
							$rpm_history_modified_on = '&nbsp;';
						}
					}

					$columns = array();
					$columns[] = array('data' => "<a href='rpmdetails.php" . session_link() . "&rpm=" . urlencode($full_path) ."'>" . $entry['file'] . '</a>', 'tdformat' => $format);
					$columns[] = array('data' => basename($entry['path']), 'tdformat' => $format);
					$columns[] = array('data' => $archname, 'tdformat' => $format);
					$columns[] = array('data' => $rpm_history_created_by, 'tdformat' => $format);
					$columns[] = array('data' => $rpm_history_created_on, 'tdformat' => $format);
					$columns[] = array('data' => $rpm_history_modified_by, 'tdformat' => $format);
					$columns[] = array('data' => $rpm_history_modified_on, 'tdformat' => $format);
					$columns[] = array('data' => "<input type='checkbox' name='dup" . $counter . "' value=''", 'tdformat' => $format);

					# the noarch channels carry the arch in the path
					if (preg_match('/([^\/]+)\/?/', $archname, $matches)) {
						$compare_archname = $matches[1];
					}

					if (array_key_exists($entry['file'], $pending_actions)) {
						foreach ($pending_actions[$entry['file']] as $pending_file) {
							if ( ($pending_file['channel'] == $columns[1]['data']) && ($pending_file['arch'] == $compare_archname) || !$can_retire || !$can_see) {
								$grey = 'bbbbbb';
								foreach ($columns as $i => $cell) {
									$columns[$i]['pre_data_format'] = "<font color='#$grey'>";
									$columns[$i]['post_data_format'] = "</font>";
								}
								$columns[count($columns)-1]['data'] .= " disabled";
								break;
							}
						}
					}
					$columns[count($columns)-1]['data'] .= ">";
					_disp_table_row($columns);

					$_SESSION['dups'][$counter] = $name . "::" . $entry['rev'] . "::" . $archname . '/' . basename($entry['path']) . '/' . $entry['file'];
					$counter++;
				}
			}
			if (--$num_groups > 0) {
				_disp_table_separator('#999999');
			}
		}
	}

	_end_table();
	print "<input type='submit' name='action' value='process_dups'></form><p/>";
}

function process_duplicates()
{
	$possible_dups = array();
	for ($i=0; $i<count($_SESSION['dups']); $i++) {
		list($name, $revid, $arch, $channel, $filename) = _decode_session_dup($_SESSION['dups'][$i]);
		
		# the noarch channels carry the arch in the path
		if (preg_match('/([^\/]+)\/?/', $arch, $proper_arch)) {
			$arch = $proper_arch[1];
		}

		if (!array_key_exists($name, $possible_dups)) $possible_dups[$name] = array();
		if (!array_key_exists($revid, $possible_dups[$name])) $possible_dups[$name][$revid] = array();
		if (!array_key_exists($arch, $possible_dups[$name][$revid])) $possible_dups[$name][$revid][$arch] = array();
		array_push($possible_dups[$name][$revid][$arch], array('id'=>$i, 'channel'=>$channel, 'file'=>$filename));
	}

	# let's see what was selected
	$selected_ids = array('user'=>array());
	foreach ($_REQUEST as $key => $value) {
		if (preg_match('/^dup(\d+)/', $key, $matches)) {
			# mark the user selected package for deletion
			array_push($selected_ids['user'], $matches[1]);
			# print_debug("Added $matches[1] because user selected it: " . $_SESSION['dups'][$matches[1]] . "\n");

			if (array_key_exists($matches[1], $selected_ids)) {
				# unmark the (possibly) autoselected package
				unset($selected_ids[$matches[1]]);
				# print_debug("removing autoselected entry $matches[1]\n");
			} else {
				# if there was no autoselected package, then check to make sure there shouldn't be one
				# let's ensure that both archs are selected
				list($name, $revid, $arch, $channel, $filename) = _decode_session_dup($_SESSION['dups'][$matches[1]]);
				
				# the noarch channels carry the arch in the path
				if (preg_match('/([^\/]+)\/?/', $arch, $proper_arch)) {
					$arch = $proper_arch[1];
				}

				$other_arch = 'i586';
				if ($arch == 'i586') $other_arch = 'x86_64';

				if ( array_key_exists($name, $possible_dups) &&
					array_key_exists($revid, $possible_dups[$name]) &&
					array_key_exists($other_arch, $possible_dups[$name][$revid])
				) {
					# print_debug("Considering the other arch $other_arch\n");
					# dump($possible_dups[$name][$revid][$other_arch]);
					$autoid = $possible_dups[$name][$revid][$other_arch][0]['id'];
					# print_debug("using auto_id = $autoid\n");
					if (!array_key_exists($autoid, $selected_ids)) {
						$selected_ids[$autoid] = $matches[1];
					}
				}
			}

			# print_debug("=================================================\n");
		}
	}

	# confirm the (auto) selection
	print "<b>Confirm your selection</b>:<p/>\n";
	print "<form name='frm_dups' action='" . session_link() . "' method='post'>\n";

	print "<blockquote>Your selections:\n";
	_start_table(array('Filename', 'Channel', 'Arch', 'Retire?'));

	$counter = 0;
	foreach ($selected_ids['user'] as $id) {
		list($name, $revid, $arch, $channel, $filename) = _decode_session_dup($_SESSION['dups'][$id]);
		$columns = array();
		$columns[] = array('data' => $filename);
		$columns[] = array('data' => $channel);
		$columns[] = array('data' => $arch);
		$columns[] = array('data' => "<input type='checkbox' name='dup" . $counter++ . "' value='$id' checked>");
		_disp_table_row($columns);
	}
	_end_table();
	print "<p/>Automatically identified for you:\n";
	_start_table(array('Filename', 'Channel', 'Arch', 'Retire?'));

	foreach ($selected_ids as $key => $id) {
		if (preg_match('/\d+/', $key)) {
			list($name, $revid, $arch, $channel, $filename) = _decode_session_dup($_SESSION['dups'][$key]);
			$columns = array();
			$columns[] = array('data' => $filename);
			$columns[] = array('data' => $channel);
			$columns[] = array('data' => $arch);
			$columns[] = array('data' => "<input type='checkbox' name='dup" . $counter++ . "' value='$key' checked>");
			_disp_table_row($columns);
		}
	}
	_end_table();
	print "<p/><input type='submit' name='action' value='confirm_dups'>";
	print "</blockquote></form>\n";
}

function delete_duplicates()
{
	global $repo_path;
	global $retired_rpm_path;

	$status = true;
	foreach ($_REQUEST as $key => $value) {
		if (preg_match('/^dup(\d+)/', $key)) {
			list($name, $revid, $arch, $channel, $filename) = _decode_session_dup($_SESSION['dups'][$value]);
			if (preg_match('/([^\/]+)\/?/', $arch, $matches)) {
				$cmd = "\mv $repo_path/$matches[1]/$channel/$filename $retired_rpm_path$matches[1] 2>&1";
				if (write_pending_action("$cmd\n")) {
					$status = false;
				} else {
					if (preg_match('/.*(noarch|i586|x86_64)\.rpm$/', $filename, $details)) {
						$thearch = $matches[1];
						if ($details[1] == 'noarch') {
							$thearch = $matches[1] . '/noarch';
						}
						update_rpm_history($filename, $thearch, $_SESSION['userName'], 'retired');
					}
				}
			}
		}
	}

	if ($status) {
		print "<p/>Your actions have been queued up. They will be executed next time the Build Server syncs its repos.";
	} else {
		print "<p/>Could not get exclusive lock on file to schedule your requested actions for execution. Please try again later.";
	}

	remove_dups_sesson();
}

#########################################################
#
#                 Supporting functions
#
########################################################

function run_duplicates_report($cmd, &$dups)
{
	global $repo_path;
	global $repo_channels;
	global $packages_path;
	global $projects_path;

	exec($cmd, $output, $retval);

	$dups = array();
	foreach ($output as $row) {
		if (!strstr($row, '::')) continue;
		list($SiblingID, $pkgname, $RevID, $file, $path, $version, $revision, $distarch, $arch) = explode('::', $row);
		if (!array_key_exists($SiblingID, $dups)) {
			$dups[$SiblingID] = array();
		}
		if (!array_key_exists($pkgname, $dups[$SiblingID])) {
			$dups[$SiblingID][$pkgname] = array();
		}
		if (!array_key_exists($arch, $dups[$SiblingID][$pkgname])) {
			$dups[$SiblingID][$pkgname][$arch] = array();
		}
		$dups[$SiblingID][$pkgname][$arch][$RevID] = array('file' => $file, 'path' => $path, 'rev' => $RevID);
	}
}

function IdentifyDuplicates($group, &$is_dup)
{
	global $packages_path;
	global $projects_path;

	$index = array();
	foreach ($group as $id => $dummy) {
		$index[] = $id;
	}

	$is_dup[$group[$index[0]]['file']] = false;
	for ($i=1; $i<count($index); $i++) {
		$cmd =  "perl $projects_path/anyutils/compare_rpm_versions.pl " . $group[$index[$i]]['path'] . '/' . $group[$index[$i]]['file'] . " " . $group[$index[$i-1]]['path'] . '/' . $group[$index[$i-1]]['file'];
		exec($cmd, $output, $retval);
		if ($retval == 0) {
			$looser = -1; // default to no looser

			switch ($output[0]) {
			case '1':
				// pkg1 > pkg2
				$winner = $i;
				$looser = $i-1;
				break;

			case '0':
				// pkg1 = pkg2
				$ch_pkg1 = basename($group[$i]['path']);
				$ch_pkg2 = basename($group[$i-1]['path']);

				if ( (($ch_pkg1 == 'test') || ($ch_pkg1 == 'unstable')) && (($ch_pkg2 != 'test') && ($ch_pkg2 != 'unstable')) ) {
					$winner = $i-1;
					$looser = $i;
				} else if ( (($ch_pkg1 != 'test') && ($ch_pkg1 != 'unstable')) && (($ch_pkg2 == 'test') || ($ch_pkg2 == 'unstable')) ) {
					$winner = $i;
					$looser = $i-1;
				} else if ( ($ch_pkg1 == 'test') && ($ch_pkg2 == 'unstable') ) {
					$winner = $i-1;
					$looser = $i;
				} else if ( ($ch_pkg1 == 'unstable') && ($ch_pkg2 == 'test') ) {
					$winner = $i;
					$looser = $i-1;
				} else {
					$winner = $i;
				}
				break;

			case '-1':
				$winner = $i-1;
				$looser = $i;
				break;

			default:
				print_debug("executing $cmd resulted in an unknown comparison result\n");
			}

			$is_dup[$group[$index[$winner]]['file']] = false;
			if ($looser >= 0) {
				$is_dup[$group[$index[$looser]]['file']] = true;
			}
		}
	}
}

function _decode_session_dup($str)
{
	list($name, $revid, $path) = explode('::', $str);
	$details = explode('/', $path);

	if (count($details) == 3) {
		# arch specific packages will have a path in the form of x86_64/plf/cinelerra-4-0.svn1061.5-plf2010.x86_64.rpm
		$offset = 0;
		$arch = $details[0];
	} else if (count($details) == 4) {
		# noarch packages have a path in the form of i586/noarch/unity/automake-1.11-1-unity2009.noarch.rpm
		$offset = 1;
		$arch = $details[0] . '/' . $details[1];
	}
	$channel = $details[1 + $offset];
	$filename = $details[2 + $offset];
	return array($name, $revid, $arch, $channel, $filename);
}

?>
