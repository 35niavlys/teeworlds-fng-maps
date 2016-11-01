#!/bin/bash

EC_ADDRESS=127.0.0.1

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

test -z "$CONF_DIR" && show_help

FILES=$(find $CONF_DIR -maxdepth 1 -name '*.cfg')

EC_PORT=$(grep -h "^ec_port" $FILES | awk '{print $2}')
EC_PWD=$(grep -h "^ec_password" $FILES | awk '{print $2}')


{
	echo "$EC_PWD"
	if [ -t 0 ]; then
	    echo -e "$*"
	else
	    while read -r line ; do
		echo $line
	    done
	fi
} | nc "$EC_ADDRESS" "$EC_PORT"
