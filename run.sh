#!/bin/bash

cd "${0%/*}"

RANDOM_MAP_FILE="conf/vote_random_map"

function update_random_map {
	CURRENT="$1"
	echo "### updating random maps. Current is $CURRENT"
	echo "### updating ${RANDOM_MAP_FILE}.cfg"
	unset LAST
	LAST=$(cat ${RANDOM_MAP_FILE}.cfg 2>/dev/null)
	find data/maps/ -type f -name '*.map' | grep -v "$CURRENT" | grep -v "${LAST:-\0}" | sort -R | head -1 | sed 's/^data\/maps\//sv_map /' | sed 's/.map$//' > "${RANDOM_MAP_FILE}.cfg"
	echo -e "\t-$(cat ${RANDOM_MAP_FILE}.cfg)"
	for I in {0..5} ; do
		echo "### updating ${RANDOM_MAP_FILE}_${I}.cfg"
		unset LAST
		LAST=$(cat ${RANDOM_MAP_FILE}_${I}.cfg 2>/dev/null)
		./getMapsWithMinRank.sh $I | sort -R | head -1 > "${RANDOM_MAP_FILE}_${I}.cfg"
		echo -e "\t-$(cat ${RANDOM_MAP_FILE}_${I}.cfg)"
	done
}

./openfng.sh "$@" | while read -r LINE ; do
	echo "[$(date '+%d/%m/%Y %H:%M:%S')] $LINE"
	if grep -q "\[datafile\]: loading done" <<<"$LINE" ; then
		LAST=$(sed "s#.*datafile='maps/\(.*\)\.map'#\1#" <<<"$LINE")
		update_random_map "$LAST"
	elif grep "\[game\]: activate_random_rotation" <<<"$LINE" | grep -qv "\[say\]" ; then
		RANK=${LINE//*activate_random_rotation/}
		./sendToServer.sh < "${RANDOM_MAP_FILE}${RANK}.cfg"
	fi
done |& tee -a ./logs/teeworlds.log

