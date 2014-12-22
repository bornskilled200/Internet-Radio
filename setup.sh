#!/bin/bash

set -o nounset
set -o errexit

# For turning off the raspberry pi using these GPIO pins
POWEROFF_GPIO_IN=23
POWEROFF_GPIO_OUT=24

# For going to the next stream using these GPIO pins
NEXT_GPIO_IN=17
NEXT_GPIO_OUT=22

# The media player for the TTS
TTS_PLAYER=/usr/bin/mplayer
TTS_ARGS="-ao alsa -really-quiet -volume 100"

# The media player for the omxplayer_playlist_play
PLAYLIST_PLAYER=omxplayer
PLAYLIST_ARGS=""

###
# For turning off the raspberry pi using it's GPIO pins
###
echo '#!/bin/bash

#this is the GPIO pin for OUT
GPIOpin1='$POWEROFF_GPIO_OUT'

#this is the GPIO pin for IN
GPIOpin2='$POWEROFF_GPIO_IN'

echo "$GPIOpin1" > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio$GPIOpin1/direction
echo "$GPIOpin2" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio$GPIOpin2/direction
echo "1" > /sys/class/gpio/gpio$GPIOpin2/value
while [ 1 = 1 ]; do
	power=$(cat /sys/class/gpio/gpio$GPIOpin1/value)
	if [ $power = 0 ]; then
		sleep 1
	else
		sudo poweroff
		break
	fi
done' > /etc/switch.sh
sudo chmod 755 /etc/switch.sh
grep -qF '/etc/switch.sh &' /etc/rc.local || sudo sed -i '$ i /etc/switch.sh &' /etc/rc.local

###
# For going to the next stream by killing omxplayer using the raspberry pi's GPIO pins
###
echo '#!/bin/bash

#this is the GPIO pin for OUT
GPIOpin1='$NEXT_GPIO_OUT'

#this is the GPIO pin for IN
GPIOpin2='$NEXT_GPIO_IN'

echo "$GPIOpin1" > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio$GPIOpin1/direction
echo "$GPIOpin2" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio$GPIOpin2/direction
echo "1" > /sys/class/gpio/gpio$GPIOpin2/value
while [ 1 = 1 ]; do
	power=$(cat /sys/class/gpio/gpio$GPIOpin1/value)
	if [ $power = 0 ]; then
		sleep 1
	else
		sudo pkill omxplayer
	fi
done' > /etc/next.sh
sudo chmod 755 /etc/next.sh
grep -qF '/etc/next.sh &' /etc/rc.local || sudo sed -i '$ i /etc/next.sh &' /etc/rc.local

# installing googletts
echo '#!/bin/bash

set -o nounset
set -o errexit

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
verbose=0
force=0
PLAYER="'$TTS_PLAYER'"
PLAYER_ARGS="'$TTS_ARGS'"

forceSay() { 
	[ "$verbose" = "1" ] && echo "Playing the mp3 directly from the url"
	${PLAYER} ${PLAYER_ARGS} "http://translate.google.com/translate_tts?tl=en&q=$*"; 
}

cacheSay() {
	hashcode="/var/cache/googletts/."$(echo "$*" | md5sum | cut -d" " -f1)".mp3"
	# Check that the file exists
	if [ ! -f "${hashcode}" ]; then
		[ "$verbose" = "1" ] && echo "Retrieving the mp3, ${hashcode}"
		mkdir --parents /var/cache/googletts/
		wget --quiet --user-agent="Mozilla/5.0 (X11; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0" --output-document $hashcode "http://translate.google.com/translate_tts?tl=en&q=$*"
	else
		[ "$verbose" = "1" ] && echo "The mp3 is already cached, ${hashcode}"
	fi
	${PLAYER} ${PLAYER_ARGS} $hashcode; 
}

while getopts "h?vf" opt; do
	case "$opt" in
	h|\?)
		show_help
		exit 0
		;;
	v)  verbose=1
		;;
	f)	force=1
		;;
	esac
