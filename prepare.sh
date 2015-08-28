#!/bin/sh
echo Preparing to up admin and nodes
#
# Generating ssh keys to allow access to minions from master node
#
rm -f ./common/id_*
ssh-keygen -f ./common/id_rsa -P ""
chmod +x common/*.sh 
