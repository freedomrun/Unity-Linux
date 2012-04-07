<?php

######################################
#   Main Functions
######################################

function display_promote_report()
{
	global $repo_channels;

	print <<<END_SCRIPT
<script language="JavaScript">
<!--
	function enable_text(status)
	{
		if (status)
		{
			document.frm_promote.pattern.value = '.*\\\\.rpm';
		}
		else
		{
			document.frm_promote.pattern.value = '';
		}
	}
//-->
</script>
END_SCRIPT;

	print "<p/><H1> Move packages between channels</H1><p/>Type in at least part of the name of the package that you would like to relocate. The entry can be a valid regexp. You can list multiple packages by separating the entries by a comma (the ',' character).<p/>";
	print "<form name='frm_promote' action='" . session_link() . "' method='post'><p/>\n";
	print "<input type='checkbox' name='all_rmps' onclick='enable_text(this.checked)'>Search all RPMs<br/>\n";
	print "Pattern: <input type='text' name='pattern' /><input type='submit' value='Submit' /><input type='hidden' name='action' value='prom_find_pattern' /><br/>\n";

	$desired_channel = "<select name='searchin'>\n<option value='-1' selected>All Channels\n";
	foreach ($repo_channels as $index => $ch) {
		$choice = '';
		if (strtolower($ch) == 'test') {
			$choice = 'selected';
		}
		$desired_channel .= "<option $choice value='$index'>$ch\n";
	}
	$desired_channel .= "</select>\n";
	
	print "Search in: $desired_channel\n";
	print "</form>\n";
}