done

shift $((OPTIND-1))

[ ! -z ${var+x} ] && [ "$1" = "--" ] && shift

[ "$verbose" = "1" ] && echo "verbose=$verbose, force=$force, Text: $@"

if [ "$force" = "1" ]; then
	forceSay $*
else
	cacheSay $*
fi' > /etc/googletts
sudo chmod 755 /etc/googletts

echo '#!/usr/bin/env bash
#
# Plays files and STRM files from a playlist
#
# Copyright Â© 2013 Janne Enberg http://lietu.net/
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.
#

set -o nounset
set -o errexit

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.
verbose=0

# If you want to switch omxplayer to something else, or add parameters, use these
PLAYER="'$PLAYLIST_PLAYER'"
PLAYER_OPTIONS="'$PLAYLIST_ARGS'"

# Where is the playlist
PLAYLIST_FILE="/var/omxplayer_playlist_play/playlist"


while getopts "h?vf" opt; do
        case "$opt" in
        h|\?) show_help
              exit 0
                ;;
        v) verbose=1
                ;;
        esac
done

shift $((OPTIND-1))

[ ! -z ${var+x} ] && [ "$1" = "--" ] && shift

if [ ! -z "$@" ]; then
        PLAYLIST_FILE="$@"
fi

[ "$verbose" = "1" ] && echo "verbose=$verbose, playlist file=$PLAYLIST_FILE, Text: $@"

# Process playlist contents
while [ true ]; do
        # Sleep a bit so its possible to kill this
        sleep 1

        # Do nothing if the playlist doesnt exist
        if [ ! -f "${PLAYLIST_FILE}" ]; then
                echo "Playlist file ${PLAYLIST_FILE} not found"
                continue
        fi

        # Get the top of the playlist
        file=$(cat "${PLAYLIST_FILE}" | head -n1)

        # Skip if this is empty
        if [ -z "${file}" ]; then
                echo "Playlist empty or bumped into an empty entry for some reason"

                cat "${PLAYLIST_FILE}" | tail -n+2 > "${PLAYLIST_FILE}.new"
                echo "$file" >> "${PLAYLIST_FILE}.new"
                mv "${PLAYLIST_FILE}.new" "${PLAYLIST_FILE}"
                continue
        fi

        # Check that the file exists
        if [ ! -f "${file}" ]; then
                echo "Playlist entry ${file} not found"
                continue
        fi

        echo
        echo "Playing ${file} ..."
        echo
	
	stream=$(cat "$file")
	echo
	echo "Stream ${stream} ..."
	echo

	filename=$(basename "$file")
	extension="${filename##*.}"
        filename=${filename%.*}
        echo
        echo "ext ${extension} ..."
        echo
        if [ `echo $extension | tr [:upper:] [:lower:]` =  `echo strm | tr [:upper:] [:lower:]` ]; then
	       play=$(cat "$file")
        else
                play=$file
        fi
        echo
        echo "Hi ${file} ..."
        echo

        sudo /etc/googletts "Now playing ${filename}"
	"${PLAYER}" ${PLAYER_OPTIONS} "${play}" || true

        echo
        echo "Playback complete, continuing to next item on playlist."
        echo


        # Sleep a bit so its possible to kill this
        sleep 1

        # And strip it off the playlist file
        cat "${PLAYLIST_FILE}" | tail -n+2 > "${PLAYLIST_FILE}.new"
        echo "$file" >> "${PLAYLIST_FILE}.new"
        mv "${PLAYLIST_FILE}.new" "${PLAYLIST_FILE}"

done' > /etc/omxplayer_playlist_play
sudo chmod 755 /etc/omxplayer_playlist_play
grep -qF '/etc/omxplayer_playlist_play &' /etc/rc.local || sudo sed -i '$ i /etc/omxplayer_playlist_play &' /etc/rc.local