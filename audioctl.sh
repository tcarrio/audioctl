#!/usr/bin/env bash

# Configure data/cache directory variables
# Following XDG Base Directory Specification[1]
# [1](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
if [[ -n "$XDG_CONFIG_HOME" ]] && [[ -d "$XDG_CONFIG_HOME" ]]; then
	CONF_DIR="$XDG_CONFIG_HOME/audioctl"
else
	CONF_DIR="/home/$(whoami)/.config/audioctl"
fi
if [[ -n "$XDG_CACHE_HOME" ]] && [[ -d "$XDG_CONFIG_HOME" ]]; then
	CACHE_DIR="$XDG_CACHE_HOME/audioctl"
else
	CACHE_DIR="/home/$(whoami)/.cache/audioctl"
fi
OUTPUT_CONF="$CONF_DIR/outputs.conf"
OUTPUT_DESC_CONF="$CONF_DIR/output_desc.conf"
TMP_CONF="$CACHE_DIR/tmp.conf"
if [ -d "$CONF_DIR" ];then
	if [ -f "$OUTPUT_DESC_CONF" ];then
		source $OUTPUT_DESC_CONF
	fi
	if [ -f "$OUTPUT_CONF" ]; then
		import_outputs "$OUTPUT_CONF"
	fi
else
	mkdir -p "$CONF_DIR"
fi

# Increment value for increasing/decreasing volume
INCREMENT='5'

#useful array join function with parameter for IFS
#function join_by { local IFS="$1"; shift; echo "$*"; }
#join_by , "${array[@]}"

usage(){
	echo """audioctl - tcarrio's custom media manipulation script

		setup           configure output devices to use
		list            display output device configuration
		1               send audio to OUPUT1
		2               send audio to OUTPUT2
		toggle          toggle output device
		sound           sound controls
		help            show usage help
"""
	return
}

sound_usage(){
	echo """audioctl sound [OPTION]

		up              turn the source volume up
		down            turn the source volume down
		mute            toggle mute status
		help            show sound usage help
"""
	return
}

map_devices(){
	# Setup outputs by user conf file $OUTPUT_DESC_CONF
	if [ -f "$OUTPUT_DESC_CONF" ]; then
		tmp_out=""
		tmp_desc=""
		while read -r line
		do
			case $line in
				Sink\ #*)
					tmp_out="$(echo $line|rev|cut -c 1|rev)"
					;;

				device.description*) # start here for finding outputs
					tmp_desc="$(echo $line | cut -d "=" -f 2)"
						case $tmp_desc in
							*$OUTPUT1_DESC*)
								OUTPUT1="$tmp_out"
								;;
							*$OUTPUT2_DESC*)
								OUTPUT2="$tmp_out"
								;;
							*$OUTPUT3_DESC*)
								OUTPUT3="$tmp_out"
								;;
							*$OUTPUT4_DESC*)
								OUTPUT4="$tmp_out"
								;;
							*$OUTPUT5_DESC*)
								OUTPUT5="$tmp_out"
								;;
							*$OUTPUT6_DESC*)
								OUTPUT6="$tmp_out"
								;;
							*$OUTPUT7_DESC*)
								OUTPUT7="$tmp_out"
								;;
							*$OUTPUT8_DESC*)
								OUTPUT8="$tmp_out"
								;;
							*$OUTPUT9_DESC*)
								OUTPUT9="$tmp_out"
								;;
						esac
			esac
		done < <(pactl list sinks)
		OUTPUTS=( $OUTPUT1 $OUTPUT2 $OUTPUT3 $OUTPUT4 $OUTPUT5 $OUTPUT6 $OUTPUT7 $OUTPUT8 $OUTPUT9 )
	fi
}

setup(){
	# Confirm cache directory exists
	if [ ! -d "$CACHE_DIR" ];then
		mkdir -p "$CACHE_DIR"
	fi

	# Show all PulseAudio sinks for user selection
	printf "Detected PulseAudio devices:\n"
	list_index=1
	while read device; do
		printf "[%s] - %s\n" $list_index "$device"
		list_index=$(expr $list_index + 1)
	done < <(pactl list sinks | grep device.description | awk -F= '{print $2}' | cut -d '"' -f 2)
	printf "Please select your devices (separated by spaces): "
	read newdevs

	# Create array from user selects and setup sed arguments for parsing
	newdevsarr=($newdevs)
	seddevs=""
	for i in ${newdevsarr[@]};do
		seddevs+="$(printf '%s %sp ' '-e' $i)"
	done
	pactl list sinks|grep device.description|awk -F= '{print $2}'|cut -d '"' -f 2|sed -n $seddevs>$TMP_CONF
	local IFS='
'	# ^ IFS set to '\n'
	
	# Iterate over lines in device descriptions to generate sourced file to go to output_desc.conf
	conf_index=1
	if [ -f "$OUTPUT_DESC_CONF" ]; then
		rm $OUTPUT_DESC_CONF
	fi
	cat $TMP_CONF|while read line; do
		printf 'OUTPUT%s_DESC="%s"\n' $conf_index $line >> $OUTPUT_DESC_CONF
		conf_index=$(expr $conf_index + 1)
	done
	rm $TMP_CONF
}

list(){
	if [ -f "$OUTPUT_DESC_CONF" ];then
		echo "The following was taken from your output_desc.conf file:"
		cat $OUTPUT_DESC_CONF
	else
		echo "No output_desc.conf file was found, please use audioctl setup to create one"
	fi
}

do_sound(){
	while read sink
	do
		case "$1" in	
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
}

do_toggle(){
	if [ -n "$OUTPUT1" ];then
		echo "Current OUTPUT variables: ${OUTPUTS[@]}"
		#printf "Current OUTPUT variables:\n%s\n%s\n" "$OUTPUT1" "$OUTPUT2"
		current_device="$(pactl list short sink-inputs | tail -n 1 | awk '{print $2;}')"
		out_index=0
		while [ $out_index -lt ${#OUTPUTS[@]} ]; do
			if [ "$current_device" == "${OUTPUTS[$out_index]}" ];then
				output=${OUTPUTS[$(expr $out_index + 1)]}
				out_index=${#OUTPUTS[@]}
			fi
			out_index=$(expr $out_index + 1)
		done

		# confirm $output has a sink value
		if [ -z "$output" ]; then
			output=$OUTPUT1
		fi

		printf "output = %s\n" $output
		while read sinkinput; do
			pactl move-sink-input $sinkinput $output 
		done < <(pactl list short sink-inputs | awk '{print $1;}')
		pactl set-default-sink $output
	else
		echo "You have not configured your output devices! Please use audioctl setup to start your configuration"
	fi
}

do_player(){
	[ -n "$(which mpdctl)" ] && mpdctl $1
}

map_devices #sets all $OUTPUT_ variables from $OUTPUT_DESC_CONF

# check for and parse argument
case "$1" in
	setup)
		setup
		;;
	list)
		list
		;;
	1|2|3|4|5|6|7|8|9)
		if [ -n "$OUTPUT$1" ]; then
			output=${OUTPUTS[0]}
		else
			echo "No configured device for that index"
		fi
		;;
	toggle)
		do_toggle
		;;
	sound)
		shift
		if [ -n "$1" ];then
			do_sound $1
		fi
		;;
	player)
		shift
		if [ -n "$1" ];then
			do_player $1
		fi
		;;
	*)
		usage
		exit 1
		;;
esac
