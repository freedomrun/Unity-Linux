#!/bin/bash -e

# local (SVN) server information
LOCAL_BACKUP_DIR=/home/unity/svn_incremental_backups
LOCAL_REPOSITORY_DIR=/home/unity/svn
LOCAL_USER_RSA_KEY=/home/unity/.ssh/id_rsa

# remote (backup) server information
REMOTE_MACHINE=unity@gri6507.no-ip.org:/media/unity/
 
# Take the incremental backup and store it on the server
$LOCAL_BACKUP_DIR/svn-backup-dumps.py -iz $LOCAL_REPOSITORY_DIR $LOCAL_BACKUP_DIR

# back it up to the devel server
rsync -avz --exclude=svn.000000-004067.svndmp.gz  -e "ssh -i $LOCAL_USER_RSA_KEY" $LOCAL_BACKUP_DIR $REMOTE_MACHINE
