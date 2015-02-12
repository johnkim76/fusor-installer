#!/bin/bash

TARGET=/etc/puppet/environments/production/modules/
OVIRT_MODULE=/usr/share/ovirt-puppet/

# TODO: When moving to katello content management, we should instead 
# install the puppet modules by creating a katello product/repo,
# uploading modules (tar.gz) to repo, creating/publishing a content view
# that contains those modules

# copy modules from the package to the puppet environment

if [[ ! -e $TARGET ]]; then
    mkdir -p $TARGET
fi

cp -r $OVIRT_MODULE $TARGET
