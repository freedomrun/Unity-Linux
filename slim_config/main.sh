#!/bin/sh

# (C) 2010 Kaleb Marshall
# http://www.tinymelinux.com/
# Please be sensible. If somebody writes code, give them credit. If you are
# inspired by their program, give them credit. Please leave my copyright and
# website URL intact.

#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

# These variables are user-editable
slim_conf="/etc/slim.conf"
theme_dir="/usr/share/slim/themes/"
script_dir=$(pwd)
log="$HOME/.slim/slim_config.log"
# Number of columns for the theme tab
columns=4

####################
###              ###
###   GENERIC    ###
###   FUNCTIONS  ###
###              ###
####################

# Requires: Nothing
# Returns: $output, the output of the gtkdialog program
function show_dialog()
{
	export MAIN_DIALOG=$(
	sed	-e 's|#.*||' \
		-e '/<!--/,/-->/ d' \
		-e "s|@@DEFAULT_USER_SET@@|$du_set|" \
		-e "s|@@USERS@@|$users|" \
		-e "s|@@FILL@@|$aln_fill|" \
		-e "s|@@PUT@@|$aln_cursor_pass|" \
		-e "s|@@AUTO@@|$aln_auto|" \
		-e "s|@@THEME_BOXES@@|$themes_boxes|" \
		$script_dir/main.xml)

	output=$(gtkdialog --program=MAIN_DIALOG)
}

# Requires: the name of the line in slim.conf it is going to enable
# Returns: Nothing
function enable_me()
{
	sed -i "s|^[\ \t#]*$1|$1|" $slim_conf
}

# Requires: the name of the line in slim.conf it is going to disable
# Returns: Nothing
function disable_me()
{
	sed -i "s|^$1|#$1|" $slim_conf
}

####################
###              ###
###  AUTO LOGIN  ###
###              ###
####################

# Requires: no input
# Returns: $aln_auto, $aln_fill, and $aln_cursor_put
function autologin_setup()
{
	local $cdul $i $preset_default_user $gotopass $autologin

	cdul=$(grep -m1 default_user $slim_conf)
	user_list=$(ls -1 --indicator-style=none /home | grep -v lost+found)
	preset_default_user=$(echo $cdul | awk '{print $2}')
	user_found=false
	for i in $user_list; do
		if [[ $preset_default_user == $i ]]; then
			user_found=true
		fi
	done

	#if default_user is commented out or blank, then it is not set
	if [[ $(echo $cdul | cut -c1) == "#" ]] || [[ $(echo $cdul | awk '{print $2}') == "" ]]; then
		du_set=false
	else
		du_set=true
	fi

	# Get list of users and embed in <item></item> brackets
	users=$(ls -1 --indicator-style=none /home | grep -v lost+found | grep -v $preset_default_user)
	users=$(for i in $users; do \
			echo -n "<item>$i</item>"; \
		done)

	# Add in root user if need be
	if [[ $preset_default_user != "root" ]]; then
		users=$(echo "<item>root</item> $users")
	fi

	# Add in preset default user
	if [[ $user_found == "true" ]]; then
		users=$(echo "<item>$preset_default_user</item> $users")
	fi

	# Fill in user, go to password field, or autologin?
	gotopass=false
	autologin=false

	if [[ $(grep focus_password $slim_conf | cut -c1) != "#" ]] && [[ $(grep focus_password $slim_conf | awk '{print $2}') == "yes" ]]; then
		gotopass=true
	fi

	if [[ $(grep auto_login $slim_conf | cut -c1) != "#" ]] && [[ $(grep auto_login $slim_conf | awk '{print $2}') == "yes" ]]; then
		autologin=true
	fi

	# Default settings
	aln_cursor_pass="false"
	aln_auto="false"
	aln_fill="true"

	# Sanity check-- if both are enabled, disable them
	if [[ $gotopass == "true" ]] && [[ $autologin == "true" ]]; then
		for i in "focus_password auto_login"; do
			sed -i "s|^$i\(.*\)|#$i\1|" $slim_conf
		done
		aln_cursor_pass="false"
		aln_auto="false"
	else
		if [[ $gotopass == "true" ]]; then
			aln_cursor_pass="true"
			aln_fill="false"
		else
			if [[ $autologin == "true" ]]; then
				aln_auto="true"
				aln_fill="false"
			fi
		fi
	fi
}

