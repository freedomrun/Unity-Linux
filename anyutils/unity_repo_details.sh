#!/bin/bash -e

NON_PLF_CHANNELS="branded main test gnome kde4 xfce nonfree e17 unstable games"
BRANCH_CHANNELS="orvitux tmlinux"
NON_PLF_CHANNELS="$NON_PLF_CHANNELS $BRANCH_CHANNELS"
PLF_CHANNELS="plf"
ARCH_LIST="i586 x86_64 armv5te"
#DEVEL_SERVER_ROOT='/home/disk'
### unity svn packages dir
DEVEL_PACKAGE_ROOT='/home/builduser/src/svn'
# 2 b deprecated
DEVEL_SERVER_ROOT='/home/builduser'

### unity svn projects dir
DEVEL_PROJECT_ROOT='/home/mdawkins/src/unity-linux/projects'

### mandriva/alternative svn package dir
ALTDEVEL_PACKAGE_ROOT='/home/builduser/src/cooker'

### rpm repo dir
CUR_REPO='current'
REPO_PATH="/home/disk/repos/unity/repo/$CUR_REPO"

### rpm retired dir
RETIRED_PATH='/home/disk/repos/retired_'

args=`getopt acpehdmnorzx $*`
set -- $args
for i
do
	case "$i" in
		-c) shift; disp_channels=1;;
		-p) shift; disp_plf_channels=1;;
		-e) shift; disp_all_channels=1;;
		-a) shift; disp_arches=1;;
		-d) shift; disp_devel_server_root=1;;
		-m) shift; disp_devel_package_root=1;;
		-n) shift; disp_devel_project_root=1;;
		-o) shift; disp_altdevel_package_root=1;;
		-r) shift; disp_repo_path=1;;
		-z) shift; disp_current_repo=1;;
		-x) shift; disp_retired_repo=1;;
		-h) shift; help=1;;
	esac
done

if [ -z "$disp_channels" -a -z "$disp_plf_channels" -a -z "$disp_all_channels" -a -z "$disp_arches" -a -z "$disp_devel_server_root" -a -z "$disp_devel_package_root" -a -z "$disp_devel_project_root" -a -z "$disp_altdevel_package_root" -a -z "$disp_repo_path" -a -z "$disp_current_repo" -a -z "$disp_retired_repo" ]
then
	help=1
fi

if [ -n "$help" ]
then
	echo "Usage: $0 [options]"
	echo ""
	echo "Possible Options:"
	echo "    -a  Display supported architectures"
	echo "    -c  Display list of non-PLF channels"
	echo "    -p  Display list of PLF channels"
	echo "    -e  Display list of PLF and non-PLF channels"
	echo "    -d  Display the devel server root path for all things Unity"
	echo "    -m  Display the svn package dir"
	echo "    -n  Display the svn project dir"
	echo "    -m  Display the altsvn package dir"
	echo "    -r  Display the RPM repo path (relative to devel server root path)"
	echo "    -z  Display the current repo version (i.e. current)"
	echo "    -x  Display the retired repo path"
	echo "    -h  This message"
	exit
fi

if [ -n "$disp_channels" ]
then
	echo "$NON_PLF_CHANNELS"
fi

if [ -n "$disp_plf_channels" ]
then
	echo "$PLF_CHANNELS"
fi

if [ -n "$disp_all_channels" ]
then
	echo "$NON_PLF_CHANNELS $PLF_CHANNELS"
fi

if [ -n "$disp_arches" ]
then
	echo "$ARCH_LIST"
fi

if [ -n "$disp_devel_server_root" ]
then
	echo "$DEVEL_SERVER_ROOT"
fi

if [ -n "$disp_devel_package_root" ]
then
	echo "$DEVEL_PACKAGE_ROOT"
fi

if [ -n "$disp_devel_project_root" ]
then
	echo "$DEVEL_PROJECT_ROOT"
fi

if [ -n "$disp_altdevel_package_root" ]
then
	echo "$ALTDEVEL_PACKAGE_ROOT"
fi

if [ -n "$disp_repo_path" ]
then
	echo "$REPO_PATH"
fi

if [ -n "$disp_current_repo" ]
then
	echo "$CUR_REPO"
fi

if [ -n "$disp_retired_repo" ]
then
	echo "$RETIRED_PATH"
fi

