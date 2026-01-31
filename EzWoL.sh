#!/bin/bash

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
    mkdir -p "$CONFIG_DIR"
    echo -e "${CYAN}Initialisation : Dossier de config créé dans $CONFIG_DIR${NC}"
fi

if [[ ! -f "$CONFIG_FILE" ]]; then 
    touch "$CONFIG_FILE"
fi

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
    clear
    clear
    echo -e "${PURPLE}------------------------------------------${NC}"
    echo -e "${RED}        [ SUPPRIMER UN APPAREIL ]${NC}"
    echo -e "${PURPLE}------------------------------------------${NC}"

    if [[ ! -s "$CONFIG_FILE" ]]; then 
        echo "La liste est vide." ; sleep 1 ; return
    fi
    
    mapfile -t lines < "$CONFIG_FILE"
    for i in "${!lines[@]}"; do 
        IFS=: read -r name ip bc mac <<< "${lines[$i]}"
        echo -e "$((i+1))) $name"
    done
    echo "q) Annuler"

    read -p "Numéro à supprimer : " del_choice
    if [[ "$del_choice" =~ ^[0-9]+$ ]] && [ "$del_choice" -le "${#lines[@]}" ]; then
        sed -i "${del_choice}d" "$CONFIG_FILE"
        echo -e "${GREEN}Appareil supprimé !${NC}"
        sleep 1
    fi
}
# Ajout d'un appareil
add_device(){
    echo -e "\n${YELLOW}[ Ajouter un Appareil ]${NC}"
    read -p "Nom (ex: Windows1, Linux2, Mac3) : " name
    read -p "IP (ex: 192.168.1.50) : " ip
    read -p "Broadcast ? (y/n) : " bc_choice
    [[ "$bc_choice" == "y" ]] && broadcast="yes" || broadcast="no"
    read -p "Adresse MAC (ex: AA:BB:CC:DD:EE:FF) : " mac

    echo "$name:$ip:$broadcast:$mac" >> "$CONFIG_FILE"
    echo -e "${GREEN}Appareil enregistré !${NC}"
    sleep 1
}

# Liste des appareils
load_devices(){
    clear
    echo -e "${CYAN} == LISTE DES APPAREILS ==${NC}"

    if [[ ! -s "$CONFIG_FILE" ]]; then 
        echo -e "${RED}La liste est vide.${NC}"
        echo -e "Utilisez la deuxieme option pour ajouter un PC."
        read -p "Appuyez sur Entrée..."
        return
    fi

    mapfile -t lines < "$CONFIG_FILE"
    for i in "${!lines[@]}"; do 
        IFS=: read -r name ip bc mac <<< "${lines[$i]}"
        echo -e "$((i+1)) ${GREEN}$name${NC} | $mac | IP: $ip"
    done
    echo -e "q) Retour"

    read -p "Action : " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#lines[@]}" ]; then
        IFS=: read -r name ip bc mac <<< "${lines[$((choice-1))]}"
        echo -e "${YELLOW}Réveil de $name ... ${NC}"

        if [[ "$bc" == "yes" ]]; then 
            wakeonlan "$mac"
        else 
            wakeonlan -i "$ip" "$mac"
        fi
        read -p "Appuyez sur Entrée pour continuer..."
    fi
}

while true; do
    clear
    echo -e "${PURPLE} ---------------------------- "
    echo -e "     EZWOL MANAGER     "
    echo -e "---------------------------- ${NC}"
    echo " 1) Liste des appareils enregistrés"
    echo " 2) Ajouter un appareil"
    echo " 3) Supprimer un appareil"
    echo " 4) Quitter"
    read -p "Choix : " main_choice

    case $main_choice in
        1) load_devices ;;
        2) add_device ;;
        3) delete_device ;;
        4) echo "Bye !" ; exit 0 ;;
    esac
done