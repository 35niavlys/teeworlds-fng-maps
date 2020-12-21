#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "$0" )" && pwd )"

FUNCTION=cat
RUN=false

OPTION_MAX_CLIENTS=16
OPTION_NB_TEAMS=2
OPTION_MAX_PLAYERS_PER_TEAM=8
OPTION_TIMELIMIT=false
OPTION_WEAPONS=false
OPTION_PHYSIC=false
OPTION_RANDOM_MAP=false

OPTION_NO_ACTION="say idiots"

if [ -f "$CURRENT_DIR/SETTINGS" ] ; then
	. "$CURRENT_DIR/SETTINGS"
fi

###################

show_help() {
	echo "$0    Usage:"
	echo "  --run                                Will dump the generated config"
	echo "  --max-clients=<integer>              Default is 16"
	echo "  --nb-teams=[1|2]                     Default is 2"
	echo "  --max-players-per-team=<integer>     Default is 8"
	echo "  --physic=[true|false]            Default is false"
	echo "  --random-map=[true|false]            Default is false"
	echo "  --timelimit=[true|false]             Default is false"
	echo "  --tune=[true|false]                  Default is false"
	echo "  --weapons=[true|false]               Default is false"
	exit 1
}

for i in "$@" ; do
	case $i in
		--run)
			RUN=true
		;;
		--discard=*)
			FUNCTION="egrep -v ${i#*=}"
		;;
		--max-clients=*)
			OPTION_MAX_CLIENTS=${i#*=}
		;;
		--nb-teams=*)
			OPTION_NB_TEAMS=${i#*=}
		;;
		--max-players-per-team=*)
			OPTION_MAX_PLAYERS_PER_TEAM=${i#*=}
		;;
		--random-map=*)
			OPTION_RANDOM_MAP=${i#*=}
		;;
		--physic=*)
			OPTION_PHYSIC=${i#*=}
		;;
		--timelimit=*)
			OPTION_TIMELIMIT=${i#*=}
		;;
		--weapons=*)
			OPTION_WEAPONS=${i#*=}
		;;
		*)
			echo "Unknown param: $i"
			show_help
		;;
	esac
	shift
done

[ $RUN = false ] && show_help

###################

MAPS_DIR="$CURRENT_DIR/data/maps/"
cd "$MAPS_DIR" || { echo "$MAPS_DIR NOT EXISTS" ; exit 1 ; }

###################

set_prefix() {
	NB_PREFIX=$1
	PREFIX=""
	while [ $NB_PREFIX -gt 0 ] ; do
		PREFIX="$PREFIX│ "
		NB_PREFIX=$(( $NB_PREFIX - 1 ))
	done
}


add_to_conf() {
	echo "$*"
}

add_header() {
	set_prefix $1
	VAR1="$2"
	VAR2="$3"
	add_to_conf
	if [ -z "$VAR2" ] ; then
		VAR2="$OPTION_NO_ACTION"
	fi
	add_to_conf "add_vote \"$PREFIX╭──────┤ $VAR1\" \"$VAR2\""
}

add_vote() {
	set_prefix $1
	add_to_conf add_vote \"$PREFIX│ • $2\" \"$3\"
}

add_footer () {
	set_prefix $1
	FOOTER_SPACE="${FOOTER_SPACE}."
	add_to_conf "add_vote \"$PREFIX╰──────┤ $FOOTER_SPACE\" \"$OPTION_NO_ACTION\""
	add_empty_vote $1
}

add_empty_vote() {
	set_prefix $1
	EMPTY_VOTE_SPACE="$EMPTY_VOTE_SPACE "
	add_to_conf "add_vote \"$PREFIX$EMPTY_VOTE_SPACE\" \"$OPTION_NO_ACTION\""
	add_to_conf
}

