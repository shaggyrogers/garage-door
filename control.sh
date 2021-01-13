#!/usr/bin/env bash
# -*- coding: UTF-8 -*-
###############################################################################
# control.sh
# ==========
#
# Description:           Takes an operation (up/down) and temporarily sets the
#                        corresponding GPIO pin to high.
# Author:                Michael De Pasquale
# Creation Date:         2021-01-06
# Modification Date:     2021-01-10
#
###############################################################################


# Configuration
GPIO_UP=17  # "Up" gpio pin number
GPIO_DOWN=27  # "Down" gpio pin number
GPIO_STOP=22  # "Stop" gpio pin number
GPIO_DELAY_SEC=0.25  # Time to wait after changing the value of a pin
INIT_DELAY_SEC=0.25  # Time to wait to ensure that the gpio group has ownership

# Echoes arguments to stderr.
loge() { echo "$@" >&2; }

# Returns the base directory for a given GPIO pin number.
# Assumes that control has already been exported to userland.
gpio_base() { echo "/sys/class/gpio/gpio$1"; }

# Initialises one or more GPIO pins for output with default value 0.
gpio_init()
{
    if [ "$#" = '0' ]; then
        loge "gpio_init needs at least 1 argument!"
        return 1
    fi

    while [ "$#" != '0' ]; do
        _PIN=$1
        _GPIO_BASE="$(gpio_base $_PIN)"
        shift

        if [ -d "$_GPIO_BASE" ]; then
            # Already initialised
            continue
        fi

        # Export control to userland
        echo "$_PIN" > "/sys/class/gpio/export"

        # HACK: Sleep here to give the gpio udev rule time to run.
        # The aforementioned udev rule takes ownership over files in the
        # $_GPIO_BASE directory for the 'gpio' group, which we need for
        # permission to write.
        sleep $INIT_DELAY_SEC

        if ! echo "out" > "$_GPIO_BASE/direction"; then
            loge "Failed to set direction! base=$_GPIO_BASE"
            return 2
        fi

        if ! echo "0" > "$_GPIO_BASE/value"; then
            loge "Failed to initialise value! base=$_GPIO_BASE"
            return 3
        fi

        loge "Initialised GPIO$_PIN"
    done

    return 0
}

# Change the value of a given GPIO pin, waiting for GPIO_DELAY_SEC before
# returning.
#
# Arguments:
# * pin - The pin number (integer)
# * value - The value to set (integer)
gpio_set()
{
    if [ "$#" != '2' ]; then
        loge "gpio_set needs 2 arguments, got $#"
        return 1
    fi

    # Initialise pin if necessary
    if ! gpio_init "$1"; then
        return 2
    fi

    # Set value and sleep
    if ! echo "$2" > "$(gpio_base $1)/value"; then
        loge "Failed to set pin $1 to $2!"
        return 3
    fi

    sleep "$GPIO_DELAY_SEC"
    return 0
}


if [ "$#" != '1' ] ; then
    loge "Expected 1 argument, got $#"
    exit 1
fi

if [ "$1" = 'up' ]; then
    gpio_set "$GPIO_UP" 1 || exit 10
    gpio_set "$GPIO_UP" 0 || exit 11
elif [ "$1" = 'down' ]; then
    gpio_set "$GPIO_DOWN" 1 || exit 12
    gpio_set "$GPIO_DOWN" 0 || exit 13
elif [ "$1" = 'stop' ]; then
    gpio_set "$GPIO_STOP" 0 || exit 16
    gpio_set "$GPIO_STOP" 1 || exit 17
elif [ "$1" = 'init' ]; then
    gpio_init "$GPIO_UP" "$GPIO_DOWN" "$GPIO_STOP" || exit 14
    gpio_set "$GPIO_STOP" 1 || exit 15
else
    loge "Unrecognised argument '$1', valid arguments are 'up', 'down' or" \
        " 'init' (case sensitive)"
    exit 2
fi

# vim: set ts=4 sw=4 tw=79 fdm=indent et :
