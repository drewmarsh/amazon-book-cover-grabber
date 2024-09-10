#!/bin/sh

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is based on work by Leonardo Brondani Schenkel
# (https://github.com/lbschenkel/calibre-amazon-hires-covers)

# Function to extract ASIN from URL or use provided ASIN
get_asin() {
    local input="$1"
    local asin

    if echo "$input" | grep -qE "^https?://"; then
        asin=$(echo "$input" | sed -E '
            s/.*\/dp\/([A-Z0-9]{10}).*/\1/;
            s/.*\/product\/([A-Z0-9]{10}).*/\1/;
            s/.*\/gp\/product\/([A-Z0-9]{10}).*/\1/;
            s/.*\?asin=([A-Z0-9]{10}).*/\1/;
        ')
    else
        asin="$input"
    fi

    if echo "$asin" | grep -qE "^[A-Z0-9]{10}$"; then
        echo "$asin"
    else
        echo ""
    fi
}

# Function to open URL in default browser
open_url() {
    local url="$1"
    case "$(uname -s)" in
        Darwin*)  open "$url" ;;
        MINGW*)   start "$url" ;;
        MSYS*)    start "$url" ;;
        *)        xdg-open "$url" ;;
    esac
}

# Function to download and save image
download_image() {
    local url="$1"
    local asin="$2"
    local download_dir

    echo ""
    printf "Enter the directory where you want to save the image: "
    echo ""
    read -r download_dir

    # Expand ~ to home directory if used
    download_dir=$(eval echo "$download_dir")

    if [ ! -d "$download_dir" ]; then
        echo "The specified directory does not exist. Creating it now."
        mkdir -p "$download_dir"
        if [ $? -ne 0 ]; then
            echo "Failed to create directory. Please check permissions and try again."
            return 1
        fi
    fi

    local filename="${download_dir}/${asin}_cover.jpg"

    if command -v curl >/dev/null 2>&1; then
        curl -o "$filename" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$filename" "$url"
    else
        echo "Error: Neither curl nor wget is available. Unable to download the image."
        return 1
    fi

    if [ $? -eq 0 ]; then
        echo "Image saved as: $filename"
    else
        echo "Failed to download the image."
        return 1
    fi
}

# Function to process input and open cover
process_input() {
    local input="$1"
    local asin=$(get_asin "$input")

    if [ -z "$asin" ]; then
        echo ""
        echo "Invalid input. Please provide a valid Amazon URL or ASIN." >&2
        return 1
    fi

    local cover_url="https://ec2.images-amazon.com/images/P/${asin}.01.MAIN._SCRM_.jpg"
    echo ""
    echo "Opening cover image for ASIN: $asin"
    open_url "$cover_url"

    echo ""
    printf "Would you like to save this file to disk? (y/n): "
    read -r save_answer
    case $save_answer in
        [Yy]* ) 
            download_image "$cover_url" "$asin"
            ;;
    esac
}

# Main script
run_script() {
    while true; do
        echo ""
        printf "Enter the Amazon book URL or ASIN number (or 'q' to quit): "
        read -r input
        
        if [ "$input" = "q" ]; then
            return 0
        fi

        if process_input "$input"; then
            break
        fi
    done

    echo ""
    printf "Do you want to run the script again? (y/n): "
    read -r answer
    case $answer in
        [Yy]* ) return 1 ;;
        * ) return 0 ;;
    esac
}

if [ $# -eq 0 ]; then
    while true; do
        if run_script; then
            break
        fi
    done
else
    process_input "$1"
fi