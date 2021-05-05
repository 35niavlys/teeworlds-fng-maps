#!/bin/bash

set -o noglob

EC_ADDRESS=127.0.0.1
CONF_DIR=conf

show_help() {
	echo "$0    Usage:"
	echo "  --conf-dir=<path>"
	echo "  -- <data to send>"
	exit 1
}


for i in "$@" ; do
	case $i in
		--conf-dir=*)
			CONF_DIR=${i#*=}
		;;
		--)
			shift;
			break;
		;;
		*)
			echo "Unknown param: $i"
			show_help
		;;
	esac
	shift
done

FILES=$(find $CONF_DIR -maxdepth 1 -name '*.cfg')

EC_PORT=$(grep -h "^ec_port" $FILES | awk '{print $2}')
EC_PWD=$(grep -h "^ec_password" $FILES | awk '{print $2}')

NETCAT="nc -q 1"
nc --help |& grep -q BusyBox && NETCAT="nc"

echo $NETCAT
{
	echo "$EC_PWD"
	if [ -t 0 ]; then
	    echo -e "$*"
	else
	    while read -r line ; do
		echo $line
	    done
	fi
} | $NETCAT "$EC_ADDRESS" "$EC_PORT"
