#!/bin/bash

HOST=$MAHAD_1_HOST
USER=$MAHAD_1_HOST_USER


DESTINATION_DIR=/var/www/html/MeezanSync
LOCAL_DOCUMENTS_DIR=documents

# create target directory
ssh -i $HOME/.ssh/id_rsa $USER@$HOST "sudo mkdir -p $DESTINATION_DIR";

# Copy the terms and privacy policy files to the web server
scp -i $HOME/.ssh/id_rsa -r $LOCAL_DOCUMENTS_DIR $USER@$HOST:/tmp/;

# Move the files to the target directory and Restart the web server
ssh -i $HOME/.ssh/id_rsa $USER@$HOST "
    sudo rm -rf $DESTINATION_DIR/$LOCAL_DOCUMENTS_DIR || (echo 'Directory does not exist' && exit 1);
    sudo mv /tmp/$LOCAL_DOCUMENTS_DIR $DESTINATION_DIR/$LOCAL_DOCUMENTS_DIR || (echo 'Move failed' && exit 1);
    sudo service nginx restart || ( echo 'Nginx restart failed' && exit 1);
";

echo "Deployed terms and privacy policy files to $HOST"