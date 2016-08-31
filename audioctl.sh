#!/usr/bin/env bash
#	Simple utility for toggling audio channels
#	I don't like pulling up settings to do this so here's a short script 
# Obviously the indices listed only apply to my system


# set preliminary values for output devices
# these can be different after reboots, so we'll check
# for the correct values as well
HEADPHONES="4"
SPEAKERS="1"

source outputs.conf
#echo "$HEADPHONES_DESC"
#echo "$SPEAKERS_DESC"
# `pactl list sinks` to retrieve card info
# only the index is required for moving audio
# set output indices

tmp_out=""
tmp_desc=""

while read -r line
do
	#echo "$line"
	if [[ $line == "Sink #"* ]]
	then
		tmp_out="$(echo $line|rev|cut -c 1|rev)"
		#printf "Got tmp_out! Sink:%s\n" $tmp_out
	elif [[ $line == "device.description"* ]]
	then
		tmp_desc="$(echo $line | cut -d "=" -f 2)"
		#printf "Sink:%1s\tDesc:%s\n" "$tmp_out" "$tmp_desc"
		case $tmp_desc in
			*$HEADPHONES_DESC*)
				HEADPHONES="$tmp_out"
				#printf "Set headphones to sink %s\n" $HEADPHONES
				;;
			*$SPEAKERS_DESC*)
				SPEAKERS="$tmp_out"
				#printf "Set speakers to sink %s\n" $SPEAKERS
				;;
		esac
	fi
done < <(pactl list sinks | grep -e "Sink #" -e "device.description")

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
	for snd in $(pactl list short sink-inputs | awk '{print $1;}' )
	do 
		#echo "$snd"
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

#echo "$output"
main $output
	
