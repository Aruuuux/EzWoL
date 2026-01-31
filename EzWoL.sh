#!/bin/bash

# --- VERSION & CONFIG ---
VERSION="2.1"
CONFIG_DIR="$HOME/.EzWoL"
CONFIG_FILE="$CONFIG_DIR/devices.conf"

# --- VERSION ARGUMENT CHECK ---
if [[ "$1" == "-v" || "$1" == "--version" ]]; then  
    echo -e "EzWoL version $VERSION"
    exit 0
fi

# --- COLORS ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

# --- UI FUNCTIONS ---
center_text() {
    local text="$1"
    local width=$(tput cols)
    local clean_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local padding=$(( (width - ${#clean_text}) / 2 ))
    [[ $padding -lt 0 ]] && padding=0
    printf "%${padding}s" " "
    echo -e "$text"
}

draw_header() {
    clear
    echo -e "${PURPLE}"
    center_text " _____     _ _ _       _ "
    center_text "|   __|___| | | | ___ | |"
    center_text "|   __|- _| | | |  _  | |"
    center_text "|_____|___|_____|___|_|_|"
    echo -e "${NC}"
    center_text "v$VERSION - Made by Aruuuux"
    echo -e "${PURPLE}$(printf '━%.0s' $(seq 1 $(tput cols)))${NC}"
}

# --- INITIALIZATION ---
if [[ ! -d "$CONFIG_DIR" ]]; then
    clear
    mkdir -p "$CONFIG_DIR"
    touch "$CONFIG_FILE"
    
    echo -e "${PURPLE}"
    center_text " _____     _ _ _       _ "
    center_text "|   __|___| | | | ___ | |"
    center_text "|   __|- _| | | |  _  | |"
    center_text "|_____|___|_____|___|_|_|"
    echo -e "${NC}"
    center_text "Welcome to EzWoL !"
    center_text "Running inital setup..."
    sleep 1.5
    center_text "${GREEN}Configuration folder created: $CONFIG_DIR${NC}"
    sleep 2
fi

# --- VALIDATIONS ---
validate_ip(){
    if [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        return 0
    else 
        return 1
    fi
}

validate_mac(){
    if [[ $1 =~ ^([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}$ ]]; then
        return 0
    else 
        return 1
    fi
}

# --- WAKEONLAN CHECK ---
if ! command -v wakeonlan &> /dev/null; then 
    echo -e "${RED}Error : wakeonlan is not installed.${NC}"
    read -p "Would you like to install it now? (y/n) :" install_choice
    
    if [[ "$install_choice" == y ]]; then   
        echo "Installing ..."
        sudo apt update && sudo apt install wakeonlan -y

        if command -v wakeonlan &> /dev/null; then 
            echo -e "${GREEN}Installation successful !${NC}"
            sleep 2
            clear
        else 
            echo -e "${RED}Installation failed. Check your connection.${NC}"
            exit 1
        fi
    
    else 
        echo -e "${RED}Error: EzWoL requires wakeonlan to function.${NC}"
        exit 1
    fi
fi

# --- DELETE DEVICE ---
delete_device(){
    while true; do
        draw_header
        center_text "─── DELETE A DEVICE ───"
        echo -e "\n"

        if [[ ! -s "$CONFIG_FILE" ]]; then 
            center_text "${RED}Device list is empty.${NC}"
            sleep 1 ; return
        fi
        
        mapfile -t lines < "$CONFIG_FILE"
        for i in "${!lines[@]}"; do 
            IFS=: read -r name ip bc mac <<< "${lines[$i]}"
            center_text "$((i+1))) ${GREEN}$name${NC} ($mac)"
        done

        echo -e "\n"
        center_text "q) Cancel and return to menu"
        echo -e "${PURPLE}$(printf '━%.0s' $(seq 1 $(tput cols)))${NC}"

        read -p "Number to delete: " del_choice

        if [[ "$del_choice" == "q" ]]; then return; fi

        if [[ "$del_choice" =~ ^[0-9]+$ ]] && [ "$del_choice" -le "${#lines[@]}" ] && [ "$del_choice" -gt 0 ]; then
            
            IFS=: read -r name ip bc mac <<< "${lines[$((del_choice-1))]}"
            
            sed -i "${del_choice}d" "$CONFIG_FILE"
            echo -e "\n$(center_text "${RED}Device '$name' deleted.${NC}")"
            sleep 1 ; break
        else
            echo -e "$(center_text "${YELLOW}Invalid choice.${NC}")"
            sleep 1
        fi
    done
}

# --- ADD DEVICE ---
add_device(){
    local name="" ip="" bc="" mac="" err=""

    while true; do
        draw_header
        center_text "─── ADD A NEW DEVICE ───"

        if [[ -n "$err" ]]; then
            echo -e "\n$(center_text "${RED}$err${NC}")"
        fi
        echo -e "\n"

        if [[ -z "$name" ]]; then
                read -p "  Device Name: " input
                if [[ -z "$input" ]]; then err="Name cannot be empty."
                elif grep -q "^$input:" "$CONFIG_FILE"; then err="This name already exists."
                else name="$input"; err=""; fi
    
        elif [[ -z "$ip" ]]; then
                echo -e "  Name : ${GREEN}$name${NC}"
                read -p "  IP Address (e.g. 192.168.1.50): " input
                if validate_ip "$input"; then ip="$input"; err=""
                else err="Invalid IP format."; fi

        elif [[ -z "$bc" ]]; then
                echo -e "  Name : ${GREEN}$name${NC} | IP : ${GREEN}$ip${NC}"
                read -p "  Use Broadcast ? (y/n) : " input
                if [[ "$input" == "y" || "$input" == "n" ]]; then
                    [[ "$input" == "y" ]] && bc="yes" || bc="no"; err=""
                else err="Please answer 'y' or 'n'."; fi
        
        elif [[ -z "$mac" ]]; then
                echo -e "  Name : ${GREEN}$name${NC} | IP : ${GREEN}$ip${NC} | Broadcast : ${GREEN}$bc${NC}"
                read -p "  MAC Address (e.g. AA:BB:CC:DD:EE:FF): " input
                if validate_mac "$input"; then mac="$input"; err=""; break
                else err="Invalid MAC format."; fi
            fi
    done

    echo "$name:$ip:$bc:$mac" >> "$CONFIG_FILE"
    echo -e "${GREEN}Device '$name' successfully saved !${NC}"
    sleep 2
}

# --- LOAD & WAKE DEVICES ---
load_devices(){
    while true; do
        draw_header
        center_text "─── WAKE UP A DEVICE ───"
        echo -e "\n"

        if [[ ! -s "$CONFIG_FILE" ]]; then 
            center_text "${RED}Device list is empty.${NC}"
            center_text "Add a device from the main menu."
            read -p "  Press Enter... " ; return
        fi

        mapfile -t lines < "$CONFIG_FILE"
        for i in "${!lines[@]}"; do 
            IFS=: read -r name ip bc mac <<< "${lines[$i]}"
            echo -e "$(center_text "$((i+1))) ${GREEN}$name${NC} | IP: $ip | MAC: $mac")"
        done
        
        echo -e "\n"
        center_text "q) Back to menu"
        echo -e "${PURPLE}$(printf '━%.0s' $(seq 1 $(tput cols)))${NC}"
        
        read -p "  Select device (Number) : " choice

        if [[ "$choice" == "q" ]]; then return; fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#lines[@]}" ] && [ "$choice" -gt 0 ]; then
            IFS=: read -r name ip bc mac <<< "${lines[$((choice-1))]}"
            clear
            draw_header
            echo -e "\n"
            center_text "${YELLOW} Waking up : $name${NC}"
            
            if [[ "$bc" == "yes" ]]; then 
                base_ip=$(echo $ip | cut -d. -f1-3)
                target_ip="${base_ip}.255"
                center_text "Broadcasting to : $target_ip"
                wakeonlan -i "$target_ip" "$mac"
            else 
                center_text "Sending direct packet to : $ip"
                wakeonlan -i "$ip" "$mac"
            fi
            
            echo -e "\n"
            center_text "${GREEN} Magic Packet sent !${NC}"
            read -p "  Press Enter to continue..."
            break
        else
            center_text "${RED}Invalid selection.${NC}"
            sleep 1
        fi
    done
}



# --- MAIN MENU ---
while true; do
    draw_header
    echo -e "\n"
    echo " 1) List & Wake Devices"
    echo " 2) Add New Device"
    echo " 3) Delete Device"
    echo " 4) Exit"
    echo -e "\n"
    read -p "Selection : " main_choice

    case $main_choice in
        1) load_devices ;;
        2) add_device ;;
        3) delete_device ;;
        4) echo "Goodbye !" ; exit 0 ;;
    esac
done