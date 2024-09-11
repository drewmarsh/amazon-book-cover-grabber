# Instructions
To view or download a high-resolution book cover image, provide the script with any of the options below:

- Amazon book **URL**: 
  - ```https://www.amazon.com/Name-Wind-Anniversary-Kingkiller-Chronicle/dp/0756413710```
- Amazon Standard Identification Number (**ASIN**): 
  - ```0756413710```
- 10-character International Standard Book Number (**ISBN**): 
  - ```0756413710```

# User Configuration
While it is not required to change any user settings to use these scripts out-of-the-box, some settings are easily configurable:

> ### Shell (.sh) script for Linux/Mac
> ```
> ASK_RUN_AGAIN=true
> ASK_SAVE=true
> DEFAULT_SAVE_DIR="$HOME/Downloads"
> ```
- ```ASK_RUN_AGAIN```: If set to true, the user is asked if they want to run the script again after it concludes.
- ```ASK_SAVE```: If set to true, the user is asked whether they want to save the image file to disk.
- ```DEFAULT_SAVE_DIR```: Should be set to the desired default save directory of the user.

> ### PowerShell (.ps1) script for Windows
> ```
> $global:ASK_RUN_AGAIN = $true
> $global:ASK_SAVE = $true
> $global:DEFAULT_SAVE_DIR = "$env:USERPROFILE\Downloads"
> ```
- ```$global:ASK_RUN_AGAIN```: If set to true, the user is asked if they want to run the script again after it concludes.
- ```$global:ASK_SAVE```: If set to true, the user is asked whether they want to save the image file to disk.
- ```$global:DEFAULT_SAVE_DIR```: Should be set to the desired default save directory of the user.

# Direct Downloads
### [Windows (.ps1 file)](https://github.com/drewmarsh/amazon-book-cover-grabber/releases/download/v1.0.1/amazon_book_cover_grabber.ps1)
### [Linux/Mac (.sh file)](https://github.com/drewmarsh/amazon-book-cover-grabber/releases/download/v1.0.1/amazon_book_cover_grabber.sh)
