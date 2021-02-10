#!/bin/bash

SCRIPT_DIR="${0%/*}"
BASEDIR="$SCRIPT_DIR/.."

RANDOM_MAP_FILE="conf/vote_random_map"

function random_sort() {
	while read LINE ; do
		echo "$RANDOM,$LINE"
	done | sort -t',' -n | cut -d"," -f2-
};

function update_random_map {
	CURRENT="$1"
	echo "### updating random maps. Current is $CURRENT"
	echo "### updating ${RANDOM_MAP_FILE}.cfg"
	unset LAST
	LAST=$(cat ${RANDOM_MAP_FILE}.cfg 2>/dev/null)
	find "$BASEDIR/data/maps/" -type f -name '*.map' | grep -v "$CURRENT" | grep -v "${LAST:-\0}" | random_sort | head -1 | sed 's#.*data/maps/#sv_map #' | sed 's/.map$//' > "${RANDOM_MAP_FILE}.cfg"
	echo -e "\t-$(cat ${RANDOM_MAP_FILE}.cfg)"
	for I in {0..5} ; do
		echo "### updating ${RANDOM_MAP_FILE}_${I}.cfg"
		unset LAST
		LAST=$(cat ${RANDOM_MAP_FILE}_${I}.cfg 2>/dev/null)
		"$SCRIPT_DIR/getMapsWithMinRank.sh" $I | random_sort | head -1 > "${RANDOM_MAP_FILE}_${I}.cfg"
		echo -e "\t-$(cat ${RANDOM_MAP_FILE}_${I}.cfg)"
	done
}

"$@" | while read -r LINE ; do
	echo "[$(date '+%d/%m/%Y %H:%M:%S')] $LINE"
	if echo "$LINE" | grep -q "\[datafile\]: loading done" ; then
		LAST=$(echo "$LINE" | sed "s#.*datafile='maps/\(.*\)\.map'#\1#")
		AUTHOR=${LAST%/*}
		[ -f "$BASEDIR/data/maps/$AUTHOR/folder.name" ] && AUTHOR=$(< "$BASEDIR/data/maps/$AUTHOR/folder.name")
		MAPNAME=${LAST#*/}
		{ sleep 5 ; echo "broadcast $MAPNAME by $AUTHOR" | "$SCRIPT_DIR/sendToServer.sh" ; } &
		update_random_map "$LAST"
	elif echo "$LINE" | grep "\[game\]: activate_random_rotation" | grep -qv "\[say\]" ; then
		RANK=${LINE//*activate_random_rotation/}
		"$SCRIPT_DIR/sendToServer.sh" < "${RANDOM_MAP_FILE}${RANK}.cfg"
	fi
done | "$SCRIPT_DIR/translate.sh"

