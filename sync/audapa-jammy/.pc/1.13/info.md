PortAudio can ask for portaudio.h (the file is in portaudio19-dev).\
PortAudio and python 3.10 can report playback errors (install from [here](https://git.skeh.site/skeh/pyaudio) and add libportaudio2 package).\
The audio records are saved where *appdirs.user_data_dir("audapa")* points at (example: ~/.local/share/audapa/1650089398.wav).\
The points are saved at the file folder plus *\_audapacache\_* folder (example: /home/x/audapa/\_audapacache\_/example.wav.json).\
In the root folder at source, write "example.wav" and click the build button from top-right.\
[Git Page](https://github.com/colin-i/audapa)
