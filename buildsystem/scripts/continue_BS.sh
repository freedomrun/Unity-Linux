#!/bin/bash

if [ "$USER" != "mdawkins" -a "$USER" != "builduser" ];
then
   echo "You dont' have sufficient svn privs to run this script."
   exit 1
fi


# This script restarts the SGE 
source /usr/share/gridengine/default/common/settings.sh

#/usr/bin/sge_execd start
sudo /etc/init.d/sge_execd start
