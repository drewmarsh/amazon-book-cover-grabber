#!/bin/sh

# User-configurable options
ASK_RUN_AGAIN=true
ASK_SAVE=true
DEFAULT_SAVE_DIR="$HOME/Downloads"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PINK='\033[0;35m'
NC='\033[0m' # No Color

print_color() {
    printf "%b%s%b" "$1" "$2" "$NC"
}

get_yes_no_input() {
    local prompt="$1"
    local response

    while true; do
        printf "%s" "$prompt"
        read -r response
        case "$response" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
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

get_asin() {
    local input="$1"
    local asin

    if echo "$input" | grep -qE "^https?://ec2\.images-amazon\.com/images/P/[A-Z0-9]{10}\."; then
        asin=$(echo "$input" | sed -E 's/.*\/P\/([A-Z0-9]{10})\..*/\1/')
    elif echo "$input" | grep -qE "^https?://"; then
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

open_url() {
    local url="$1"
    case "$(uname -s)" in
        Darwin*)  open "$url" ;;
        MINGW*)   start "$url" ;;
        MSYS*)    start "$url" ;;
        *)        xdg-open "$url" ;;
    esac
}

save_image() {
    local url="$1"
    local asin="$2"
    local save_dir

    if [ -z "$DEFAULT_SAVE_DIR" ] || [ ! -d "$DEFAULT_SAVE_DIR" ]; then
        printf "\nEnter the custom directory where you want to save the image: "
        read -r save_dir
        save_dir=$(eval echo "$save_dir")
    elif [ "$ASK_SAVE" = false ]; then
        save_dir="$DEFAULT_SAVE_DIR"
    else
        printf "\nHow would you like to save the image?\n\n"
        printf "%b%s%b Use the default save directory (%b%s%b) as defined in the script\n" "$YELLOW" "1." "$NC" "$PINK" "$DEFAULT_SAVE_DIR" "$NC"
        printf "%b%s%b Enter a custom directory\n\n" "$YELLOW" "2." "$NC"
        
        while true; do
            printf "Enter your choice (%b%s%b or %b%s%b): " "$YELLOW" "1" "$NC" "$YELLOW" "2" "$NC"
            read -r choice
            case $choice in
                1|1.) save_dir="$DEFAULT_SAVE_DIR"; break ;;
                2|2.)
                    printf "\nEnter the custom directory where you want to save the image: "
                    read -r save_dir
                    save_dir=$(eval echo "$save_dir")
                    break
                    ;;
                *) printf "\nInvalid choice. Please enter %b%s%b or %b%s%b.\n" "$YELLOW" "1" "$NC" "$YELLOW" "2" "$NC" ;;
            esac
        done
    fi

    printf "\n"

    # Ensure we have a non-empty directory
    if [ -z "$save_dir" ]; then
        printf "Error: No valid directory specified. Unable to save the image.\n"
        return 1
    fi

    if [ ! -d "$save_dir" ]; then
        printf "The specified directory does not exist. Creating it now.\n"
        mkdir -p "$save_dir" || { printf "Failed to create directory. Please check permissions and try again.\n"; return 1; }
    fi

    local filename="${save_dir}/${asin}_cover.jpg"

    if command -v curl >/dev/null 2>&1; then
        curl -o "$filename" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$filename" "$url"
    else
        printf "Error: Neither curl nor wget is available. Unable to save the image.\n"
        return 1
    fi

    if [ $? -eq 0 ]; then
        printf "\nImage saved as: %b%s%b\n" "$PINK" "$filename" "$NC"
    else
        printf "Failed to save the image.\n"
        return 1
    fi
}

process_input() {
    local input="$1"
    local asin=$(get_asin "$input")

    if [ -z "$asin" ]; then
        printf "\nInvalid input. Please provide a valid "
        print_color "$YELLOW" "Amazon book URL"
        printf ", "
        print_color "$YELLOW" "ASIN"
        printf ", or "
        print_color "$YELLOW" "direct image URL"
        printf ".\n" >&2
        return 1
    fi

    local cover_url="https://ec2.images-amazon.com/images/P/${asin}.01.MAIN._SCRM_.jpg"
    
    if echo "$input" | grep -qE "^https?://ec2\.images-amazon\.com/images/P/[A-Z0-9]{10}\."; then
        cover_url="$input"
    fi

    printf "\nOpening cover image for "
    print_color "$YELLOW" "ASIN # $asin "
    printf "in the default browser\n"
    open_url "$cover_url"

    if [ "$ASK_SAVE" = true ]; then
        printf "\n"
        if get_yes_no_input "Would you like to save this file to disk? ("$(print_color "$GREEN" "Y")"/"$(print_color "$RED" "N")"): "; then
            save_image "$cover_url" "$asin"
        fi
    fi
}

main() {
    local input
    
    while true; do
        printf "\nEnter the "
        print_color "$YELLOW" "Amazon book URL"
        printf " or "
        print_color "$YELLOW" "ASIN number"
        printf " (alternatively, enter '"
        print_color "$YELLOW" "q"
        printf "' to quit): "
        read -r input
        
        [ "$input" = "q" ] && break

        if process_input "$input"; then
            if [ "$ASK_RUN_AGAIN" = true ]; then
                printf "\n"
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