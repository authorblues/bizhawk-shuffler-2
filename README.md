# Bizhawk Shuffler 2
* written by authorblues, inspired by [Brossentia's Bizhawk Shuffler](https://github.com/brossentia/BizHawk-Shuffler), based on slowbeef's original project
* [tested on Bizhawk v2.6.3-v2.9.1](https://github.com/TASVideos/BizHawk/releases/)  
* [click here to download the latest version](https://github.com/authorblues/bizhawk-shuffler-2/archive/refs/heads/main.zip)

**This version has been revised by Laxaria to add some additional functionality. Changelog & Details below.**

## Laxaria Revisions Changelog

### Version 1.0.0_Laxaria

* [FEATURE] Write out to `swap_log.txt` with a tab-separated line on each swap indicating Total Swaps, Epoch Swap was Made, Current Total Frame, Current Game Frame, Current Game's Current Swaps, Current Game Name, Next Game.
* [FEATURE] Write out to `completed_log.txt` with a tab-separated line each time a game is completed, indicating Total Swaps, Epoch, Current Total Frame, Current Game Frame, Current Game Total Swaps, Current Game Name
* [BUG-FIX] Force advancing the `config.total_swaps` counter and `config.game_swaps[config.current_game]` counter at the end of the `swap_game()` function rather than in the `on_game_load()` function. This ensures the advoancement of the counters occur only when a swap occurs, and not when a game is loaded.

## Additional Resources
* **[Setup Instructions](https://github.com/authorblues/bizhawk-shuffler-2/wiki/Setup-Instructions)**
* [Frequently Asked Questions](https://github.com/authorblues/bizhawk-shuffler-2/wiki/Frequently-Asked-Questions) - important info!
* [How to Create a Shuffler Plugin](https://github.com/authorblues/bizhawk-shuffler-2/wiki/How-to-Create-a-Shuffler-Plugin)