set_stars() {
	STARS=""
	for (( i=1; i<=$1; i++ )) ; do  
		STARS="$STARS★"
	done
	for (( i=$1; i<5; i++ )) ; do  
		STARS="$STARS☆"
	done
}

###################

add_to_conf clear_votes

###################

add_header 0 Misc

add_vote 0 "Restart game" "restart"
if [ $OPTION_NB_TEAMS -gt 1 ] ; then
	add_vote 0 "Shuffle teams" "shuffle_teams"
fi

add_footer 0

###################

if [ $OPTION_MAX_PLAYERS_PER_TEAM -gt 0 ] ; then
	add_header 0 "Max player"
	
	MINIMAL_SPECTATOR_SLOTS=$(( $OPTION_MAX_CLIENTS - $OPTION_NB_TEAMS * $OPTION_MAX_PLAYERS_PER_TEAM ))
	[ $MINIMAL_SPECTATOR_SLOTS -lt 0 ] && MINIMAL_SPECTATOR_SLOTS=0
	
	for SPECTATOR_SLOTS in $(seq $(( $OPTION_MAX_CLIENTS - 2 )) -$OPTION_NB_TEAMS $MINIMAL_SPECTATOR_SLOTS) ; do
		NB=$(( $OPTION_MAX_CLIENTS - $SPECTATOR_SLOTS ))
		NB=$(( $NB / $OPTION_NB_TEAMS ))
		if [ $OPTION_NB_TEAMS -eq 1 ] ; then
			add_vote 0 "$NB players" "sv_spectator_slots $SPECTATOR_SLOTS"
		elif [ $OPTION_NB_TEAMS -eq 2 ] ; then
			add_vote 0 "$NB vs $NB" "sv_spectator_slots $SPECTATOR_SLOTS"
		fi
	done

	add_footer 0
fi

###################

add_header 0 "Score limit"

add_vote 0 "Score limit 100" "sv_scorelimit 100"
add_vote 0 "Score limit 250" "sv_scorelimit 250"
add_vote 0 "Score limit 500" "sv_scorelimit 500"
add_vote 0 "Score limit 700" "sv_scorelimit 700"
add_vote 0 "Score limit 1000" "sv_scorelimit 1000"

add_footer 0

###################

if [ "$OPTION_TIMELIMIT" = "true" ] ; then
	add_header 0 "Time limit"

	add_vote 0 "Time limit 5 min" "sv_timelimit 5"
	add_vote 0 "Time limit 10 min" "sv_timelimit 10"
	add_vote 0 "Time limit 20 min" "sv_timelimit 20"
	add_vote 0 "Time limit 40 min" "sv_timelimit 40"
	add_vote 0 "Time limit 60 min" "sv_timelimit 60"

	add_footer 0
fi

###################

add_header 0 Rounds

add_vote 0 "1 round par map" "sv_rounds_per_map 1"
add_vote 0 "2 round par map" "sv_rounds_per_map 2"
add_vote 0 "3 round par map" "sv_rounds_per_map 3"

add_footer 0

###################

if [ "$OPTION_WEAPONS" = "true" ] ; then
	add_header 0 "Weapons options"

	add_vote 0 "Reset Hammer and Laser" "sv_hammer_freeze 0;sv_hammer_scale_x 320;sv_hammer_scale_y 120;tune laser_damage 10;tune laser_bounce_cost 0"
	add_vote 0 "Laser : no damage" "laser_damage 10"
	add_vote 0 "Laser : Wallshoot only" "tune laser_damage 0;tune laser_bounce_cost -10"
	add_vote 0 "Hammer : no freeze" "sv_hammer_freeze 0"
	add_vote 0 "Hammer : freeze 3s" "sv_hammer_freeze 3"
	add_vote 0 "Hammer : freeze 5s" "sv_hammer_freeze 5"
	add_vote 0 "Hammer : freeze 10s" "sv_hammer_freeze 10"
	add_vote 0 "Hammer : Normal" "sv_hammer_scale_x 320;sv_hammer_scale_y 120"
	add_vote 0 "Hammer : Powerful" "sv_hammer_scale_x 640;sv_hammer_scale_y 240"
	add_vote 0 "Hammer : GOD" "sv_hammer_scale_x 960;sv_hammer_scale_y 360"

	add_footer 0
