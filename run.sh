#!/bin/bash

cd ${0%/*}

RANDOM_MAP_FILE="conf/vote_random_map"

function update_random_map {
	echo "### ${RANDOM_MAP_FILE}.cfg"
	LAST=$(cat ${RANDOM_MAP_FILE}.cfg)
	echo -e "\t-$LAST"
	find data/maps/ -type f -name '*.map' | grep -v "$LAST" | sort -R | head -1 | sed 's/^data\/maps\//sv_map /' | sed 's/.map$//' > "${RANDOM_MAP_FILE}.cfg"
	echo -e "\t-$(cat ${RANDOM_MAP_FILE}.cfg)"
	for I in {0..5} ; do
		echo "### ${RANDOM_MAP_FILE}_${I}.cfg"
		if [ -f ${RANDOM_MAP_FILE}_${I}.cfg ] ; then
			LAST=$(cat ${RANDOM_MAP_FILE}_${I}.cfg)
			echo -e "\t-$LAST"
			./generateRandomMapsCfg.sh $I | grep -v "$LAST" | sort -R | head -1 > "${RANDOM_MAP_FILE}_${I}.cfg"
		else
			./generateRandomMapsCfg.sh $I | sort -R | head -1 > "${RANDOM_MAP_FILE}_${I}.cfg"
		fi
		echo -e "\t-$(cat ${RANDOM_MAP_FILE}_${I}.cfg)"
	done
}

./openfng.sh $@ | while read LINE ; do
	echo "[$(date '+%d/%m/%Y %H:%M:%S')] $LINE"
	if grep -q "\[datafile\]: loading done" <<<"$LINE" ; then
		update_random_map
	elif grep "\[game\]: activate_random_rotation_" <<<"$LINE" | grep -qv "\[say\]" ; then
		RANK=$(sed 's/.*activate_random_rotation_//' <<<"$LINE")
		cat ${RANDOM_MAP_FILE}_${RANK}.cfg | ./sendToServer.sh
	elif grep "\[game\]: activate_random_rotation" <<<"$LINE" | grep -qv "\[say\]" ; then
		cat ${RANDOM_MAP_FILE}.cfg | ./sendToServer.sh
	fi
done |& tee ./logs/teeworlds.log
