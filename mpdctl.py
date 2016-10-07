#!/usr/bin/env python
from sys import argv
from mpd import MPDClient

def show_usage():
	print("""mpdctl -- quick mpd media control

usage: 
next       play next song in playlist
previous   play previous song in playlist
pause      toggle play/pause state
""")

h="localhost"
p=6600
invalid_command="No valid command passed"
c=MPDClient()
c.timeout=10
c.idletimeout=None
try:
	c.connect(h,p)
	if(len(argv)>1):
		d=argv[1]
		if("next" in d):
			c.next()
		elif("previous" in d):
			c.previous()
		elif("pause" in d):
			c.pause() if c.status()['state']=="play" else c.play()
		else:
			show_usage()
			#print(invalid_command)
	else:
		show_usage()
		#print(invalid_command)
except Exception as e:
	print("Error in connecting to %s:%s\nException:%s" % (h,p,e))	


