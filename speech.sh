#!/bin/bash

set -o nounset
set -o errexit

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
verbose=0
force=0
PLAYER=/usr/bin/mplayer
PLAYER_ARGS="-ao alsa -really-quiet -volume 100"

forceSay() { 

	if [ "$verbose" = "1" ]; then
		echo "Playing the mp3 directly from the url"
	fi
	${PLAYER} ${PLAYER_ARGS} "http://translate.google.com/translate_tts?tl=en&q=$*"; 
}

cacheSay() { 
	hashcode="."$(echo "$*" | md5sum | cut -d" " -f1)".mp3"
	# Check that the file exists
	if [ ! -f "${hashcode}" ]; then
		if [ "$verbose" = "1" ]; then
			echo "Retrieving the mp3, ${hashcode}"
		fi
		wget –-quiet -U 'Mozilla/5.0 (X11; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0' --output-document $hashcode "http://translate.google.com/translate_tts?tl=en&q=$*" 
	else
		if [ "$verbose" = "1" ]; then
			echo "The mp3 is already cached, ${hashcode}"
		fi
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

[ "$1" = "--" ] && shift

if [ "$verbose" = "1" ]; then
	echo "verbose=$verbose, force=$force, Text: $@"
fi


if [ "$force" = "1" ]; then
	forceSay $*
else
	cacheSay $*
fi
#forceSay $*
#cacheSay $*