function display_found_by_pattern()
{
    print <<<END_SCRIPT
<script language="JavaScript">
<!--
    function retire_and_promote(my_frm, status, sel1, sel2, new_val1, new_val2, def_val1, def_val2)
    {
        my_sel1 = eval("document." + my_frm.name + "." + sel1);  
        my_sel2 = eval("document." + my_frm.name + "." + sel2); 
        
        if (status)
        {
            my_sel1.value = new_val1;
            my_sel2.value = new_val2;
        }
        else
        {
            my_sel1.value = def_val1;
            my_sel2.value = def_val2;
        }
    }
//-->
</script>
END_SCRIPT;

	global $repo_path;
	global $repo_channels;
	global $packages_path;
	global $projects_path;
	$arches = array('i586', 'x86_64');
	$seen_files = array();

	# get a listing of all of the files in the requested channels
	$all_files = array();
	foreach ($repo_channels as $index => $channel) {
		$all_files[$channel] = array();
		if (($_REQUEST['searchin'] < 0) || ($_REQUEST['searchin'] == $index)) {
			foreach ($arches as $arch) {
				$all_files[$channel][$arch] = scandir("$repo_path/$arch/$channel");
			}
		}
	}

	# let's try to get a lock on the pending actions file because there may have already been scheduled events
	$pending_actions = array();
	$raw_actions = read_pending_actions();
	foreach ($raw_actions as $line) {
		if (preg_match('/^.?mv\s+(.*)\/+([^\/]+)\/+([^\/]+)\/+([^\/]+(noarch|i586|x86_64)\.rpm)\s+(.*)\s+/', $line, $matches)) {
			$thearch = $matches[2];
		    if ($matches[5] == 'noarch') {
				$thearch = $matches[2] . '/noarch';
			}
			$pending_actions[$matches[4]][] = array('channel'=>$matches[3], 'arch'=>$thearch);
		}
	}

	# create the selection entry for letting users set the target channel for the promote operation
	$promote_choice = "<select name='sel_NNNN'>\n<option value='-1'>Unspecified\n";
	foreach ($repo_channels as $index => $ch) {
		$promote_choice .= "<option value='$index'>$ch\n";
	}
	$promote_choice_w_retire = $promote_choice;
	$promote_choice_w_retire .= "<option value='retire'>retire\n";
	$promote_choice .= "</select>\n";
	$promote_choice_w_retire .= "</select>\n";

	# start the form for this page
	print "<form name='frm_promote' action='" . session_link() . "' method='post'><p/>\n";

	# try to find the files which match the requested pattern, and then find their siblings
	$patterns = explode(',', $_REQUEST['pattern']);
	foreach ($patterns as $pattern) {
		print "<h1>Here's what we found for '$pattern'</h1><p/><input type='submit' value='Process'>";
		$matched_files = '';
		$counter = 0;

		foreach ($all_files as $channel => $channel_files) {
			foreach ($channel_files as $arch => $channel_arch_files) {
				foreach ($channel_arch_files as $file) {
					if (preg_match('/^\./', $file)) continue;
					if (is_dir("$repo_path/$arch/$channel/$file")) continue;

					if (preg_match("/$pattern/", $file, $matches)) {
						# make sure that the user is allowed to do the cleanup action on this file
						list($can_see, $can_retire) = is_user_allowed_to_manip($file, $arch);
						$file_path = "$arch/$channel/$file";
						
						# skip over the RPMs which have already been displayed as siblings for some other package.
						if (array_key_exists($repo_path . '/' . $file_path, $seen_files)) continue;

						# find the direct and indirect siblings of this RPM
						$cmd = "perl $projects_path/anyutils/clean_server.pl  --repopath=$repo_path --findsibs=$file_path";
						run_duplicates_report($cmd, $dups);

						print "<br/>Found the followsing siblings for <b>'$file_path'</b>\n";

						# figure out how many groups there are for this block
						$block_groups = array();
						foreach ($dups as $sib_id => $all_sibs) {
							foreach ($all_sibs as $sib_name => $sib_details) {
								foreach ($sib_details as $sib_arch => $sib_arch_details) {
									foreach ($sib_arch_details as $sib_arch_rev => $entry) {
										array_push($block_groups, basename($entry['path']));
									}
									break;
								}
								break;
							}
							break;
						}
						
						# if there are exactly two groups in this block and exactly one of them is in test/unstable, then we can do a Fast Retire/Promote feature
						if (count($block_groups) == 2) {
							if ( (in_array('test', $block_groups) && !in_array('unstable', $block_groups)) ||
								 (!in_array('test', $block_groups) && in_array('unstable', $block_groups)) )
							{
								foreach ($block_groups as $id => $value) {
									if ($value == 'test' || $value == 'unstable') {
										$retire_from = $block_groups[($id+1)%2];
										$sel1_number = $counter + $id;
										$sel2_number = $counter + ($id + 1) % 2;

										# convert into index format
										foreach ($repo_channels as $index => $ch) {
											if ($retire_from == $ch) {
												$retire_from = $index;
												break;
											}
										}

										# specify the correct select block for the correct action
										break;
									}
								}

								print " <input type='checkbox' name='retire_promote' onclick='retire_and_promote(this.form, this.checked, \"sel_$sel1_number\", \"sel_$sel2_number\", $retire_from, \"retire\" , -1, -1)'>Retire and Promote\n";
							}
						}
						print "<br/>";

						_start_table(array('Filename', 'Channel', 'Arch', 'Size', 'Created By', 'Created On', 'Modified By', 'Modified On', 'To Channel'));

						foreach ($dups as $sib_id => $all_sibs) {
							_disp_table_separator('#dd0000');

							# figure out which revs are old and which are new
							$all_revs = array();
							foreach ($all_sibs as $sib_name => $sib_details) {
								foreach ($sib_details as $sib_arch => $sib_arch_details) {
									$is_duplicate = array();
									IdentifyDuplicates($sib_arch_details, $is_duplicate);

									foreach ($sib_arch_details as $sib_arch_rev => $entry) {
										if (!array_key_exists($sib_arch_rev, $all_revs)) {
											$all_revs[$sib_arch_rev] = array();
										}
										$entry['duplicate'] = $is_duplicate[$entry['file']];
										if (count($is_duplicate) == 1) {
											# if there is only one ver-rev in the group, then it cannot be a duplicate
											$entry['duplicate'] = false;
										}
										$entry['arch'] = $sib_arch;
										$seen_files[$entry['path'] . '/' . $entry['file']] = true;
										$all_revs[$sib_arch_rev][] = $entry;
									}
								}
							}

							# display the groupings with proper highlighting
							foreach ($all_revs as $ver_rev_id => $ver_rev_details) {

								# create a unique selector for this group
								$prom_choice = $promote_choice;
								if ($can_retire) {
									$prom_choice = $promote_choice_w_retire;
								}	
								$prom_choice = str_replace('NNNN', $counter, $prom_choice);
								$group_counter = $counter;
								$num_in_group = count($all_revs[$ver_rev_id]);

								# list all files in this group
								foreach ($ver_rev_details as $entry) {

									$format = '';
									if ($entry['duplicate']) {
										$format = "bgcolor='#F3F781'";
									}

									$chnl = basename($entry['path']);
									$full_path = $entry['path'] . '/' . $entry['file'];
									$stats = stat($full_path);
									$rpm_history = fetch_rpm_history($entry['file'], $entry['arch']);

									$rpm_history_created_by = '&nbsp;';
									$rpm_history_created_on = '&nbsp;';
									$rpm_history_modified_by = '&nbsp;';
									$rpm_history_modified_on = date ("Y-m-d H:i", $stats[9]);
									if (array_key_exists('0', $rpm_history)) {
										$rpm_history_created_by = $rpm_history[0]['CreatedBy'];
										$rpm_history_created_on = $rpm_history[0]['CreatedOn'];
										$rpm_history_modified_by = $rpm_history[0]['LastModifiedBy'];
										$rpm_history_modified_on = $rpm_history[0]['LastModifiedOn'];
										$rpm_history_modified_on = "<a href='" . 
											session_link() . 
											"&action=last_modified_info&file=" . 
											urlencode($entry['file']) . 
											"&arch=" . urlencode($entry['arch']). "'>" . 
											$rpm_history[0]['LastModifiedOn'] .
											"</a>";
										if ($rpm_history_modified_by == '') {
											$rpm_history_modified_on = '&nbsp;';
										}
									}

									$myarch = $entry['arch'];
									if (preg_match('/([^\/]+)\/noarch/', $myarch, $match)) {
										$myarch = $match[1];
									}

									$columns = array();
									$columns[] = array('data' => "<a href='rpmdetails.php" . session_link() . "&rpm=" . urlencode("$repo_path/$myarch/$chnl/" . $entry['file']) ."'>" . $entry['file'] . '</a>', 'tdformat' => $format);
									$columns[] = array('data' => $chnl, 'tdformat' => $format);
									$columns[] = array('data' => $entry['arch'], 'tdformat' => $format);
									$columns[] = array('data' => $stats[7], 'tdformat' => $format);
									$columns[] = array('data' => $rpm_history_created_by, 'tdformat' => $format);
									$columns[] = array('data' => $rpm_history_created_on, 'tdformat' => $format);
									$columns[] = array('data' => $rpm_history_modified_by, 'tdformat' => $format);
									$columns[] = array('data' => $rpm_history_modified_on, 'tdformat' => $format);
									$columns[] = array('data' => $prom_choice, 'tdformat' => $format, 'rowspan' => $num_in_group);

									$is_pending = false;
									if (array_key_exists($entry['file'], $pending_actions)) {
										foreach ($pending_actions[$entry['file']] as $pending_file) {
											if (($pending_file['channel'] == $chnl) && ($pending_file['arch'] == $entry['arch'])) {
												$is_pending = true;
												break;
											}
										}
									}

									if (!$can_see || $is_pending)
									{
										$grey = 'bbbbbb';
										foreach ($columns as $i => $cell) {
											$columns[$i]['pre_data_format'] = "<font color='#$grey'>";
											$columns[$i]['post_data_format'] = "</font>";
										}
										$columns[count($columns)-1]['data'] = str_replace("<select ", "<select disabled ", $columns[count($columns)-1]['data']);
									}

									_disp_table_row($columns);
									$_SESSION['promote'][$group_counter][] = $full_path;
								}

								# increment the counter for each group
								$counter++;
								_disp_table_separator('#999999');
							}
						}

						_end_table();
					}
				}
			}
		}
	}

	print "<input type='submit' value='Process'>\n<input type='hidden' name='action' value='process_prom'>\n</form>\n";
#	print "<br/>Current memory usage is " . memory_get_usage() . "<br/>";
#	print "Maximum memory usage is " . memory_get_peak_usage() . "<br/>";
#	print "PHP is configured for " . ini_get('memory_limit') . "<br/>";
}

