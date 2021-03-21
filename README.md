#Bizhawk Shuffler 2
written by authorblues, inspired by the [original Bizhawk Shuffler by Brossentia](https://github.com/brossentia/BizHawk-Shuffler)
[tested on Bizhawk v2.6.1 - http://tasvideos.org/BizHawk/ReleaseHistory.html](http://tasvideos.org/BizHawk/ReleaseHistory.html)

##INSTRUCTIONS:
1. unpack shuffler.lua and related folders into the same directory
    * shuffler-src/ = auxilliary scripts, config backup, and helper files (DO NOT MODIFY)
    * output-info/ = text files for streaming/broadcast software (files explained below)
2. run shuffler.lua in Bizhawk (before loading any game) but *DO NOT* complete the setup
3. place roms in the games/ folder created by the script (more games can be added later)
4. NOW complete the setup form - settings are explained below
5. press your chosen hotkey (default: Ctrl+Shift+End) to mark a game as complete

##SETTINGS:
* Seed - this value is the seed for the random number generator (if racing, choose same seed)
* Minimum Swap Time - minimum number of seconds between game swaps
* Maximum Swap Time - maximum number of seconds between game swaps
* Resuming a run? - check this box to resume a previous session (uses shuffler-src/config.lua)
* Hotkey: Completed Game - this is the hotkey (combo?) you will press to mark a game as complete
	* if background input is not enabled on Bizhawk, this hotkey may not work predictably

##OUTPUT FILES:
* current-game.txt - name of current game (based on filename, minus the extension)
* total-time.txt - APPROXIMATE total time spent on this shuffler
	* (this is an approximation. NOT a substitute for a timer, for speedrun/race purposes)
* total-swaps.txt - total number of times the shuffler has swapped games
* current-time.txt - APPROXIMATE time spent on current game during this shuffler
* current-swaps.txt - number of times the shuffler has swapped to the current game