# Requires: no input
# Sets: the values of the focus_password, auto_login, and default_user lines in $slim_conf
function autologin_post()
{
	local $user $autologin_action
	# Check if autologin functions are enabled
	if [[ $(echo $output | sed -e 's| |\n|g' | grep AUTOLOGIN_ENABLE | awk -F\" '{print $2}' ) == "true" ]]; then
		# Get default user
		user=$(echo $output | sed -e 's| |\n|g' | grep AUTOLOGIN_USER | awk -F\" '{print $2}')
		# Enter the default user
		sed -i "s|^#*default_user.*|default_user\t$user|" $slim_conf
		autologin_action=$(echo $output | sed 's| |\n|g' | sed -n 's|\(ALN_.*\)="true"|\1| p')
		case "$autologin_action" in
			ALN_FILL)
				disable_me focus_password
				disable_me auto_login
			;;
			ALN_CURSOR_PUT)
				disable_me auto_login
				enable_me focus_password
				sed -i 's|^\(focus_password\).*|\1\tyes|' $slim_conf
			;;
			ALN_AUTO)
				disable_me focus_password
				enable_me auto_login
				sed -i 's|^\(auto_login\).*|\1\tyes|' $slim_conf
			;;
		esac
	else
		# Disable autologin functions
		for i in "focus_password auto_login default_user"; do
			disable_me $i
		done
	fi
}

##################
###            ###
###  MESSAGES  ###
###            ###
##################

# Messages have no code to run before they are displayed.
# The gtkdialog program allows embedding the necessary code into the XML.

# Requires: no input
# Sets: *_msg values in $slim_conf
function message_post()
{
	local $welcome $session $shutdown $reboot
	welcome=$(echo $output | sed 's|" |\n|g' | grep WELCOME_MSG | awk -F\" '{print $2}')
	session=$(echo $output | sed 's|" |\n|g' | grep SESSION_MSG | awk -F\" '{print $2}')
	shutdown=$(echo $output | sed 's|" |\n|g' | grep SHUTDOWN_MSG | awk -F\" '{print $2}')
	reboot=$(echo $output | sed 's|" |\n|g' | grep REBOOT_MSG | awk -F\" '{print $2}')

	preset_welcome=$(sed -n 's|welcome_msg[\t ]*\(.*\)|\1| p' $slim_conf)
	preset_session=$(sed -n 's|session_msg[\t ]*\(.*\)|\1| p' $slim_conf)
	preset_shutdown=$(sed -n 's|shutdown_msg[\t ]*\(.*\)|\1| p' $slim_conf)
	preset_reboot=$(sed -n 's|reboot_msg[\t ]*\(.*\)|\1| p' $slim_conf)

	if [[ $preset_welcome != $welcome ]]; then
		sed -i "s|\(welcome_msg\).*|\1\t$welcome|" $slim_conf
	fi
	if [[ $preset_session != $session ]]; then
		sed -i "s|\(session_msg\).*|\1\t$session|" $slim_conf
	fi
	if [[ $preset_shutdown != $shutdown ]]; then
		sed -i "s|\(shutdown_msg\).*|\1\t$shutdown|" $slim_conf
	fi
	if [[ $preset_reboot != $reboot ]]; then
		sed -i "s|\(reboot_msg\).*|\1\t$reboot|" $slim_conf
	fi
}

#########################
###                   ###
###  THEME SELECTION  ###
###                   ###
#########################

# Requires: no input
# Returns: $themes_boxes
function select_theme_setup()
{
	local $q $ibox $available_themes $no_available_themes $rows $themes_currently_used $this_theme $eocol
	available_themes=$(ls -1 --indicator-style=none $theme_dir)
	no_available_themes=$(echo $available_themes | sed 's| |\n|g' | grep -c ".*")

	# If we don't have enough themes for the number of columns, convert to one column
	if [[ $columns -ge $no_available_themes ]]; then
		columns=1
	fi

	rows=$(echo "$no_available_themes / $columns" | bc)
	themes_currently_used=$(grep current_theme $slim_conf | awk '{print $2}' | sed 's|,| |g')

	# If the number of available themes is not evenly divisible by the number of columns,
	# we have to add an extra row
	if [[ $(echo "$no_available_themes % $columns" | bc) != "0" ]]; then
		rows=$(echo "$rows + 1" | bc)
	fi

	for (( q=1; $q<=$no_available_themes; q++ )); do
		this_theme=$(echo $available_themes | awk '{print $'$q'}')
		# Figure out whether to enable the checkbox
		if [[ $(echo $themes_currently_used | grep -c $this_theme) == "1" ]]; then
			ibox="true"
		else
			ibox="false"
		fi

		eocol=$(echo "$q % $rows" | bc)
		if [[ $eocol -eq 1 ]]  || [[ $no_available_themes -eq 1 ]]; then
			themes_boxes=$(echo "$themes_boxes <vbox>")
		fi
		themes_boxes=$(echo "$themes_boxes <hbox><checkbox active=\"$ibox\"><label>\"\"</label><variable>\"THEME_$this_theme\"</variable></checkbox><text width-chars=\"17\" xalign=\"0\"><label>$this_theme</label></text><button><label>Preview</label><action>slim -p $theme_dir$this_theme \&</action></button></hbox>")
		if [[ $eocol -eq 0 ]] || [[ $q -eq $no_available_themes ]]; then
			themes_boxes=$(echo "$themes_boxes </vbox>")
		fi
	done
}

# Requires: $output
# Sets: current_theme line in $slim_conf
function select_theme_post()
{
	local $th
	# Now we set the theme list
	th=$(echo $(echo $output | sed 's| |\n|g' | sed -n 's|THEME_\(.*\)="true"|\1|g p') | sed 's| |,|g')
	sed -i "s|current_theme.*|current_theme\t$th|" $slim_conf
}

#######################
###                 ###
###  MISCELLANEOUS  ###
###                 ###
#######################

function misc_setup
{
	echo miscellaneous
}

function misc_post
{
	echo no code here yet
}

##################
###            ###
###  ADVANCED  ###
###            ###
##################

function advanced_setup
{
	echo no code here yet
}

function advanced_post
{
	echo no code here yet
}

#########################
###                   ###
###   MAIN PROGRAM    ###
###                   ###
#########################

autologin_setup
select_theme_setup

show_dialog

#echo $MAIN_DIALOG >> $log

if [[ $(echo $output | sed 's|.*EXIT="\(.*\)"|\1|') == "OK" ]]; then
#	echo $output
	autologin_post
	select_theme_post
	message_post
fi
