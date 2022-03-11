#!/bin/bash

# Based on https://github.com/soimort/translate-shell

set -o noglob

SCRIPT_DIR="${0%/*}"

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

while read -r LINE ; do
	echo "$LINE"
	if grep "\[chat\]:" <<<"$LINE" | grep -qv '\[chat\]: \*\*\*' ; then
	    if grep -qv '!gt' <<<"$LINE" ; then
		LAST_SAY="$(echo "$LINE" | sed 's/.*chat]: //' | cut -d: -f4-)"
		LAST_SAY="$(trim $LAST_SAY)"
		echo "LAST_SAY\"$LAST_SAY\""
	    else
		PARAM=$(echo "$LINE" | sed 's/.*\!gt\(.*\)/\1/')
		echo "PARAM=\"$PARAM\""
		OPTION=$(echo "$PARAM " | grep -Eo '([a-z][a-z]|):([a-z][a-z]|) ' | tail -1)
		echo "OPTION=\"$OPTION\""
		TEXT=$(echo "$PARAM " | sed -r 's/ [a-z]?[a-z]?:[a-z]?[a-z]? / /g')
		TEXT=$(trim $TEXT)
		echo "TEXT=\"$TEXT\""
		if [ -z "$OPTION" ] ; then
		    OPTION=":en"
		fi
		if [ -z "$TEXT" ] ; then
		    TEXT="$LAST_SAY"
		fi
		TEXT=$(echo "$TEXT" | sed 's/^:*//')
		echo "timeout 5s trans -e google --brief $OPTION -- '$TEXT'"
		TRANSLATION=$(timeout 5s trans -e google --brief $OPTION -- "$TEXT" 2>/dev/null)
		if [ -z "$TRANSLATION" ] ; then
		    echo "timeout 5s trans -e bing --brief $OPTION -- '$TEXT'"
		    TRANSLATION=$(timeout 5s trans -e bing --brief $OPTION -- "$TEXT" 2>/dev/null)
		fi
		if [ $? -eq 0 ]; then
		    echo "TRANSLATION=\"$TRANSLATION\""
		    TRANSLATION=$(trim $TRANSLATION)
		    TRANSLATION=${TRANSLATION%%null}
		    TRANSLATION=${TRANSLATION##null}
		    TRANSLATION=$(urldecode $TRANSLATION)
		    TRANSLATION=$(echo $TRANSLATION | tr ';' ' ')
		    TRANSLATION=$(echo $TRANSLATION | sed 's#"#\\"#g')
		    echo "TRANSLATION=\"$TRANSLATION\""
		    echo "say \"Translation: $TRANSLATION\"" | "$SCRIPT_DIR/sendToServer.sh" &
		else
		    echo "say \"Translation: timeout\"" | "$SCRIPT_DIR/sendToServer.sh" &
		fi
	    fi
	fi
done
