#!/bin/bash

# Version
VERSION="1.0"

if [[ "$1" == "-v" || "$1" == "--version" ]]; then  
    echo -e "EzWoL version $VERSION"
    exit 0
fi

# Configuration du stockage
CONFIG_DIR="$HOME/.wol-manager"
CONFIG_FILE="$CONFIG_DIR/devices.conf"

# Couleurs
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Initialisation
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
    center_text "Bienvenue dans EzWoL !"
    center_text "Configuration initiale en cours..."
    sleep 1.5
    center_text "${GREEN}Dossier de configuration créé : $CONFIG_DIR${NC}"
    sleep 2
fi

# Validations
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

# Verification wakeonlan
if ! command -v wakeonlan &> /dev/null; then 
    echo -e "${RED}Erreur : wakeonlan n'est pas installé.${NC}"
    read -p "Voulez-vous l'installer maintenant ? (y/n) :" install_choice
    
    if [[ "$install_choice" == y ]]; then   
        echo "Installation en cours ..."
        sudo apt update && sudo apt install wakeonlan -y

        if command -v wakeonlan &> /dev/null; then 
            echo -e "${GREEN}Installation réussie !${NC}"
            sleep 2
            clear
        else 
            echo -e "${RED}L'installation a échoué. Vérifiez votre connexion.${NC}"
            exit 1
        fi
    
    else 
        echo -e "${RED}Erreur : Sans wakeonlan le script ne fonctionnera pas.${NC}"
        exit 1
    fi
fi

# Supprimer un appareil
delete_device(){
    while true; do
        draw_header
        center_text "─── SUPPRIMER UN APPAREIL ───"
        echo -e "\n"

        if [[ ! -s "$CONFIG_FILE" ]]; then 
            center_text "${RED}La liste est vide.${NC}"
            sleep 1 ; return
        fi
        
        mapfile -t lines < "$CONFIG_FILE"
        for i in "${!lines[@]}"; do 
            IFS=: read -r name ip bc mac <<< "${lines[$i]}"
            center_text "$((i+1))) ${GREEN}$name${NC} ($mac)"
        done

        echo -e "\n"
        center_text "q) Annuler et retourner au menu"
        echo -e "${PURPLE}$(printf '━%.0s' $(seq 1 $(tput cols)))${NC}"

        read -p "Numéro à supprimer : " del_choice

        if [[ "$del_choice" == "q" ]]; then return; fi

        if [[ "$del_choice" =~ ^[0-9]+$ ]] && [ "$del_choice" -le "${#lines[@]}" ] && [ "$del_choice" -gt 0 ]; then
            
            IFS=: read -r name ip bc mac <<< "${lines[$((del_choice-1))]}"
            
            sed -i "${del_choice}d" "$CONFIG_FILE"
            echo -e "\n$(center_text "${RED}Appareil '$name' supprimé.${NC}")"
            sleep 1 ; break
        else
            echo -e "$(center_text "${YELLOW}Choix invalide.${NC}")"
            sleep 1
        fi
    done
}
# Ajout d'un appareil
add_device(){
    local name="" ip="" bc="" mac="" err=""
    local err=""

    while true; do
        draw_header
        center_text "─── AJOUTER UN APPAREIL ───"

        if [[ -n "$err" ]]; then
            echo -e "\n$(center_text "${RED}$err${NC}")"
        fi
        echo -e "\n"

        if [[ -z "$name" ]]; then
                read -p "  Nom de la machine : " input
                if [[ -z "$input" ]]; then err="Le nom ne peut pas être vide."
                elif grep -q "^$input:" "$CONFIG_FILE"; then err="Ce nom existe déjà."
                else name="$input"; err=""; fi
    
        elif [[ -z "$ip" ]]; then
                echo -e "  Nom : ${GREEN}$name${NC}"
                read -p "  Adresse IP (ex: 192.168.1.50) : " input
                if validate_ip "$input"; then ip="$input"; err=""
                else err="Format IP invalide."; fi

        elif [[ -z "$bc" ]]; then
                echo -e "  Nom : ${GREEN}$name${NC} | IP : ${GREEN}$ip${NC}"
                read -p "  Option Broadcast ? (y/n) : " input
                if [[ "$input" == "y" || "$input" == "n" ]]; then
                    [[ "$input" == "y" ]] && bc="yes" || bc="no"; err=""
                else err="Veuillez répondre par 'y' ou 'n'."; fi
        
        elif [[ -z "$mac" ]]; then
                echo -e "  Nom : ${GREEN}$name${NC} | IP : ${GREEN}$ip${NC} | BC : ${GREEN}$bc${NC}"
                read -p "  Adresse MAC (ex: AA:BB:CC:DD:EE:FF) : " input
                if validate_mac "$input"; then mac="$input"; err=""; break
                else err="Format MAC invalide."; fi
            fi
    done

    echo "$name:$ip:$broadcast:$mac" >> "$CONFIG_FILE"
    echo -e "${GREEN}Appareil '$name' enregistré !${NC}"
    sleep 2
}

# Liste des appareils
load_devices(){
    while true; do
        draw_header
        center_text "─── RÉVEILLER UN APPAREIL ───"
        echo -e "\n"

        if [[ ! -s "$CONFIG_FILE" ]]; then 
            center_text "${RED}La liste est vide.${NC}"
            center_text "Ajoutez un PC via le menu principal."
            read -p "  Appuyez sur Entrée..." ; return
        fi

        # Lecture et affichage des appareils
        mapfile -t lines < "$CONFIG_FILE"
        for i in "${!lines[@]}"; do 
            IFS=: read -r name ip bc mac <<< "${lines[$i]}"
            echo -e "$(center_text "$((i+1))) ${GREEN}$name${NC} | IP: $ip | MAC: $mac")"
        done
        
        echo -e "\n"
        center_text "q) Retour au menu"
        echo -e "${PURPLE}$(printf '━%.0s' $(seq 1 $(tput cols)))${NC}"
        
        read -p "  Action (Numéro du PC) : " choice

        if [[ "$choice" == "q" ]]; then return; fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#lines[@]}" ] && [ "$choice" -gt 0 ]; then
            IFS=: read -r name ip bc mac <<< "${lines[$((choice-1))]}"
            clear
            draw_header
            echo -e "\n"
            center_text "${YELLOW}⚡ Tentative de réveil de : $name${NC}"
            
            if [[ "$bc" == "yes" ]]; then 
                base_ip=$(echo $ip | cut -d. -f1-3)
                target_ip="${base_ip}.255"
                center_text "Diffusion Broadcast sur : $target_ip"
                wakeonlan -i "$target_ip" "$mac"
            else 
                center_text "Envoi direct sur : $ip"
                wakeonlan -i "$ip" "$mac"
            fi
            
            echo -e "\n"
            center_text "${GREEN} Magic Packet envoyé !${NC}"
            read -p "  Appuyez sur Entrée pour continuer..."
            break
        else
            center_text "${RED}Choix invalide.${NC}"
            sleep 1
        fi
    done
}

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

while true; do
    draw_header
    echo -e "\n"
    echo " 1) Liste des appareils enregistrés"
    echo " 2) Ajouter un appareil"
    echo " 3) Supprimer un appareil"
    echo " 4) Quitter"
    echo -e "\n"
    read -p "Choix : " main_choice

    case $main_choice in
        1) load_devices ;;
        2) add_device ;;
        3) delete_device ;;
        4) echo "Bye !" ; exit 0 ;;
    esac
done