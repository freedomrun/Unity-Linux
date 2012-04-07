#!/bin/bash -e

# local server information
LOCAL_HTML_DIR=/home/unity/mirmon/
LOCAL_WEB_DIR=/home/unity/public_html/
LOCAL_USER_RSA_KEY=/home/unity/.ssh/id_rsa

# remote server information
REMOTE_MACHINE=builduser@mdawkins.com
REMOTE_PORT=21
REMOTE_PATH=/home/home/src/unity-linux/projects/mirmon
 
# run mirmon on the remote server
ssh -i $LOCAL_USER_RSA_KEY -p $REMOTE_PORT $REMOTE_MACHINE "cd $REMOTE_PATH; perl gen_mirror_list.pl > mirror_list; perl mirmon -t 100 -get all"

echo ""
echo "============== Done with mirmon ==============="
rsync -avz -e "ssh -i $LOCAL_USER_RSA_KEY -p $REMOTE_PORT" $REMOTE_MACHINE:$REMOTE_PATH/html $LOCAL_HTML_DIR

cp $LOCAL_HTML_DIR/html/*.html $LOCAL_WEB_DIR/mm/
