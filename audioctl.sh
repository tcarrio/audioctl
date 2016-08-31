#!/usr/bin/env bash
#	Simple utility for toggling audio channels
#	I don't like pulling up settings to do this so here's a short script 
# Obviously the indices listed only apply to my system

# set output indices
while read -r line
do
	if [[ $line == "Sink #"* ]]
	then
		tmp_out="${line:-1}"
		echo "$tmp_out"
	else if [[ $line == "device.description" ]]
	then
		tmp_desc="$(echo $line | cut -d "=" -f 2)"
		case $tmp_desc in
			*$HEADPHONE_DESC*)
				HEADPHONES=$tmp_out
				;;
			*$SPEAKERS_DESC*)
				SPEAKERS=$tmp_out
				;;
		esac

		# or use ifs?
		if [[ $tmp_desc == "$HEADPHONE_DESC" ]]
		then
			HEADPHONES=$tmp_out
		else if [[ $(echo $line | 
	fi
done < <(pactl list sinks | grep -e "Sink #" -e "device.description")

HEADPHONES="4"
SPEAKERS="1"
# `pactl list sinks` to retrieve card info
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
	pactl list short sink-inputs
	for snd in $(pactl list short sink-inputs | awk '{print $1;}' )
	do 
		echo "$snd"
		pactl move-sink-input $snd $1 1>/dev/null 2>/dev/null
		pactl set-default-sink $1 1>/dev/null 2>/dev/null
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

echo "$output"
main $output
	
