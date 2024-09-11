#!/bin/sh

# User-configurable options
ask_run_again=true
ask_save=true
default_save_dir="$HOME/Downloads"  # Default save-to-disk directory

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is based on work by Leonardo Brondani Schenkel
# (https://github.com/lbschenkel/calibre-amazon-hires-covers)

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print with color
print_color() {
    printf "%b%s%b" "$1" "$2" "$NC"
}

# Function to get yes/no input
get_yes_no_input() {
    local prompt="$1"
    local response

    while true; do
        printf "%s" "$prompt"
        read -r response
        case "$response" in
            [Yy]) return 0 ;;
            [Nn]) return 1 ;;
            *)
                printf "\nInvalid input. Please enter "
                print_color "$GREEN" "Y"
                printf " or "
                print_color "$RED" "N"
                printf ".\n\n"
                ;;
        esac
    done
}

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

# Function to save image to disk
save_image() {
    local url="$1"
    local asin="$2"
    local save_dir

    if [ -z "$default_save_dir" ] || [ ! -d "$default_save_dir" ]; then
        # Default save directory is invalid or empty, skip to custom directory input
        echo ""
        printf "Enter the custom directory where you want to save the image: "
        read -r save_dir
        # Expand ~ to home directory if used
        save_dir=$(eval echo "$save_dir")
    elif [ "$ask_save" = false ]; then
        save_dir="$default_save_dir"
    else
        echo ""
        echo "How would you like to save the image?"
        echo ""
        printf "%b%s%b Use the default save directory (%s) as defined in the script\n" "$YELLOW" "1." "$NC" "$default_save_dir"
        printf "%b%s%b Enter a custom directory\n" "$YELLOW" "2." "$NC"
        echo ""
        printf "Enter your choice (%b%s%b or %b%s%b): " "$YELLOW" "1" "$NC" "$YELLOW" "2" "$NC"
        
        while true; do
            read -r choice
            case $choice in
                1|1.)
                    save_dir="$default_save_dir"
                    break
                    ;;
                2|2.)
                    echo ""
                    printf "Enter the custom directory where you want to save the image: "
                    read -r save_dir
                    # Expand ~ to home directory if used
                    save_dir=$(eval echo "$save_dir")
                    break
                    ;;
                *)
                    echo ""
                    printf "Invalid choice. Please enter %b%s%b or %b%s%b: " "$YELLOW" "1" "$NC" "$YELLOW" "2" "$NC"
                    ;;
            esac
        done
    fi

    echo ""  # Add a blank line after user input

    if [ ! -d "$save_dir" ]; then
        echo "The specified directory does not exist. Creating it now."
        mkdir -p "$save_dir"
        if [ $? -ne 0 ]; then
            echo "Failed to create directory. Please check permissions and try again."
            return 1
        fi
    fi

    local filename="${save_dir}/${asin}_cover.jpg"

    if command -v curl >/dev/null 2>&1; then
        curl -o "$filename" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$filename" "$url"
    else
        echo "Error: Neither curl nor wget is available. Unable to save the image."
        return 1
    fi

    if [ $? -eq 0 ]; then
        echo "Image saved as: $filename"
    else
        echo "Failed to save the image."
        return 1
    fi
}

# Function to process input and open cover
process_input() {
    local input="$1"
    local asin=$(get_asin "$input")

    if [ -z "$asin" ]; then
        echo ""
        printf "Invalid input. Please provide a valid "
        print_color "$YELLOW" "Amazon book URL"
        printf " or "
        print_color "$YELLOW" "ASIN"
        echo "." >&2
        return 1
    fi

    local cover_url="https://ec2.images-amazon.com/images/P/${asin}.01.MAIN._SCRM_.jpg"
    echo ""
    printf "Opening cover image for "
    print_color "$YELLOW" "ASIN # $asin "
    echo "in the default browser"
    open_url "$cover_url"

    if [ "$ask_save" = true ]; then
        echo ""
        if get_yes_no_input "Would you like to save this file to disk? ("$(print_color "$GREEN" "Y")"/"$(print_color "$RED" "N")"): "; then
            save_image "$cover_url" "$asin"
        fi
    fi
}

# Main script
main() {
    local input
    
    while true; do
        echo ""
        printf "Enter the "
        print_color "$YELLOW" "Amazon book URL"
        printf " or "
        print_color "$YELLOW" "ASIN number"
        printf " (alternatively, enter '"
        print_color "$YELLOW" "q"
        printf "' to quit): "
        read -r input
        
        if [ "$input" = "q" ]; then
            break
        fi

        if process_input "$input"; then
            if [ "$ask_run_again" = true ]; then
                echo ""
                if ! get_yes_no_input "Do you want to run the script again? ("$(print_color "$GREEN" "Y")"/"$(print_color "$RED" "N")"): "; then
                    break
                fi
            else
                break
            fi
        fi
    done
}

main "$@"