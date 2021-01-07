#!/usr/bin/env bash
# -*- coding: UTF-8 -*-
###############################################################################
# install.sh
# ==========
#
# Description:           Installs or uninstalls the garage-door service.
# Author:                Michael De Pasquale
# Creation Date:         2021-01-07
# Modification Date:     2021-01-07
#
###############################################################################

install_service()
{
    cp garage-door.service /etc/systemd/system/garage-door.service
    systemctl start garage-door.service
    systemctl enable garage-door.service
}

uninstall_service()
{
    systemctl stop garage-door.service
    systemctl disable garage-door.service
    rm /etc/systemd/system/garage-door.service
}

if [ "$#" = '0' ] || [ "$1" = 'install' ]; then
    install_service
elif [ "$1" = 'uninstall' ]; then
    uninstall_service
else
    echo "Usage: install.sh [install/uninstall]"
    exit 1
fi

exit 0

# vim: set ts=4 sw=4 tw=79 fdm=indent et :