function process_promote_selection()
{
	global $repo_path;
	global $repo_channels;

	# confirm the selection
	print "<b>Confirm your selection</b>:<p/>\n";
	print "<form name='frm_dups' action='" . session_link() . "' method='post'>\n";
	_start_table(array('Filename', 'Channel', 'Arch', 'Size', 'To Channel'));
	
	# let's see what was selected
	foreach ($_REQUEST as $key => $value) {
		if (preg_match('/^sel_(\d+)/', $key, $matches) && (($value >= 0) || ($value == 'retire'))) {
			$_SESSION['prom_conf'][$matches[1]] = $value;
			foreach ($_SESSION['promote'][$matches[1]] as $file_path) {
				if (preg_match('/.*\/([^\/]+)\/([^\/]+)\/(.*\.rpm)$/', $file_path, $details)) {
					$stats = stat($file_path);
					
					$columns = array();
					$columns[] = array('data' => $details[3]);
					$columns[] = array('data' => $details[2]);
					$columns[] = array('data' => $details[1]);
					$columns[] = array('data' => $stats[7]);
					if ($value == 'retire') {
						$columns[] = array('data' => 'retire');
					} else {
						$columns[] = array('data' => $repo_channels[$value]);
					}

					_disp_table_row($columns);
				}
			}
		}
	}
	_end_table();
	print "<input type='submit' value='Confirm'>\n<input type='hidden' name='action' value='confirm_prom'>\n</form>\n</blockquote>";
}

