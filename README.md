# audioctl

I needed some way of easily modifying audio settings with shortcuts since I moved to [i3wm](https://github.com/i3/i3).

I really enjoyed how well everything could be manipulated with shortcuts but since I often switch between my desktop speakers and my headphones, I needed a way to control sink inputs, default sources, volume, mute toggling, etc. 

At the moment the easiest way to "install" this is by adding `audioctl.sh` or symlinking it to a file that is under your PATH (or modifying your PATH to include its directory). 

Once you can call upon `audioctl` this is how the script can be used..

## Usage: 

```
audioctl [OPTION]
		setup           configure output devices to use
		list            display output device configuration
		1               send audio to OUPUT1
		2               send audio to OUTPUT2
		toggle          toggle output device
		sound           sound controls
		help            show usage help

audioctl sound [OPTION]
		up              turn the source volume up
		down            turn the source volume down
		mute            toggle mute status
		help            show sound usage help

audioctl player [OPTION]
		next            play next song in queue
		prev            play previous song in queue
		toggle          toggle play/pause state
		pause           pause playlist
		play            play current song in queue
```
	

The configuration file defaults to `~/.config/audioctl/outputs.conf` for the time being. The first time you use this tool you will have the ability to manipulate anything through `audioctl sound`, however the toggle and audio source output manipulation can only be done after going through `audioctl setup`. 

`audioctl setup` will display all PulseAudio sound sources. Enter any sources you would like to use so the system can save the description for later use. Sometimes the `index` value changes on these sources so maintaining an admittedly smaller data set of just indices hasn't worked for me. 

Known issues: 

* The number of output sources supported is only 2. This is what I needed and when I threw this together I did it with that spec in mind. I will hopefully be expanding upon my current configuration to allow as many sources as your PulseAudio daemon can identify available with indexed iteration. 
* No built packages for any distro
* In between configuration and code separation

Future development:

* The PulseAudio website could be more readily used for existing solutions, such as [this FAQ entry](https://www.freedesktop.org/wiki/Software/PulseAudio/FAQ/#index39h3) which details how to move all applications to a certain output, something my solution currently does along with setting default audio source. 
* Audio output -> input setup, mapping output from one source to another sink. Could be useful for combining audio channels to feeds. 
* Pooled audio for streams (combined input/output) since OBS only seems to be pulling one source/sink at a time for me. 
* Restructure name/id configuration as according to [this Arch tip](https://wiki.archlinux.org/index.php/PulseAudio#default.pa), PulseAudio arbitrarily creates the id and is not reliable. 
	* Split config data into several files
	* `names.conf`, pulls names from `audioctl setup` selections for long-term use
	* `ids.conf`, loads `names.conf` and stores individual indices while service/program is running
* Daemonize
