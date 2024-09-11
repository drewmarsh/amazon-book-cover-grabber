# User-configurable options
$global:ASK_RUN_AGAIN = $true
$global:ASK_SAVE = $true
$global:DEFAULT_SAVE_DIR = "$env:USERPROFILE\Downloads"
$global:USER_INPUT = ""

# Color codes
$GREEN = [System.ConsoleColor]::Green
$RED = [System.ConsoleColor]::Red
$YELLOW = [System.ConsoleColor]::Yellow
$MAGENTA = [System.ConsoleColor]::Magenta

function Write-Color {
    param (
        [string]$Text,
        [System.ConsoleColor]$Color
    )
    $oldColor = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $Color
    Write-Host $Text -NoNewline
    $host.UI.RawUI.ForegroundColor = $oldColor
}

function Get-YesNoInput {
    param (
        [string]$Prompt
    )
    while ($true) {
        Write-Host $Prompt -NoNewline
        Write-Color "Y" $GREEN
        Write-Host "/" -NoNewline
        Write-Color "N" $RED
        Write-Host "): " -NoNewline
        $response = Read-Host
        switch -Regex ($response.ToLower()) {
            '^y(es)?$' { return $true }
            '^n(o)?$' { return $false }
            default {
                Write-Host "`nInvalid input. Please enter " -NoNewline
                Write-Color "Y" $GREEN
                Write-Host " or " -NoNewline
                Write-Color "N" $RED
                Write-Host "."
            }
        }
    }
}

function Get-ASIN {
    if ($global:USER_INPUT -match "^https?://ec2\.images-amazon\.com/images/P/([A-Z0-9]{10})\.") {
        return $Matches[1]
    }
    elseif ($global:USER_INPUT -match "^https?://") {
        $patterns = @(
            "/dp/([A-Z0-9]{10})/?",
            "/product/([A-Z0-9]{10})/?",
            "/gp/product/([A-Z0-9]{10})/?",
            "\?asin=([A-Z0-9]{10})/?",
            "/([A-Z0-9]{10})(?:/|\?|$)"
        )
        foreach ($pattern in $patterns) {
            if ($global:USER_INPUT -match $pattern) {
                return $Matches[1]
            }
        }
    }
    elseif ($global:USER_INPUT -match "^[A-Z0-9]{10}$") {
        return $global:USER_INPUT
    }
    return ""
}

function Open-URL {
    param (
        [string]$URL
    )
    Start-Process $URL
}

function Remove-QuotesFromDirectoryPath {
    param (
        [string]$DirectoryPath
    )

    # Remove quotation marks from the directory path
    $CleanedPath = $DirectoryPath -replace '"', ''
    
    return $CleanedPath
}

function Save-Image {
    param (
        [string]$URL,
        [string]$ASIN
    )
    $save_dir = ""

    if (-not $global:DEFAULT_SAVE_DIR -or -not (Test-Path $global:DEFAULT_SAVE_DIR)) {
        Write-Host "`nEnter the custom directory where you want to save the image: " -NoNewline
        $save_dir = Read-Host
        $save_dir = [System.Environment]::ExpandEnvironmentVariables($save_dir)
        $save_dir = Remove-QuotesFromDirectoryPath -DirectoryPath $save_dir
    }
    elseif (-not $global:ASK_SAVE) {
        $save_dir = $global:DEFAULT_SAVE_DIR
    }
    else {
        Write-Host "`nHow would you like to save the image?`n"
        Write-Color "1." $YELLOW
        Write-Host " Use the default save directory (" -NoNewline
        Write-Color $global:DEFAULT_SAVE_DIR $MAGENTA
        Write-Host ") as defined in the script"
        Write-Color "2." $YELLOW
        Write-Host " Enter a custom directory`n"
        
        $validChoice = $false
        while (-not $validChoice) {
            Write-Host "Enter your choice (" -NoNewline
            Write-Color "1" $YELLOW
            Write-Host " or " -NoNewline
            Write-Color "2" $YELLOW
            Write-Host "): " -NoNewline
            $choice = Read-Host
            switch ($choice) {
                "1" { 
                    $save_dir = $global:DEFAULT_SAVE_DIR
                    $validChoice = $true
                }
                "2" {
                    Write-Host "`nEnter the custom directory where you want to save the image: " -NoNewline
                    $save_dir = Read-Host
                    $save_dir = [System.Environment]::ExpandEnvironmentVariables($save_dir)
                    $save_dir = Remove-QuotesFromDirectoryPath -DirectoryPath $save_dir
                    $validChoice = $true
                }
                default { 
                    Write-Host "`nInvalid choice. Please enter " -NoNewline
                    Write-Color "1" $YELLOW
                    Write-Host " or " -NoNewline
                    Write-Color "2" $YELLOW
                    Write-Host "."
                }
            }
        }
    }

    Write-Host ""

    if (-not $save_dir) {
        Write-Host "Error: No valid directory specified. Unable to save the image."
        return $false
    }

    if (-not (Test-Path $save_dir)) {
        Write-Host "The specified directory does not exist. Creating it now."
        try {
            New-Item -ItemType Directory -Path $save_dir -Force | Out-Null
        }
        catch {
            Write-Host "Failed to create directory. Please check permissions and try again."
            return $false
        }
    }

    $filename = Join-Path $save_dir "${ASIN}_cover.jpg"

    try {
        Invoke-WebRequest -Uri $URL -OutFile $filename
        Write-Host "Image saved to path: " -NoNewline
        Write-Color $filename $MAGENTA
        Write-Host ""
        return $true
    }
    catch {
        Write-Host "Failed to save the image. Error: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-InputProcessing {
    $asin = Get-ASIN

    if (-not $asin) {
        Write-Host "`nInvalid input. Please provide a valid " -NoNewline
        Write-Color "Amazon book URL" $YELLOW
        Write-Host ", " -NoNewline
        Write-Color "ASIN" $YELLOW
        Write-Host ", or " -NoNewline
        Write-Color "direct image URL" $YELLOW
        Write-Host "."
        return $false
    }

    $cover_url = "https://ec2.images-amazon.com/images/P/${asin}.01.MAIN._SCRM_.jpg"
    
    if ($global:USER_INPUT -match "^https?://ec2\.images-amazon\.com/images/P/[A-Z0-9]{10}\.") {
        $cover_url = $global:USER_INPUT
    }

    Write-Host "`nOpening cover image for " -NoNewline
    Write-Color "ASIN # $asin " $YELLOW
    Write-Host "in the default browser"
    Open-URL $cover_url

    if ($global:ASK_SAVE) {
        Write-Host ""
        if (Get-YesNoInput "Would you like to save this file to disk? (") {
            Save-Image $cover_url $asin
        }
    }

    return $true
}

function Main {
    while ($true) {
        Write-Host "`nEnter the " -NoNewline
        Write-Color "Amazon book URL" $YELLOW
        Write-Host " or " -NoNewline
        Write-Color "ASIN number" $YELLOW
        Write-Host " (alternatively, enter '" -NoNewline
        Write-Color "q" $YELLOW
        Write-Host "' to quit): " -NoNewline
        $global:USER_INPUT = Read-Host
        
        if ($global:USER_INPUT -eq "q") { break }

        if (Invoke-InputProcessing) {
            if ($global:ASK_RUN_AGAIN) {
                Write-Host ""
                if (-not (Get-YesNoInput "Do you want to run the script again? (")) {
                    break
                }
            }
            else {
                break
            }
        }
    }
}

Main