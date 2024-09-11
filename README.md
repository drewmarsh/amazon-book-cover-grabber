# Instructions
To view or download a high-resolution book cover image, provide the script with any of the options below:

- Amazon book **URL**: 
  - ```https://www.amazon.com/Name-Wind-Anniversary-Kingkiller-Chronicle/dp/0756413710```
- Amazon Standard Identification Number (**ASIN**): 
  - ```0756413710```
- 10-character International Standard Book Number (**ISBN**): 
  - ```0756413710```

# User Configuration
### Shell (.sh)
```
ASK_RUN_AGAIN=true

ASK_SAVE=true

DEFAULT_SAVE_DIR="$HOME/Downloads"
```

### PowerShell (.ps1)
```
$global:ASK_RUN_AGAIN = $true

$global:ASK_SAVE = $true

$global:DEFAULT_SAVE_DIR = "$env:USERPROFILE\Downloads"
```

# Direct Downloads
### [Windows (.ps1 file)](https://github.com/drewmarsh/amazon-book-cover-grabber/releases/download/v1.0.1/amazon_book_cover_grabber.ps1)
### [Linux/Mac (.sh file)](https://github.com/drewmarsh/amazon-book-cover-grabber/releases/download/v1.0.1/amazon_book_cover_grabber.sh)