function commit_promote_selection()
{
	global $repo_path;
	global $repo_channels;
	global $retired_rpm_path;

	$status = true;

	foreach ($_SESSION['prom_conf'] as $id => $value) {
		foreach ($_SESSION['promote'][$id] as $file_path) {
			if (preg_match('/.*\/([^\/]+)\/([^\/]+)\/(.*(noarch|i586|x86_64)\.rpm)$/', $file_path, $details)) {
				$arch = $details[1];

				if ($value == 'retire') {
					$cmd = "\mv $file_path $retired_rpm_path$arch 2>&1";
					$action = "retire";
				} else if ($value < 0) {
					print "Cannot move $file_path to <b>Unknown</b> channel. Skipping this selection.<p/>\n";
					continue;
				} else {
					$cmd = "\mv $file_path $repo_path/$arch/" . $repo_channels[$value] . "/ 2>&1";
					$action = "move from " . $details[2] . " to " . $repo_channels[$value];
				}
			
				if (write_pending_action("$cmd\n")) {
					$status = false;
				} else {
					$thearch = $arch;
					if ($details[4] == 'noarch') {
						$thearch = $arch . '/noarch';
					}
					update_rpm_history($details[3], $thearch, $_SESSION['userName'], $action);
				}
			}
		}
	}

	if ($status) {
		print "<p/>Your actions have been queued up. They will be executed next time the Build Server syncs its repos.";
	} else {
		print "<p/>Could not get exclusive lock on file to schedule your requested actions for execution. Please try again later.";
	}

	remove_cleanup_session();
}

?>