fi

###################

if [ "$OPTION_PHYSIC" = "true" ] ; then
	add_header 0 "Physic Options"

	add_vote 0 "Gravity ZERO" "tune gravity 0;say Warn ! Zero gravity means no lost of speed !"
	add_vote 0 "I believe i can fly" "tune gravity 0.05"
	add_vote 0 "Very low gravity" "tune gravity 0.20"
	add_vote 0 "Low gravity" "tune gravity 0.40"
	add_vote 0 "Normal gravity" "tune gravity 0.50"
	add_vote 0 "Hard gravity" "tune gravity 0.80"

	add_footer 0
fi

###################

add_header 0 Maps

if [ "$OPTION_RANDOM_MAP" = "true" ] ; then
	add_empty_vote 1
	add_vote 0 "Random map" "exec conf/vote_random_map.cfg"
	add_vote 0 "Random map >= ★★★★★" "exec conf/vote_random_map_5.cfg"
	add_vote 0 "Random map >= ★★★★☆" "exec conf/vote_random_map_4.cfg"
	add_vote 0 "Random map >= ★★★☆☆" "exec conf/vote_random_map_3.cfg"
	add_vote 0 "Random map >= ★★☆☆☆" "exec conf/vote_random_map_2.cfg"
	add_vote 0 "Random map >= ★☆☆☆☆" "exec conf/vote_random_map_1.cfg"
	add_vote 0 "Random rotation with all maps" "sv_maprotation activate_random_rotation"
	add_vote 0 "Random rotation >= ★★★★★" "sv_maprotation activate_random_rotation_5"
	add_vote 0 "Random rotation >= ★★★★☆" "sv_maprotation activate_random_rotation_4"
	add_vote 0 "Random rotation >= ★★★☆☆" "sv_maprotation activate_random_rotation_3"
	add_vote 0 "Random rotation >= ★★☆☆☆" "sv_maprotation activate_random_rotation_2"
	add_vote 0 "Random rotation >= ★☆☆☆☆" "sv_maprotation activate_random_rotation_1"
	add_empty_vote 1
fi

find -maxdepth 1 -type d | sort -f | while read MAPS_DIR ; do
	DIR_NAME="${MAPS_DIR#*/}"
	if [ -f "$MAPS_DIR/folder.name" ] ; then
		DIR_NAME=$(< "$MAPS_DIR/folder.name")
	fi
	
	MAPS=$(find "$MAPS_DIR" -maxdepth 1 -name '*.map' -type f | $FUNCTION | sort | sed 's/\.\/\(.*\)\.map/\1/')
	if [ -n "$MAPS" ] ; then
		MAP_ROTATION="sv_maprotation $(echo $MAPS)"
		MAP_ROTATION_LENGTH=$(echo "$MAP_ROTATION" | wc -c)
		if [ $MAP_ROTATION_LENGTH -gt 1000 ] ; then
			add_header 1 "$DIR_NAME" "say too much map"
		else
			add_header 1 "$DIR_NAME (set rotation)" "$MAP_ROTATION"
		fi
		echo "$MAPS" | while read MAP_PATH ; do
			unset NAME RANK
			NAME=$(basename "$MAP_PATH")
			if [ -f "$MAP_PATH.map.properties" ] ; then
				source "$MAP_PATH.map.properties"
				if [ -n "$RANK" ] ; then
					set_stars $RANK
					NAME="$STARS $NAME"
				fi
			fi
			add_vote 1 "$NAME" "sv_map $MAP_PATH"
		done
		add_footer 1
	fi
done

add_footer 0

###################
