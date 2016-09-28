#!/usr/bin/env bash
#	Simple utility for toggling audio channels
#	I don't like pulling up settings to do this so here's a short script 
# 	Obviously the indices listed only apply to my system
PROG_DIR="/home/$(whoami)/.config/audioctl"
OUTPUT_CONF="$PROG_DIR/outputs.conf"
INCREMENT='5'

# set preliminary values for output devices
# these can be different after reboots, so we'll check
# for the correct values as well
OUTPUT1="4"
OUTPUT2="1"

if [ -d "$PROG_DIR" ];then
	if [ -f "$OUTPUT_CONF" ];then
		source $OUTPUT_CONF
	fi
else
	mkdir -p "$PROG_DIR"
fi

# Setup outputs by user conf file $OUTPUT_CONF
if [ -f "$OUTPUT_CONF" ]; then
	#echo "Reading outputs.conf"
	tmp_out=""
	tmp_desc=""
	while read -r line
	do
		case $line in
			Sink\ #*)
				tmp_out="$(echo $line|rev|cut -c 1|rev)"
				;;

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

#function join_by { local IFS="$1"; shift; echo "$*"; }
#join_by , "${array[@]}"

usage(){
	echo """audioctl - tcarrio's custom media manipulation script

		setup           configure output devices to use
		list            display output device configuration
		1               send audio to OUPUT1
		2               send audio to OUTPUT2
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
		help            show sound usage help
"""
	return
}
	
setup(){
	echo "Setup"
	list_index=1
	while read device; do
		printf "[%s] - %s\n" $list_index "$device"
		list_index=$(expr $list_index + 1)
	done < <(pactl list sinks | grep device.description | awk -F= '{print $2}' | cut -d '"' -f 2)
	printf "Please select up to two devices: "
	read newdevs
	newdevsarr=($newdevs)
	seddevs=""
	for i in ${newdevsarr[@]};do
		seddevs+="$(printf '%s %sp ' '-e' $i)"
	done
	pactl list sinks|grep device.description|awk -F= '{print $2}'|cut -d '"' -f 2|sed -n $seddevs>$PROG_DIR/tmp.conf
	local IFS='
'	
	conf_index=1
	if [ -f "$OUTPUT_CONF" ]; then
		rm $OUTPUT_CONF
	fi
	cat $PROG_DIR/tmp.conf|while read line; do
		printf 'OUTPUT%s_DESC="%s"\n' $conf_index $line >> $OUTPUT_CONF
		conf_index=$(expr $conf_index + 1)
	done
	rm $PROG_DIR/tmp.conf
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
		if [ -n "$OUTPUT1" ];then
			current_device="$(pactl list short sink-inputs | tail -n 1 | awk '{print $2;}')"
			if [ "$current_device" == "$OUTPUT1" ]; then
				output=$OUTPUT2
			else
				output=$OUTPUT1
			fi
			#printf "output = %s\n" $output
			while read sinkinput; do
				pactl move-sink-input $sinkinput $output 
			done < <(pactl list short sink-inputs | awk '{print $1;}')
			pactl set-default-sink $output
		else
			echo """
You have not configured your output devices!
Please use `audioctl setup` to start your configuration
"""
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
