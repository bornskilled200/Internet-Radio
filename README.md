Internet-Radio
==============

A setup to make a linux machine play some streams, tailored for the Raspberry Pi on Rasbian OS
Some of the main features are
* Start playing music as soon as the Raspberry Pi turns on
* Say which stream is playing using Google's TTS
* Simple way to control the Raspberry pi using GPIO pins

# Requirements
There are some requirements to run this script especially if you want all the bells and whistles
##Software
* mplayer

  The reason for this is that omxplayer seems to cut off some of the mp3 of the Text-to-Speech at the end
  
##Hardware
* button for GPIO pins 23 and 24, for shuttdown down
* button for GPIO pins 17 and 22, for going to the next stream

  These values are not concrete, the variables you need to change are at the top of the setup script.

# Installation
To setup your Raspberry Pi easily, simply copy the following code into your terminal
You might want to take a look at the file first to configure it to your liking.
```Bash
wget https://github.com/bornskilled200/Internet-Radio/raw/master/setup.sh
sudo bash setup.sh
sudo reboot
```
