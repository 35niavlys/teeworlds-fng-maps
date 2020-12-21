#!/bin/bash

SCRIPT_DIR="${0%/*}"
BASEDIR="$SCRIPT_DIR/.."

MIN_RANK=$1

find "$BASEDIR/data/maps/" -type f -name '*.properties' | while read PROP ; do
	grep -q ^RANK "$PROP" && {
		. "$PROP"
		if [ "$RANK" -ge "$MIN_RANK" ]; then
			echo ${PROP%%.map.properties} | sed 's#.*data/maps/#sv_map #'
		fi
	}
done
