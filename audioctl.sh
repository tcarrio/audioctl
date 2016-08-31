#!/usr/bin/env bash
#	Simple utility for toggling audio channels
#	I don't like pulling up settings to do this so here's a short script 
# Obviously the indices listed only apply to my system

# set output indices
HEADPHONES="4"
SPEAKERS="1"
# `pactl list cards` to retrieve card info
# only the index is required for moving audio

# show help 
usage(){
	echo """audioctl - transfer output to another channel

		headphones		send audio to headphones
		speakers  		send audio to speakers
		toggle    		switch audio output device
		help      		show usage help
"""
}
	
# run main toggle, checking for a passed value
main(){
	if [ -z "$1" ];then
		usage
	fi
	#pactl list short sink-inputs
	for sink in $(pactl list short sink-inputs | awk '{print $1;}' )
	do 
		#echo "$sink"
		pactl move-sink-input $sink $1 1>/dev/null 2>/dev/null
	done
}

# check for and parse argument
case "$1" in
	headphones)
		output=$HEADPHONES
		;;
	speakers)
		output=$SPEAKERS
		;;
	toggle)
		current_device="$(pactl list short sink-inputs | tail -n 1 | awk '{print $2;}')"
		if [ "$current_device" == "$HEADPHONES" ]; then
			output=$SPEAKERS
		else
			output=$HEADPHONES
		fi
		;;
	*)
		usage
		exit 1
		;;
esac

main $output
	
