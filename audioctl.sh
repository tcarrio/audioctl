#!/usr/bin/env bash
#	Simple utility for toggling audio channels
#	I don't like pulling up settings to do this so here's a short script 
# 	Obviously the indices listed only apply to my system
PROG_DIR="/home/$(whoami)/bin/audioctl"
OUTPUT_CONF="$PROG_DIR/outputs.conf"
INCREMENT='5'

# set preliminary values for output devices
# these can be different after reboots, so we'll check
# for the correct values as well
OUTPUT1="4"
OUTPUT2="1"

fullsink="$(pactl list sinks short | awk '{print $1}')"
runningsinks="$(pactl list sinks short | grep RUNNING | awk '{print $1}')"
if [ -f "$OUTPUT_CONF" ];then
	source $OUTPUT_CONF
fi

# Setup outputs by user conf file $OUTPUT_CONF
if [ -f "$OUTPUT_CONF" ]; then
	tmp_out=""
	tmp_desc=""
	while read -r line
	do
		case $line in
			Sink\ #*)
				tmp_out="$(echo $line|rev|cut -c 1|rev)";;

			device.description*)
				tmp_desc="$(echo $line | cut -d "=" -f 2)"
					case $tmp_desc in
						*$OUTPUT1_DESC*)
							OUTPUT1="$tmp_out";;
						*$OUTPUT2_DESC*)
							OUTPUT2="$tmp_out";;
					esac
		esac
	done < <(pactl list sinks)
fi

usage(){
	echo """audioctl - tcarrio's custom media manipulation script

		setup           configure output devices to use
		list            display output device configuration
		1               send audio to OUPUT1
		2               send audio to OUTPUT1
		sound           sound controls
		help            show usage help
"""
	return
}

sound_usage(){
	echo """audioctl sound [OPTION]

		up              turn the source volume up
		down            turn the source volume down
		toggle          toggle mute status
"""
	return
}
	
setup(){
	echo "Setup"
	index=1
	while read device; do
		printf "[%s] - %s\n" $index "$device"
		index=$(expr $index + 1)
	done < <(pactl list sinks | grep device.description | awk -F= '{print $2}' | cut -d '"' -f 2)
	printf "Please select up to two devices: "
	read newdevs

	# for (( c=1; c<$index; c++ )); do
	# 	for d in $newdevs; do
	# 		if [[ "$c" == "$d" ]]; then
	# 			conf1="OUTPUT1=$"
	#		fi
	# 	done
	# done

}

list(){
	if [ -f "$OUTPUT_CONF" ];then
		echo "The following was taken from your outputs.conf file:"
		cat $OUTPUT_CONF
	else
		echo """
No outputs.conf file was found, please use
`audioctl setup` to create one
"""
	fi
}

# check for and parse argument
case "$1" in
	setup)
		setup
		;;
	list)
		list
		;;
	1)
		output=$OUTPUT1
		;;
	2)
		output=$OUTPUT2
		;;
	toggle)
		current_device="$(pactl list short sink-inputs | tail -n 1 | awk '{print $2;}')"
		if [ "$current_device" == "$OUTPUT1" ]; then
			output=$OUTPUT2
		else
			output=$OUTPUT1
		fi
		;;
	sound)
		while read sink
		do
			case "$2" in	
				up)
					pactl set-sink-mute $sink false
					pactl set-sink-volume $sink +$INCREMENT%
					;;
				down)
					pactl set-sink-volume $sink -$INCREMENT%
					;;
				mute)
					pactl set-sink-mute $sink toggle
					;;
				*)
					sound_usage
					break
					;;
			esac
		done < <(pactl list sinks short | awk '{print $1}')
		;;
	*)
		usage
		exit 1
		;;
esac