#!/bin/bash

cd ${0%/*}

RANDOM_MAP_FILE="conf/vote_random_map.cfg"

function update_random_map {
	find data/maps/ -type f -name '*.map' | sort -R | head -1 | sed 's/^data\/maps\//sv_map /' | sed 's/.map$//' > "$RANDOM_MAP_FILE"
}

LAST=$(date +%s)

./openfng.sh $@ | while read LINE ; do
	echo "[$(date '+%d/%m/%Y %H:%M:%S')] $LINE"
	if grep -q "\[datafile\]: loading done" <(echo $LINE) ; then
		update_random_map
	elif grep "\[game\]: activate_random_rotation" <(echo $LINE) | grep -qv "\[say\]" ; then
		cat conf/vote_random_map.cfg | ./sendToServer.sh
	fi
done | tee ./logs/teeworlds.log
